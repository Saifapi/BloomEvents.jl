using Test
using Dates
using BloomEvents

@testset "QA: dates" begin
    d = collect(Date(2020,1,1):Day(1):Date(2020,1,5))
    @test is_sorted_dates(d)
    @test check_daily(d)

    d2 = [Date(2020,1,1), Date(2020,1,3)]
    @test !check_daily(d2; strict=false)
    @test_throws ArgumentError check_daily(d2; strict=true)

    d3 = [Date(2020,1,2), Date(2020,1,1)]
    @test !check_daily(d3; strict=false)
    @test_throws ArgumentError check_daily(d3; strict=true)
end

@testset "QA: missing/valid fraction" begin
    x = [1.0, missing, NaN, 2.0]
    @test missing_fraction(x) == 0.5
    @test valid_fraction(x) == 0.5
end

@testset "QA: valid pixels on map" begin
    m = [1.0 NaN; missing 2.0]
    @test count_valid_pixels(m) == 2
    @test fraction_valid_pixels(m) == 0.5
end
