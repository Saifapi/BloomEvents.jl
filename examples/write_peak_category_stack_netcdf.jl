import Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

using BloomEvents
using NCDatasets
using Dates

file_path = raw"H:\GitHub\BloomEvents\NetCDF\CHL(1998-01-01_2025-12-31).nc"
files = [file_path]

varname = "CHL"
latname = "latitude"
lonname = "longitude"

# Load only needed years
dates, chl3d, lat, lon = load_chl_cube_netcdf(files;
    varname=varname, latname=latname, lonname=lonname,
    start_date=Date(2003,1,1),
    end_date=Date(2023,12,31)
)

years = 2021:2023
bloom_opts = BloomOptions(min_duration=3, max_gap=0, event_min_category=BloomEvents.Likely)
grid_opts  = GridOptions(min_valid_fraction=0.3, threads=false)

peaks = event_peak_category_stack(dates, chl3d, years; bloom_options=bloom_opts, grid_options=grid_opts)

outnc = joinpath(pwd(), "bloom_peak_category_events_2021_2023.nc")
write_peak_category_stack_netcdf(outnc, lat, lon, peaks)

println("Wrote: ", outnc)
