import Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

using Dates
using BloomEvents
using CairoMakie

# 60-day windows using day offsets (valid calendar dates)
dates1 = collect(Date(2021,1,1):Day(1):Date(2021,1,1) + Day(59))
dates2 = collect(Date(2022,1,1):Day(1):Date(2022,1,1) + Day(59))
dates = vcat(dates1, dates2)

chl1 = fill(1.0, length(dates1))
chl2 = vcat(fill(1.0, 20), fill(3.0, 10), fill(1.2, length(dates2) - 30))
chl = vcat(chl1, chl2)

analysis = analyze_bloom(dates, chl; options=BloomOptions(min_duration=3, max_gap=0, event_min_category=BloomEvents.Likely))

fig1 = plot_bloom_timeseries(dates, chl, analysis; title="Bloom time series (synthetic)")
save("timeseries.png", fig1)

sums = annual_summaries(analysis, chl)
fig2 = plot_annual_panels(sums; title="Annual bloom metrics (synthetic)")
save("annual_panels.png", fig2)

println("Saved: timeseries.png, annual_panels.png")
