using BloomEvents
using NCDatasets
using CairoMakie

# Path to your exported stacks
ncfile = raw"H:\GitHub\BloomEvents\bloom_metric_stacks_2021_2023.nc"

ds = NCDataset(ncfile)

lat = ds["latitude"][:]
lon = ds["longitude"][:]
years = Int.(ds["year"][:])

# Build a stacks NamedTuple compatible with plotting functions
stacks = (;
    years = years,
    frequency = ds["frequency"][:, :, :],
    total_days = ds["total_days"][:, :, :],
    mean_duration = ds["mean_duration"][:, :, :],
    mean_intensity = ds["mean_intensity"][:, :, :],
    max_intensity = ds["max_intensity"][:, :, :],
    cumulative_intensity = ds["cumulative_intensity"][:, :, :],
    mean_rate_onset = ds["mean_rate_onset"][:, :, :],
    mean_rate_decline = ds["mean_rate_decline"][:, :, :]
)

close(ds)

# Annual panels (choose a year that exists)
fig1 = plot_spatial_panels_year(lat, lon, stacks; year=2023, title="Annual Bloom Metrics")
save("annual_panels_2023.png", fig1)

# Mean panels
fig2 = plot_spatial_panels_mean(lat, lon, stacks; title="Mean Bloom Metrics (2021–2023)")
save("mean_panels.png", fig2)

# Trend panels (needs ≥ min_points valid years; with only 3 years this may be mostly NaN)
fig3 = plot_spatial_panels_trend(lat, lon, stacks; min_points=2, title="Trend (2021–2023)")
save("trend_panels.png", fig3)

println("Saved: annual_panels_2023.png, mean_panels.png, trend_panels.png")
