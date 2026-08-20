module BloomEventsNCDatasetsExt

using BloomEvents
using NCDatasets
using Dates

# -------------------------
# Loader: single cube file
# -------------------------
function BloomEvents.load_chl_cube_netcdf(filepaths::AbstractVector{<:AbstractString};
                                         varname::AbstractString = "CHL",
                                         timename::AbstractString = "time",
                                         latname::AbstractString = "latitude",
                                         lonname::AbstractString = "longitude")

    paths = collect(filepaths)
    isempty(paths) && throw(ArgumentError("filepaths is empty"))

    length(paths) == 1 || throw(ArgumentError("Multiple-file loading not implemented; provide a single cube NetCDF file."))

    ds = NCDataset(paths[1])

    timev = ds[timename][:]
    dates = Date.(timev)

    lat = vec(ds[latname][:])
    lon = vec(ds[lonname][:])

    var = ds[varname]
    A = var[:, :, :]                  # keep 3D (lon, lat, time) in your file

    close(ds)

    sz = size(A)
    nt = length(dates)
    nlat = length(lat)
    nlon = length(lon)

    it = findfirst(==(nt), sz)
    iy = findfirst(==(nlat), sz)
    ix = findfirst(==(nlon), sz)
    (it === nothing || iy === nothing || ix === nothing) &&
        throw(ArgumentError("Cannot infer dimension order for $varname with size $sz"))

    # permute to (time, lat, lon)
    Ap = permutedims(A, (it, iy, ix))

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
# Writer helpers (MODULE SCOPE)
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
# Writer: stacks -> NetCDF
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

    vyear = defVar(ds, "year", Int32, ("year",))
    vyear.attrib["long_name"] = "Year"
    vyear[:] = Int32.(years)

    vlat = defVar(ds, "latitude", Float32, ("latitude",))
    vlat.attrib["standard_name"] = "latitude"
    vlat.attrib["units"] = "degrees_north"
    vlat[:] = Float32.(lat)

    vlon = defVar(ds, "longitude", Float32, ("longitude",))
    vlon.attrib["standard_name"] = "longitude"
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
    ds.attrib["history"] = "Created by BloomEvents.jl write_metric_stack_netcdf"

    for (k,v) in global_attrib
        ds.attrib[k] = v
    end

    close(ds)
    return path
end

end # module
