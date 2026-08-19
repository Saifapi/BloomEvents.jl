using Test
using Dates
using BloomEvents

@testset "doy365" begin
    @test doy365(Date(2021, 1, 1)) == 1
    @test doy365(Date(2021, 12, 31)) == 365

    # Leap year: March 1 shifts back by 1 (since Feb 29 is ignored)
    @test doy365(Date(2020, 3, 1)) == 60

    # Feb 29 should error
    @test doy365(Date(2020, 2, 29)) == 59
end

@testset "daily_climatology_mean" begin
    # Two years with same day: Jan 1 values 1 and 3 => mean 2
    dates = [Date(2021,1,1), Date(2022,1,1), Date(2021,1,2)]
    chl   = [1.0, 3.0, missing]

    clim = daily_climatology_mean(dates, chl)

    @test length(clim) == 365
    @test clim[1] == 2.0
    @test isnan(clim[2])  # only missing on Jan 2 => no valid values
end

@testset "climatology_at_dates" begin
    dates = [Date(2021,1,1), Date(2021,1,2)]
    clim = fill(10.0, 365)
    out = climatology_at_dates(dates, clim)
    @test out == [10.0, 10.0]
end
