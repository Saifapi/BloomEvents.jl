using BloomEvents
using NCDatasets
using CairoMakie

ncfile = raw"H:\GitHub\BloomEvents\bloom_peak_category_events_2021_2023.nc"

ds = NCDataset(ncfile)

lat = ds["latitude"][:]
lon = ds["longitude"][:]
years = Int.(ds["year"][:])

peaks = (;
    years = years,
    events_peak_likely  = ds["events_peak_likely"][:, :, :],
    events_peak_bloom   = ds["events_peak_bloom"][:, :, :],
    events_peak_intense = ds["events_peak_intense"][:, :, :],
    events_peak_extreme = ds["events_peak_extreme"][:, :, :],
    events_total        = ds["events_total"][:, :, :]
)

close(ds)

fig1 = plot_peak_event_panels_year(lat, lon, peaks; year=2023, title="Peak-category event frequency")
save("peak_events_2023.png", fig1)

fig2 = plot_peak_event_panels_mean(lat, lon, peaks; title="Mean peak-category event frequency (2021–2023)")
save("peak_events_mean.png", fig2)

# With only 3 years, use min_points=2 (not robust but works)
fig3 = plot_peak_event_panels_trend(lat, lon, peaks; min_points=2, title="Trend (2021–2023)")
save("peak_events_trend.png", fig3)

println("Saved: peak_events_2023.png, peak_events_mean.png, peak_events_trend.png")
