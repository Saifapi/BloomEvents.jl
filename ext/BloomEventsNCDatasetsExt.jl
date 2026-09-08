module BloomEventsNCDatasetsExt

using BloomEvents
using NCDatasets
using Dates

# -------------------------
# Helper: write a 3D metric (year, lat, lon)
# -------------------------
function _write_metric!(ds::NCDataset,
                        name::String,
                        data::AbstractArray{<:Real,3},
                        units::String,
                        long_name::String)
    v = defVar(ds, name, Float32, ("year","latitude","longitude"))
    v.attrib["_FillValue"] = Float32(NaN)
    v.attrib["units"] = units
    v.attrib["long_name"] = long_name
    v[:, :, :] = Float32.(data)
    return nothing
end

# -------------------------
# Loader: single cube file with optional time subsetting
# -------------------------
function BloomEvents.load_chl_cube_netcdf(filepaths::AbstractVector{<:AbstractString};
                                         varname::AbstractString = "CHL",
                                         timename::AbstractString = "time",
                                         latname::AbstractString = "latitude",
                                         lonname::AbstractString = "longitude",
                                         start_date::Union{Nothing,Date} = nothing,
                                         end_date::Union{Nothing,Date} = nothing)

    paths = collect(filepaths)
    isempty(paths) && throw(ArgumentError("filepaths is empty"))
    length(paths) == 1 || throw(ArgumentError("Multiple-file loading not implemented; provide a single cube NetCDF file."))

    ds = NCDataset(paths[1])

    timev = ds[timename][:]
    dates_full = Date.(timev)

    tidx = collect(eachindex(dates_full))
    if start_date !== nothing
        tidx = filter(i -> dates_full[i] >= start_date, tidx)
    end
    if end_date !== nothing
        tidx = filter(i -> dates_full[i] <= end_date, tidx)
    end
    isempty(tidx) && throw(ArgumentError("No time points remain after subsetting"))

    dates = dates_full[tidx]

    lat = vec(ds[latname][:])
    lon = vec(ds[lonname][:])

    var = ds[varname]

    szfull = size(var)
    ntfull = length(dates_full)
    nlat = length(lat)
    nlon = length(lon)

    it = findfirst(==(ntfull), szfull)
    iy = findfirst(==(nlat), szfull)
    ix = findfirst(==(nlon), szfull)
    (it === nothing || iy === nothing || ix === nothing) &&
        throw(ArgumentError("Cannot infer dimension order for $varname with size $szfull"))

    ndims(var) == 3 || throw(ArgumentError("Expected a 3D variable for $varname"))

    inds = ntuple(d -> d == it ? tidx : Colon(), 3)
    A = var[inds...]     # e.g. lon×lat×time_subset

    close(ds)

    Ap = permutedims(A, (it, iy, ix))  # -> time×lat×lon

    nt = length(dates)
    chl3d = Array{Union{Missing,Float64}}(undef, nt, nlat, nlon)

    for t in 1:nt, j in 1:nlat, i in 1:nlon
        v = Ap[t, j, i]
        if ismissing(v)
            chl3d[t,j,i] = missing
        else
            x = Float64(v)
            if isnan(x) || x == -999.0
                chl3d[t,j,i] = missing
            else
                chl3d[t,j,i] = x
            end
        end
    end

    return dates, chl3d, lat, lon
end

# -------------------------
# Writer 1: metric stacks
# -------------------------
function BloomEvents.write_metric_stack_netcdf(path::AbstractString,
                                              lat::AbstractVector,
                                              lon::AbstractVector,
                                              stacks;
                                              global_attrib::Dict{String,Any}=Dict{String,Any}())

    years = stacks.years
    ny = length(years)
    nlat = length(lat)
    nlon = length(lon)

    ds = NCDataset(path, "c")
    defDim(ds, "year", ny)
    defDim(ds, "latitude", nlat)
    defDim(ds, "longitude", nlon)

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

# -------------------------
# Writer 2: category day-count stacks
# -------------------------
function BloomEvents.write_category_stack_netcdf(path::AbstractString,
                                                lat::AbstractVector,
                                                lon::AbstractVector,
                                                cats;
                                                global_attrib::Dict{String,Any}=Dict{String,Any}())

    years = cats.years
    ny = length(years)
    nlat = length(lat)
    nlon = length(lon)

    ds = NCDataset(path, "c")
    defDim(ds, "year", ny)
    defDim(ds, "latitude", nlat)
    defDim(ds, "longitude", nlon)

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

# -------------------------
# Writer 3: peak-category event-frequency stacks (14G)
# -------------------------
function BloomEvents.write_peak_category_stack_netcdf(path::AbstractString,
                                                     lat::AbstractVector,
                                                     lon::AbstractVector,
                                                     peaks;
                                                     global_attrib::Dict{String,Any}=Dict{String,Any}())

    years = peaks.years
    ny = length(years)
    nlat = length(lat)
    nlon = length(lon)

    ds = NCDataset(path, "c")
    defDim(ds, "year", ny)
    defDim(ds, "latitude", nlat)
    defDim(ds, "longitude", nlon)

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
