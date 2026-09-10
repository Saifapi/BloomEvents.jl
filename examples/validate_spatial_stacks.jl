import Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

using BloomEvents
using NCDatasets
using CairoMakie
using Dates

# ---- USER SETTINGS ----
file = raw"H:\GitHub\BloomEvents\NetCDF\CHL(1998-01-01_2025-12-31).nc"   # change to your file

dates, chl3d, lat, lon = load_chl_cube_netcdf([file];
    varname="CHL",
    timename="time",
    latname="latitude",
    lonname="longitude",
    start_date=Date(2003,1,1),
    end_date=Date(2023,12,31),
    lat_range=(16.0, 23.0),
    lon_range=(80.0, 95.0)
)

years = 2021:2023
bloom_opts = BloomOptions(min_duration=3, max_gap=0, event_min_category=BloomEvents.Likely)
grid_opts  = GridOptions(min_valid_fraction=0.3, threads=true)

stacks = annual_metric_stack(dates, chl3d, years; bloom_options=bloom_opts, grid_options=grid_opts)
println("Stacks computed. frequency size = ", size(stacks.frequency))

for (k,y) in enumerate(stacks.years)
    f = stacks.frequency[k, :, :]
    println("Year $y valid pixels = ", count_valid_pixels(f))
end

# Export NetCDF
outnc = "spatial_metric_stacks.nc"
write_metric_stack_netcdf(outnc, lat, lon, stacks)
println("Wrote: ", outnc)

# Plot annual + mean panels
figA = plot_spatial_panels_year(lat, lon, stacks; year=2023, title="Annual bloom metrics")
save("spatial_annual_2023.png", figA)

figM = plot_spatial_panels_mean(lat, lon, stacks; title="Mean bloom metrics")
save("spatial_mean.png", figM)

println("Saved: spatial_annual_2023.png, spatial_mean.png")
