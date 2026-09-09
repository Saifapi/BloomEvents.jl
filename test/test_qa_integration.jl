using Test
using Dates
using BloomEvents

@testset "QA integration: strict_daily in analyze_bloom" begin
    # Irregular (not daily) but SORTED dates: missing Jan-02 in both years
    dates = [
        Date(2021,1,1), Date(2021,1,3), Date(2021,1,4),
        Date(2022,1,1), Date(2022,1,3), Date(2022,1,4)
    ]

    # Year1 low, Year2 high -> climatology ~2, year2 > clim for 3 adjacent indices
    chl = [1.0, 1.0, 1.0, 3.0, 3.0, 3.0]

    opts_strict = BloomOptions(check_dates=true, strict_daily=true, min_duration=3)
    @test_throws ArgumentError analyze_bloom(dates, chl; options=opts_strict)

    opts_nonstrict = BloomOptions(check_dates=true, strict_daily=false, min_duration=3)
    a = analyze_bloom(dates, chl; options=opts_nonstrict)
    @test length(a.result.labels) == length(chl)
end
