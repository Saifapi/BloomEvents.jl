using Test
using Dates
using BloomEvents

@testset "compute_event_metrics basic" begin
    dates = vcat(
        collect(Date(2021,1,1):Day(1):Date(2021,1,6)),
        collect(Date(2022,1,1):Day(1):Date(2022,1,6))
    )
    chl = vcat(
        fill(1.0, 6),
        [2.6, 2.7, 2.8, 3.6, 3.7, 3.8]
    )

    a = analyze_bloom(dates, chl; options=BloomOptions(min_duration=3, max_gap=0, event_min_category=BloomEvents.Likely))

    mets = compute_event_metrics(a.events, chl, a.result.clim_at_dates)

    @test length(mets) == length(a.events)
    @test all(m.duration >= 3 for m in mets)
    @test all(!isnan(m.max_intensity) for m in mets)
end
