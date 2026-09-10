module BloomEventsNCDatasetsExt

using BloomEvents
using NCDatasets
using Dates

# ============================================================
# Helpers: attribute access and variable detection (CF-aware)
# ============================================================

_getattrib(v, key::String, default="") = haskey(v.attrib, key) ? v.attrib[key] : default

function _write_metric!(ds::NCDataset,
                        name::String,
                        data,
                        units::String,
                        long_name::String)
    v = defVar(ds, name, Float32, ("year","latitude","longitude"))
    v.attrib["_FillValue"] = Float32(NaN)
    v.attrib["units"] = units
    v.attrib["long_name"] = long_name

    # handle possible Missing values safely
    A = Array(data)
    v[:, :, :] = Float32.(coalesce.(A, NaN))
    return nothing
end

function _varnames(ds)
    # NCDatasets/CommonDataModel stores variables in ds.group
    try
        return collect(String.(keys(ds)))
    catch
        return collect(String.(keys(ds.group)))
    end
end

function _tryvar(ds, name)
    try
        ds[String(name)]
    catch
        return nothing
    end
end

function _detect_time_name(ds)
    for nm in _varnames(ds)
        v = _tryvar(ds, nm)
        v === nothing && continue
        std = String(_getattrib(v, "standard_name", ""))
        ax  = String(_getattrib(v, "axis", ""))
        if std == "time" || ax == "T" || lowercase(String(nm)) == "time"
            return String(nm)
        end
    end
    throw(ArgumentError("Could not auto-detect time variable name; pass timename=..."))
end

function _detect_lat_name(ds)
    for nm in _varnames(ds)
        v = _tryvar(ds, nm)
        v === nothing && continue
        std = String(_getattrib(v, "standard_name", ""))
        ax  = String(_getattrib(v, "axis", ""))
        units = lowercase(String(_getattrib(v, "units", "")))
        if std == "latitude" || ax == "Y" || occursin("degrees_north", units)
            return String(nm)
        end
    end
    throw(ArgumentError("Could not auto-detect latitude variable name; pass latname=..."))
end

function _detect_lon_name(ds)
    for nm in _varnames(ds)
        v = _tryvar(ds, nm)
        v === nothing && continue
        std = String(_getattrib(v, "standard_name", ""))
        ax  = String(_getattrib(v, "axis", ""))
        units = lowercase(String(_getattrib(v, "units", "")))
        if std == "longitude" || ax == "X" || occursin("degrees_east", units)
            return String(nm)
        end
    end
    throw(ArgumentError("Could not auto-detect longitude variable name; pass lonname=..."))
end

function _detect_chl_var(ds; varname::Union{Nothing,String}, timename::String, latname::String, lonname::String)
    if varname !== nothing
        return String(varname)
    end

    # prefer CF standard_name if present
    candidates = String[]
    scored = Tuple{Int,String}[]

    for nm in _varnames(ds)
        nm = String(nm)
        nm in (timename, latname, lonname) && continue
        v = _tryvar(ds, nm)
        v === nothing && continue

        # must be 3D and include time dimension
        ndims(v) == 3 || continue
        dnames = Tuple(String.(dimnames(v)))
        time_dim = String(dimnames(ds[timename])[1])
        time_dim in dnames || continue

        std = String(_getattrib(v, "standard_name", ""))
        long = lowercase(String(_getattrib(v, "long_name", "")))

        score = 0
        if std == "mass_concentration_of_chlorophyll_a_in_sea_water"
            score += 100
        end
        if occursin("chlorophyll", long)
            score += 10
        end
        if lowercase(nm) in ("chl","chla","chlor_a","chlorophyll","chlorophyll_a")
            score += 5
        end

        push!(candidates, nm)
        push!(scored, (score, nm))
    end

    isempty(candidates) && throw(ArgumentError("Could not auto-detect CHL variable; pass varname=..."))

    sort!(scored, by = x -> -x[1])
    bestscore, best = scored[1]

    # if multiple best with same score, force user to choose
    ties = filter(x -> x[1] == bestscore, scored)
    if length(ties) > 1
        names = join(last.(ties), ", ")
        throw(ArgumentError("Multiple CHL candidates found ($names). Please pass varname=..."))
    end

    return best
end

# ============================================================
# Helpers: subsetting and lon wrap
# ============================================================

function _subset_time_indices(dates::Vector{Date}, start_date, end_date)
    idx = collect(eachindex(dates))
    if start_date !== nothing
        idx = filter(i -> dates[i] >= start_date, idx)
    end
    if end_date !== nothing
        idx = filter(i -> dates[i] <= end_date, idx)
    end
    isempty(idx) && throw(ArgumentError("No time points remain after start_date/end_date subsetting"))
    return idx
end

function _select_range_indices(vec::AbstractVector{<:Real}, range::Tuple{<:Real,<:Real})
    a, b = range
    lo = min(Float64(a), Float64(b))
    hi = max(Float64(a), Float64(b))
    findall(x -> (Float64(x) >= lo) && (Float64(x) <= hi), vec)
end

# Detect dataset lon convention
# :zero360 => [0,360)
# :neg180_180 => [-180,180]
function _infer_lon_convention(lon::AbstractVector{<:Real})
    mn = minimum(Float64.(lon))
    mx = maximum(Float64.(lon))
    if mn >= 0.0 && mx > 180.0
        return :zero360
    else
        return :neg180_180
    end
end

_to_zero360(x::Real) = (Float64(x) < 0) ? Float64(x) + 360.0 : Float64(x)
_to_neg180(x::Real) = (Float64(x) > 180.0) ? Float64(x) - 360.0 : Float64(x)

function _normalize_lon_range(lon_range::Tuple{<:Real,<:Real}, dataset_conv::Symbol)
    a, b = lon_range
    if dataset_conv == :zero360
        return (_to_zero360(a), _to_zero360(b))
    else
        return (_to_neg180(a), _to_neg180(b))
    end
end

"""
    _select_lon_indices(lon, lon_range; reorder_lon=true, allow_dateline_crossing=true)

Select lon indices for requested lon_range which may cross the dateline (e.g., 170 -> -170).
Accepts lon_range in either convention; auto-normalizes to dataset convention.
Returns (lon_idx, lon_sub).
"""
function _select_lon_indices(lon::AbstractVector{<:Real},
                             lon_range::Tuple{<:Real,<:Real};
                             reorder_lon::Bool=true,
                             allow_dateline_crossing::Bool=true)

    dataset_conv = _infer_lon_convention(lon)
    a, b = _normalize_lon_range(lon_range, dataset_conv)

    lonf = Float64.(lon)

    # dateline crossing if a > b after normalization
    if a <= b
        idx = findall(x -> (x >= a) && (x <= b), lonf)
    else
        allow_dateline_crossing || throw(ArgumentError("lon_range crosses dateline but allow_dateline_crossing=false"))
        idx = findall(x -> (x >= a) || (x <= b), lonf)
    end

    isempty(idx) && throw(ArgumentError("No longitude points found for lon_range=$lon_range (normalized to $a,$b)"))

    if reorder_lon
        p = sortperm(lonf[idx])
        idx = idx[p]
    end
    return idx, lon[idx]
end

# Convert values to missing based on NaN and common sentinel (-999)
function _to_missing(x)
    if ismissing(x)
        return missing
    end
    fx = Float64(x)
    if isnan(fx) || fx == -999.0
        return missing
    end
    return fx
end

# ============================================================
# Loader: cube file OR many daily files (time read from file)
# ============================================================

"""
    load_chl_cube_netcdf(filepaths; ...)

Returns:
(dates::Vector{Date}, chl3d::Array{Union{Missing,Float64},3}, lat, lon)

Output chl3d is ALWAYS shaped: [time, lat, lon]

Supports:
- Single cube file with time dimension
- Multiple files each containing one time slice (2D CHL), time read from the file
"""
function BloomEvents.load_chl_cube_netcdf(filepaths::AbstractVector{<:AbstractString};
                                         varname::Union{Nothing,String} = nothing,
                                         timename::Union{Nothing,String} = nothing,
                                         latname::Union{Nothing,String} = nothing,
                                         lonname::Union{Nothing,String} = nothing,
                                         start_date::Union{Nothing,Date} = nothing,
                                         end_date::Union{Nothing,Date} = nothing,
                                         lat_range::Union{Nothing,Tuple{<:Real,<:Real}} = nothing,
                                         lon_range::Union{Nothing,Tuple{<:Real,<:Real}} = nothing,
                                         reorder_lon::Bool = true,
                                         allow_dateline_crossing::Bool = true)

    paths = collect(String.(filepaths))
    isempty(paths) && throw(ArgumentError("filepaths is empty"))

    # ------------------------------------------------------------
    # Helper to detect names from a dataset
    # ------------------------------------------------------------
    function detect_names(ds)
        tnm = timename === nothing ? _detect_time_name(ds) : String(timename)
        ynm = latname === nothing ? _detect_lat_name(ds) : String(latname)
        xnm = lonname === nothing ? _detect_lon_name(ds) : String(lonname)
        vnm = _detect_chl_var(ds; varname=varname, timename=tnm, latname=ynm, lonname=xnm)
        return tnm, ynm, xnm, vnm
    end

    # ------------------------------------------------------------
    # Case 1: single cube file
    # ------------------------------------------------------------
    if length(paths) == 1
        ds = NCDataset(paths[1])
        tnm, ynm, xnm, vnm = detect_names(ds)

        # time vector (NCDatasets often decodes CF time to DateTime already)
        timev = ds[tnm][:]
        dates_full = Date.(timev)
        tidx = _subset_time_indices(dates_full, start_date, end_date)
        dates = dates_full[tidx]

        lat_full = vec(ds[ynm][:])
        lon_full = vec(ds[xnm][:])

        # subset lat/lon indices
        lat_idx = lat_range === nothing ? collect(eachindex(lat_full)) : _select_range_indices(lat_full, lat_range)
        lon_idx, lon_sub = lon_range === nothing ? (collect(eachindex(lon_full)), lon_full) :
                             _select_lon_indices(lon_full, lon_range; reorder_lon=reorder_lon,
                                                 allow_dateline_crossing=allow_dateline_crossing)

        lat = lat_full[lat_idx]
        lon = lon_full[lon_idx]

        var = ds[vnm]
        ndims(var) == 3 || throw(ArgumentError("Expected 3D CHL variable $vnm, got ndims=$(ndims(var))"))

        # Determine which dim corresponds to time/lat/lon by dimension names
        dnames = Tuple(String.(dimnames(var)))
        time_dim = String(dimnames(ds[tnm])[1])
        lat_dim  = String(dimnames(ds[ynm])[1])
        lon_dim  = String(dimnames(ds[xnm])[1])

        it = findfirst(==(time_dim), dnames)
        iy = findfirst(==(lat_dim),  dnames)
        ix = findfirst(==(lon_dim),  dnames)
        (it === nothing || iy === nothing || ix === nothing) &&
            throw(ArgumentError("Cannot map dims of $vnm to time/lat/lon. dimnames(var)=$dnames"))

        # Build indices in var order
        inds = Vector{Any}(undef, 3)
        inds[it] = tidx
        inds[iy] = lat_idx
        inds[ix] = lon_idx

        A = var[inds...]      # still in file order
        close(ds)

        # permute to (time, lat, lon)
        Ap = permutedims(A, (it, iy, ix))

        nt = length(dates)
        nlat = length(lat)
        nlon = length(lon)

        chl3d = Array{Union{Missing,Float64}}(undef, nt, nlat, nlon)
        for t in 1:nt, j in 1:nlat, i in 1:nlon
            chl3d[t,j,i] = _to_missing(Ap[t,j,i])
        end

        return dates, chl3d, lat, lon
    end

    # ------------------------------------------------------------
    # Case 2: multiple files, each file contains one time slice
    # Time is read from each file (not parsed from filename)
    # ------------------------------------------------------------

    # Read dates from files (fast pass: open each file and read time scalar/first element)
    dates_all = Date[]
    for p in paths
        ds = NCDataset(p)
        tnm = timename === nothing ? _detect_time_name(ds) : String(timename)
        tv = ds[tnm][:]
        close(ds)
        # tv could be scalar or length-1 vector
        dt = tv isa AbstractVector ? Date(tv[1]) : Date(tv)
        push!(dates_all, dt)
    end

    # subset by dates
    keep = trues(length(paths))
    if start_date !== nothing
        keep .&= dates_all .>= start_date
    end
    if end_date !== nothing
        keep .&= dates_all .<= end_date
    end

    sel_paths = paths[keep]
    sel_dates = dates_all[keep]
    isempty(sel_paths) && throw(ArgumentError("No files remain after start_date/end_date subsetting"))

    # sort by date
    ord = sortperm(sel_dates)
    sel_paths = sel_paths[ord]
    sel_dates = sel_dates[ord]

    # Open first file to get grid + names
    ds0 = NCDataset(sel_paths[1])
    tnm, ynm, xnm, vnm = detect_names(ds0)

    lat_full = vec(ds0[ynm][:])
    lon_full = vec(ds0[xnm][:])

    lat_idx = lat_range === nothing ? collect(eachindex(lat_full)) : _select_range_indices(lat_full, lat_range)
    lon_idx, lon_sub = lon_range === nothing ? (collect(eachindex(lon_full)), lon_full) :
                         _select_lon_indices(lon_full, lon_range; reorder_lon=reorder_lon,
                                             allow_dateline_crossing=allow_dateline_crossing)

    lat = lat_full[lat_idx]
    lon = lon_full[lon_idx]

    var0 = ds0[vnm]
    ndims(var0) == 2 || throw(ArgumentError("Expected 2D CHL variable $vnm in daily files, got ndims=$(ndims(var0))"))
    dnames0 = Tuple(String.(dimnames(var0)))

    lat_dim = String(dimnames(ds0[ynm])[1])
    lon_dim = String(dimnames(ds0[xnm])[1])

    iy = findfirst(==(lat_dim), dnames0)
    ix = findfirst(==(lon_dim), dnames0)
    (iy === nothing || ix === nothing) &&
        throw(ArgumentError("Cannot map dims of $vnm to lat/lon in daily files. dimnames(var)=$dnames0"))

    close(ds0)

    nt = length(sel_dates)
    nlat = length(lat)
    nlon = length(lon)

    chl3d = Array{Union{Missing,Float64}}(undef, nt, nlat, nlon)

    # Read each file slice
    for (t, p) in enumerate(sel_paths)
        ds = NCDataset(p)

        # (optional) grid consistency checks
        # You can relax these if needed, but they catch silent misalignment bugs:
        lat_check = vec(ds[ynm][:])
        lon_check = vec(ds[xnm][:])
        (length(lat_check) == length(lat_full) && length(lon_check) == length(lon_full)) ||
            throw(ArgumentError("Grid size mismatch in file $p"))

        var = ds[vnm]
        ndims(var) == 2 || throw(ArgumentError("Expected 2D var $vnm in $p"))

        inds2 = Vector{Any}(undef, 2)
        inds2[iy] = lat_idx
        inds2[ix] = lon_idx

        A2 = var[inds2...]  # in file order (lat×lon or lon×lat depending on dims)
        close(ds)

        # permute to (lat, lon) before inserting into chl3d[t, :, :]
        Ap2 = (iy, ix) == (1,2) ? A2 : permutedims(A2, (iy, ix))

        for j in 1:nlat, i in 1:nlon
            chl3d[t,j,i] = _to_missing(Ap2[j,i])
        end
    end

    return sel_dates, chl3d, lat, lon
end

# ============================================================
# Writers (unchanged): keep inside module
# ============================================================

function BloomEvents.write_metric_stack_netcdf(path::AbstractString,
                                              lat::AbstractVector,
                                              lon::AbstractVector,
                                              stacks;
                                              global_attrib::Dict{String,Any}=Dict{String,Any}())

    years = stacks.years
    ny = length(years)

    ds = NCDataset(path, "c")
    defDim(ds, "year", ny)
    defDim(ds, "latitude", length(lat))
    defDim(ds, "longitude", length(lon))

    defVar(ds, "year", Int32, ("year",))[:] = Int32.(years)

    vlat = defVar(ds, "latitude", Float32, ("latitude",))
    vlat.attrib["units"] = "degrees_north"
    vlat[:] = Float32.(lat)

    vlon = defVar(ds, "longitude", Float32, ("longitude",))
    vlon.attrib["units"] = "degrees_east"
    vlon[:] = Float32.(lon)

    _write_metric!(ds, "frequency",            stacks.frequency,            "events",        "Annual bloom frequency")
    _write_metric!(ds, "total_days",           stacks.total_days,           "days",          "Annual bloom total days")
    _write_metric!(ds, "mean_duration",        stacks.mean_duration,        "days",          "Annual mean bloom duration")
    _write_metric!(ds, "mean_intensity",       stacks.mean_intensity,       "mg m-3",        "Annual mean bloom intensity (chl - climatology)")
    _write_metric!(ds, "max_intensity",        stacks.max_intensity,        "mg m-3",        "Annual max bloom intensity (chl - climatology)")
    _write_metric!(ds, "cumulative_intensity", stacks.cumulative_intensity, "mg m-3 days",   "Annual cumulative bloom intensity")
    _write_metric!(ds, "mean_rate_onset",      stacks.mean_rate_onset,      "intensity/day", "Annual mean rate of onset")
    _write_metric!(ds, "mean_rate_decline",    stacks.mean_rate_decline,    "intensity/day", "Annual mean rate of decline")

    ds.attrib["Conventions"] = "CF-1.11"
    ds.attrib["title"] = "Bloom metric stacks (BloomEvents.jl)"
    for (k,v) in global_attrib
        ds.attrib[k] = v
    end
    close(ds)
    return path
end

function BloomEvents.write_category_stack_netcdf(path::AbstractString,
                                                lat::AbstractVector,
                                                lon::AbstractVector,
                                                cats;
                                                global_attrib::Dict{String,Any}=Dict{String,Any}())

    years = cats.years
    ny = length(years)

    ds = NCDataset(path, "c")
    defDim(ds, "year", ny)
    defDim(ds, "latitude", length(lat))
    defDim(ds, "longitude", length(lon))

    defVar(ds, "year", Int32, ("year",))[:] = Int32.(years)

    vlat = defVar(ds, "latitude", Float32, ("latitude",))
    vlat.attrib["units"] = "degrees_north"
    vlat[:] = Float32.(lat)

    vlon = defVar(ds, "longitude", Float32, ("longitude",))
    vlon.attrib["units"] = "degrees_east"
    vlon[:] = Float32.(lon)

    _write_metric!(ds, "days_likely",  cats.days_likely,  "days", "Days in Likely-to-Bloom category")
    _write_metric!(ds, "days_bloom",   cats.days_bloom,   "days", "Days in Bloom category")
    _write_metric!(ds, "days_intense", cats.days_intense, "days", "Days in Intense Bloom category")
    _write_metric!(ds, "days_extreme", cats.days_extreme, "days", "Days in Extreme Bloom category")

    ds.attrib["Conventions"] = "CF-1.11"
    ds.attrib["title"] = "Bloom category day-count stacks (BloomEvents.jl)"
    for (k,v) in global_attrib
        ds.attrib[k] = v
    end
    close(ds)
    return path
end

function BloomEvents.write_peak_category_stack_netcdf(path::AbstractString,
                                                     lat::AbstractVector,
                                                     lon::AbstractVector,
                                                     peaks;
                                                     global_attrib::Dict{String,Any}=Dict{String,Any}())

    years = peaks.years
    ny = length(years)

    ds = NCDataset(path, "c")
    defDim(ds, "year", ny)
    defDim(ds, "latitude", length(lat))
    defDim(ds, "longitude", length(lon))

    defVar(ds, "year", Int32, ("year",))[:] = Int32.(years)

    vlat = defVar(ds, "latitude", Float32, ("latitude",))
    vlat.attrib["units"] = "degrees_north"
    vlat[:] = Float32.(lat)

    vlon = defVar(ds, "longitude", Float32, ("longitude",))
    vlon.attrib["units"] = "degrees_east"
    vlon[:] = Float32.(lon)

    _write_metric!(ds, "events_peak_likely",  peaks.events_peak_likely,  "events", "Events with peak category Likely")
    _write_metric!(ds, "events_peak_bloom",   peaks.events_peak_bloom,   "events", "Events with peak category Bloom")
    _write_metric!(ds, "events_peak_intense", peaks.events_peak_intense, "events", "Events with peak category Intense")
    _write_metric!(ds, "events_peak_extreme", peaks.events_peak_extreme, "events", "Events with peak category Extreme")
    _write_metric!(ds, "events_total",        peaks.events_total,        "events", "Total number of events")

    ds.attrib["Conventions"] = "CF-1.11"
    ds.attrib["title"] = "Bloom peak-category event-frequency stacks (BloomEvents.jl)"
    for (k,v) in global_attrib
        ds.attrib[k] = v
    end
    close(ds)
    return path
end

end # module
