using Test
using Dates
using BloomEvents

@testset "fit_bloom pipeline" begin
    # Construct a tiny dataset with a 3-day positive anomaly run
    dates = [Date(2021,1,1), Date(2021,1,2), Date(2021,1,3),
             Date(2022,1,1), Date(2022,1,2), Date(2022,1,3)]
    # Climatology will be mean of same DOY across years.
    # We make 2022 higher so anomalies exist.
    chl = [1.0, 1.0, 1.0, 3.0, 3.0, 3.0]

    res = fit_bloom(dates, chl; min_duration=3)

    @test length(res.clim365) == 365
    @test length(res.labels) == length(chl)
    @test any(res.posmask_persist) == true
    @test res.thresholds.q25 <= res.thresholds.q50 <= res.thresholds.q75 <= res.thresholds.q90
end
