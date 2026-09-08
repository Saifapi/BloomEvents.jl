using Test
using Dates
using BloomEvents

@testset "event_peak_category_stack totals and NaN policy" begin
    dates = vcat(
        collect(Date(2021,1,1):Day(1):Date(2021,1,6)),
        collect(Date(2022,1,1):Day(1):Date(2022,1,6))
    )
    nt = length(dates)
    chl3d = Array{Union{Missing,Float64}}(undef, nt, 1, 2)

    # Pixel 1: should be computable (year2 higher)
    chl3d[:,1,1] = vcat(fill(1.0, 6), fill(3.0, 6))

    # Pixel 2: all missing => not computable => NaN
    chl3d[:,1,2] = fill(missing, nt)

    years = 2021:2022
    opts = BloomOptions(min_duration=3, max_gap=0, event_min_category=BloomEvents.Likely)
    gopt = GridOptions(min_valid_fraction=0.3, threads=false)

    st = event_peak_category_stack(dates, chl3d, years; bloom_options=opts, grid_options=gopt)

    # Pixel 2 is NaN
    @test isnan(st.events_total[1,1,2])
    @test isnan(st.events_peak_likely[2,1,2])

    # Pixel 1 totals equal sum of peak-category counts (for both years)
    for yi in 1:length(years)
        total = st.events_total[yi,1,1]
        sumcats = st.events_peak_likely[yi,1,1] + st.events_peak_bloom[yi,1,1] +
                  st.events_peak_intense[yi,1,1] + st.events_peak_extreme[yi,1,1]
        @test total == sumcats
        @test total >= 0
    end
end
