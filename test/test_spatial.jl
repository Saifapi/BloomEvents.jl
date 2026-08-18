using Test
using Dates
using BloomEvents

@testset "annual_metric_maps small cube" begin
    # 12 days across 2 years (same DOY blocks)
    dates = vcat(
        collect(Date(2021,1,1):Day(1):Date(2021,1,6)),
        collect(Date(2022,1,1):Day(1):Date(2022,1,6))
    )

    nt = length(dates)
    ny, nx = 2, 2

    chl3d = Array{Union{Missing,Float64}}(undef, nt, ny, nx)

    # Pixel (1,1): year1 low, year2 all 3.0 -> persistent positive anomalies exist
    chl3d[:,1,1] = vcat(fill(1.0, 6), fill(3.0, 6))

    # Pixel (1,2): all missing -> insufficient data
    chl3d[:,1,2] = fill(missing, nt)

    # Pixel (2,1): constant -> analyze_bloom likely fails (no thresholds) but must not crash
    chl3d[:,2,1] = fill(1.0, nt)

    # Pixel (2,2): mixed missing but enough valid; still no events likely
    chl3d[:,2,2] = vcat(fill(1.0, 6), [missing, 1.0, 1.0, missing, 1.0, 1.0])

    maps = annual_metric_maps(dates, chl3d, 2022;
        bloom_options=BloomOptions(min_duration=3, max_gap=0, event_min_category=BloomEvents.Likely),
        grid_options=GridOptions(min_valid_fraction=0.3)
    )

    @test size(maps.frequency) == (ny, nx)

    # (1,1) should have at least 1 event or at minimum a non-NaN frequency (0 or more)
    @test !isnan(maps.frequency[1,1])

    # (1,2) all missing => NaN
    @test isnan(maps.frequency[1,2])
end
