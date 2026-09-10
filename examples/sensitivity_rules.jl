import Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

using BloomEvents
using Dates

# Synthetic series for sensitivity
dates = vcat(
    collect(Date(2021,1,1):Day(1):Date(2021,12,31)),
    collect(Date(2022,1,1):Day(1):Date(2022,12,31))
)

chl = vcat(fill(1.0, 365), fill(1.0, 200), fill(3.0, 3), fill(1.0, 162))  # 3-day spike

opts2 = BloomOptions(min_duration=2, max_gap=0, event_min_category=BloomEvents.Likely)
opts3 = BloomOptions(min_duration=3, max_gap=0, event_min_category=BloomEvents.Likely)

a2 = analyze_bloom(dates, chl; options=opts2)
a3 = analyze_bloom(dates, chl; options=opts3)

println("Events with min_duration=2: ", length(a2.events))
println("Events with min_duration=3: ", length(a3.events))
