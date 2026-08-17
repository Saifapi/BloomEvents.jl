using Test
using Dates
using BloomEvents

@testset "annual_summaries basic" begin
    # Two-year dataset like earlier
    dates = vcat(
        collect(Date(2021,1,1):Day(1):Date(2021,1,6)),
        collect(Date(2022,1,1):Day(1):Date(2022,1,6))
    )

    chl = vcat(
        fill(1.0, 6),
        [2.6, 2.7, 2.8, 3.6, 3.7, 3.8]
    )

    a = analyze_bloom(dates, chl; options=BloomOptions(min_duration=3, max_gap=0, event_min_category=BloomEvents.Likely))
    sums = annual_summaries(a, chl)

    @test length(sums) >= 1
    @test all(s.frequency >= 1 for s in sums)

    tab = annual_table(sums)
    @test length(tab.years) == length(sums)
    @test length(tab.frequency) == length(sums)
end
