using Test
using Dates
using BloomEvents

@testset "CSV export" begin
    # small fake event
    ev = BloomEvent(1, 3, Date(2021,1,1), Date(2021,1,3), 3, 2.0, BloomEvents.Bloom)
    events = [ev]

    s = AnnualBloomSummary(2021, 1, 3, 3.0, 0.5, 1.0, 1.5, 0.1, 0.1)
    sums = [s]

    tmp_events = joinpath(pwd(), "tmp_events.csv")
    tmp_annual = joinpath(pwd(), "tmp_annual.csv")

    write_events_csv(tmp_events, events)
    write_annual_csv(tmp_annual, sums)

    @test isfile(tmp_events)
    @test isfile(tmp_annual)

    # cleanup
    rm(tmp_events; force=true)
    rm(tmp_annual; force=true)
end
