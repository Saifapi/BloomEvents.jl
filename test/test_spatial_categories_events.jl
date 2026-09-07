using Test
using Dates
using BloomEvents

@testset "event-only category days <= all-days category days" begin
    dates = vcat(
        collect(Date(2021,1,1):Day(1):Date(2021,1,12)),
        collect(Date(2022,1,1):Day(1):Date(2022,1,12))
    )
    nt = length(dates)

    chl3d = Array{Union{Missing,Float64}}(undef, nt, 1, 1)

    chl3d[:,1,1] = vcat(
        fill(1.0, 12),
        vcat(fill(1.0, 4), fill(3.0, 3), fill(1.0, 5))
    )

    years = 2021:2022
    opts = BloomOptions(min_duration=3, max_gap=0, event_min_category=BloomEvents.Likely)
    gopt = GridOptions(min_valid_fraction=0.3, threads=false)

    allcats = category_day_stack(dates, chl3d, years; bloom_options=opts, grid_options=gopt)
    evcats  = category_event_day_stack(dates, chl3d, years; bloom_options=opts, grid_options=gopt)

    function check(ev_arr, all_arr)
        ok = (isnan.(ev_arr) .& isnan.(all_arr)) .|
             ((.!isnan.(ev_arr)) .& (.!isnan.(all_arr)) .& (ev_arr .<= all_arr))
        return Base.all(ok)
    end

    @test check(evcats.event_days_likely,  allcats.days_likely)
    @test check(evcats.event_days_bloom,   allcats.days_bloom)
    @test check(evcats.event_days_intense, allcats.days_intense)
    @test check(evcats.event_days_extreme, allcats.days_extreme)
end
