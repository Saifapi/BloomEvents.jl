using Test
using Dates
using BloomEvents

@testset "category_day_stack shapes and NaN policy" begin
    # Two-year small dataset (ensures thresholds can be computed for at least one pixel)
    dates = vcat(
        collect(Date(2021,1,1):Day(1):Date(2021,1,6)),
        collect(Date(2022,1,1):Day(1):Date(2022,1,6))
    )
    nt = length(dates)
    nlat, nlon = 2, 2

    chl3d = Array{Union{Missing,Float64}}(undef, nt, nlat, nlon)

    chl3d[:,1,1] = vcat(fill(1.0, 6), fill(3.0, 6))  # should be computable
    chl3d[:,1,2] = fill(missing, nt)                 # not computable
    chl3d[:,2,1] = fill(1.0, nt)                     # likely not computable (no anomalies)
    chl3d[:,2,2] = vcat(fill(1.0, 6), [missing, 1.0, 1.0, missing, 1.0, 1.0])

    years = 2021:2022

    out = category_day_stack(dates, chl3d, years;
        bloom_options=BloomOptions(min_duration=3),
        grid_options=GridOptions(min_valid_fraction=0.3)
    )

    @test out.years == collect(years)
    @test size(out.days_likely) == (2, 2, 2)

    # all-missing pixel should remain NaN
    @test isnan(out.days_likely[1,1,2])
    @test isnan(out.days_extreme[2,1,2])

    # computable pixel should not be NaN (0 or more)
    @test !isnan(out.days_likely[1,1,1])

    # day counts cannot exceed number of days in that year subset (here 6)
    @test out.days_likely[1,1,1] + out.days_bloom[1,1,1] + out.days_intense[1,1,1] + out.days_extreme[1,1,1] <= 6
end
