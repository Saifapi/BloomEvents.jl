import Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

using BloomEvents
using CairoMakie
using Dates

# ---- USER: replace with your own time series loader ----
# For now, synthetic example (replace later with CSV loading)
dates = vcat(
    collect(Date(2021,1,1):Day(1):Date(2021,12,31)),
    collect(Date(2022,1,1):Day(1):Date(2022,12,31))
)

chl = vcat(fill(1.0, 365), fill(1.0, 200), fill(3.0, 10), fill(1.2, 155))

opts = BloomOptions(min_duration=3, max_gap=0, event_min_category=BloomEvents.Likely)
analysis = analyze_bloom(dates, chl; options=opts)

println("Thresholds:")
println("  Q25=", analysis.result.thresholds.q25,
        " Q50=", analysis.result.thresholds.q50,
        " Q75=", analysis.result.thresholds.q75,
        " Q90=", analysis.result.thresholds.q90)

println("Events detected: ", length(analysis.events))
println("Missing fraction: ", missing_fraction(chl))

# Export CSVs (in current dir)
write_events_csv("hotspot_events.csv", analysis.events)
sums = annual_summaries(analysis, chl)
write_annual_csv("hotspot_annual.csv", sums)

# Optional plots
fig1 = plot_bloom_timeseries(dates, chl, analysis; title="Hotspot bloom time series")
save("hotspot_timeseries.png", fig1)

fig2 = plot_annual_panels(sums; title="Hotspot annual metrics")
save("hotspot_annual_panels.png", fig2)

println("Wrote: hotspot_events.csv, hotspot_annual.csv, hotspot_timeseries.png, hotspot_annual_panels.png")
