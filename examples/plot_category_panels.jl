import Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

using BloomEvents
using NCDatasets
using CairoMakie

# category NetCDF produced by Step 14C
ncfile = raw"H:\GitHub\BloomEvents\bloom_category_days_2021_2023.nc"

ds = NCDataset(ncfile)

lat = ds["latitude"][:]
lon = ds["longitude"][:]
years = Int.(ds["year"][:])

cats = (;
    years = years,
    days_likely  = ds["days_likely"][:, :, :],
    days_bloom   = ds["days_bloom"][:, :, :],
    days_intense = ds["days_intense"][:, :, :],
    days_extreme = ds["days_extreme"][:, :, :]
)

close(ds)

fig1 = plot_category_panels_year(lat, lon, cats; year=2023, title="Category days")
save("category_days_2023.png", fig1)

fig2 = plot_category_panels_mean(lat, lon, cats; title="Mean category days (2021–2023)")
save("category_days_mean.png", fig2)

# Trend over only 3 years is not robust; but it will run if min_points=2
fig3 = plot_category_panels_trend(lat, lon, cats; min_points=2, title="Category days trend (2021–2023)")
save("category_days_trend.png", fig3)

println("Saved: category_days_2023.png, category_days_mean.png, category_days_trend.png")
