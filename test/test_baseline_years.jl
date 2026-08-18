using Test
using Dates
using BloomEvents

@testset "baseline_years affects climatology (not inflated by later years)" begin
    # 3 years, same DOYs
    dates = vcat(
        collect(Date(2021,1,1):Day(1):Date(2021,1,6)),
        collect(Date(2022,1,1):Day(1):Date(2022,1,6)),
        collect(Date(2023,1,1):Day(1):Date(2023,1,6))
    )

    # Baseline (2021-2022) low, later year (2023) very high
    chl = vcat(
        fill(1.0, 6),
        fill(1.0, 6),
        fill(10.0, 6)
    )

    # Baseline should be 2021:2022 only, so climatology around ~1.0 for these DOYs
    opts = BloomOptions(min_duration=3, baseline_years=2021:2022, event_min_category=BloomEvents.Likely)

    a = analyze_bloom(dates, chl; options=opts)

    # Jan-1 DOY index (365-day mapping)
    idx = doy365(Date(2021,1,1))

    @test isfinite(a.result.clim365[idx])
    @test a.result.clim365[idx] < 2.0   # should be near 1.0, not inflated by 2023

    # Should detect at least one event in 2023 (because chl=10 > baseline climatology)
    sums = annual_summaries(a, chl)
    yrs = [s.year for s in sums]
    @test 2023 in yrs
end
