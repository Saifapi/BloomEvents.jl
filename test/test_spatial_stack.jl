using Test
using Dates
using BloomEvents

@testset "annual_metric_stack small cube" begin
    dates = vcat(
        collect(Date(2021,1,1):Day(1):Date(2021,1,6)),
        collect(Date(2022,1,1):Day(1):Date(2022,1,6))
    )
    nt = length(dates)
    nlat, nlon = 2, 2

    chl3d = Array{Union{Missing,Float64}}(undef, nt, nlat, nlon)

    # computable pixel (1,1): year2 higher
    chl3d[:,1,1] = vcat(fill(1.0, 6), fill(3.0, 6))

    # not computable pixel (1,2): all missing
    chl3d[:,1,2] = fill(missing, nt)

    # maybe not computable (2,1): constant
    chl3d[:,2,1] = fill(1.0, nt)

    # sparse valid (2,2): still likely no events
    chl3d[:,2,2] = vcat(fill(1.0, 6), [missing, 1.0, 1.0, missing, 1.0, 1.0])

    years = 2021:2022

    st = annual_metric_stack(dates, chl3d, years;
        bloom_options=BloomOptions(min_duration=3, max_gap=0, event_min_category=BloomEvents.Likely),
        grid_options=GridOptions(min_valid_fraction=0.3)
    )

    @test st.years == collect(years)
    @test size(st.frequency) == (length(years), nlat, nlon)

    # computable pixel should have non-NaN frequency for both years (0 or more)
    @test !isnan(st.frequency[1,1,1])
    @test !isnan(st.frequency[2,1,1])

    # all-missing pixel stays NaN
    @test isnan(st.frequency[1,1,2])
    @test isnan(st.frequency[2,1,2])
end
