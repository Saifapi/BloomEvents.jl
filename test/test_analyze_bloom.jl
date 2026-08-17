using Test
using Dates
using BloomEvents

@testset "analyze_bloom returns analysis + events honor options" begin
    # Two-year dataset so climatology is not identical to the series.
    dates = vcat(
        collect(Date(2021,1,1):Day(1):Date(2021,1,6)),
        collect(Date(2022,1,1):Day(1):Date(2022,1,6))
    )

    chl = vcat(
        fill(1.0, 6),                          # year 1 low
        [2.6, 2.7, 2.8, 3.6, 3.7, 3.8]          # year 2 higher (positive anomalies)
    )

    aLikely = analyze_bloom(dates, chl; options=BloomOptions(
        min_duration=3,
        max_gap=0,
        event_min_category=BloomEvents.Likely
    ))

    aBloom = analyze_bloom(dates, chl; options=BloomOptions(
        min_duration=3,
        max_gap=0,
        event_min_category=BloomEvents.Bloom
    ))

    @test length(aLikely.result.labels) == length(chl)
    @test isa(aLikely.events, Vector{BloomEvent})

    # Bloom-min-category events should cover <= total days than Likely-min-category
    daysLikely = sum(e.duration for e in aLikely.events)
    daysBloom  = sum(e.duration for e in aBloom.events)

    @test daysLikely > 0
    @test daysBloom > 0
    @test daysBloom <= daysLikely
end
