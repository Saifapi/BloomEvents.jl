using BloomEvents
using NCDatasets
using Dates

# Same file you used
file_path = raw"H:\GitHub\BloomEvents\NetCDF\CHL(1998-01-01_2025-12-31).nc"
files = [file_path]

varname = "CHL"
latname = "latitude"
lonname = "longitude"

years = 2021:2023
bloom_opts = BloomOptions(min_duration=3, max_gap=0, event_min_category=BloomEvents.Likely)
grid_opts  = GridOptions(min_valid_fraction=0.3, threads=false)

dates, chl3d, lat, lon = load_chl_cube_netcdf(files; varname=varname, latname=latname, lonname=lonname)
stacks = annual_metric_stack(dates, chl3d, years; bloom_options=bloom_opts, grid_options=grid_opts)

outnc = joinpath(pwd(), "bloom_metric_stacks_2021_2023.nc")
write_metric_stack_netcdf(outnc, lat, lon, stacks)
println("Wrote: ", outnc)
