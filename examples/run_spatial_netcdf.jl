using BloomEvents
using NCDatasets
using Dates
using Statistics
using Serialization

# ---- USER SETTINGS ----
file_path = raw"H:\GitHub\BloomEvents\NetCDF\CHL(1998-01-01_2025-12-31).nc"
files = [file_path]

varname = "CHL"
latname = "latitude"
lonname = "longitude"

years = 2021:2023

bloom_opts = BloomOptions(min_duration=3, max_gap=0, event_min_category=BloomEvents.Likely)
grid_opts  = GridOptions(min_valid_fraction=0.3, threads=false)

println("Found $(length(files)) NetCDF files")

# ---- LOAD CUBE ----
dates, chl3d, lat, lon = load_chl_cube_netcdf(files;
    varname=varname, latname=latname, lonname=lonname,
    start_date=Date(2003,1,1),
    end_date=Date(2023,12,31)
)

println("Loaded cube:")
println("  time = ", length(dates), " days;  lat = ", length(lat), "; lon = ", length(lon))
println("  chl3d size = ", size(chl3d))  # (time, lat, lon)

# ---- RUN STACKS ----
stacks = annual_metric_stack(dates, chl3d, years; bloom_options=bloom_opts, grid_options=grid_opts)

println("Computed stacks for years: ", stacks.years)
println("Stack frequency size: ", size(stacks.frequency))  # (nyears, nlat, nlon)

# ---- QUICK SUMMARY ----
for (k, y) in enumerate(stacks.years)
    f = stacks.frequency[k, :, :]
    vals = vec(f)
    good = vals[.!isnan.(vals)]
    m = isempty(good) ? NaN : mean(good)
    println("Year $y mean frequency (spatial): ", m)
end

# ---- SAVE OUTPUT ----
outpath = joinpath(pwd(), "bloom_metric_stacks.jls")
serialize(outpath, (lat=lat, lon=lon, stacks=stacks))
println("Saved: ", outpath)
