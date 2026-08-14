using Test
using Dates
using BloomEvents

@testset "detect_events basic" begin
    dates = collect(Date(2021,1,1):Day(1):Date(2021,1,10))
    chl = fill(1.0, 10)

    labels = BloomCategory[
        BloomEvents.NoBloom,
        BloomEvents.Likely, BloomEvents.Likely, BloomEvents.Likely,
        BloomEvents.NoBloom,
        BloomEvents.Bloom, BloomEvents.Bloom,
        BloomEvents.NoBloom,
        BloomEvents.Intense, BloomEvents.Intense
    ]

    ev = detect_events(dates, chl, labels; min_category=BloomEvents.Likely, min_duration=3, max_gap=0)
    @test length(ev) == 1
    @test ev[1].start_idx == 2
    @test ev[1].end_idx == 4
    @test ev[1].duration == 3
    @test ev[1].peak_category == BloomEvents.Likely
end

@testset "detect_events with gap bridging" begin
    dates = collect(Date(2021,1,1):Day(1):Date(2021,1,7))
    chl = fill(1.0, 7)

    labels = BloomCategory[
        BloomEvents.Likely, BloomEvents.Likely,
        BloomEvents.NoBloom,  # one-day gap
        BloomEvents.Likely, BloomEvents.Likely,
        BloomEvents.NoBloom, BloomEvents.NoBloom
    ]

    ev0 = detect_events(dates, chl, labels; min_category=BloomEvents.Likely, min_duration=3, max_gap=0)
    ev1 = detect_events(dates, chl, labels; min_category=BloomEvents.Likely, min_duration=3, max_gap=1)

    @test length(ev0) == 0          # two runs of length 2 each -> fail min_duration=3
    @test length(ev1) == 1          # gap bridged -> one run length 5 -> passes
    @test ev1[1].start_idx == 1
    @test ev1[1].end_idx == 5
end
