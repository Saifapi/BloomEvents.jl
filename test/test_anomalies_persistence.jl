using Test
using Dates
using BloomEvents

@testset "positive_anomaly_mask" begin
    chl = [1.0, 2.0, missing, 4.0]
    clim = [0.5, 2.0, 1.0, NaN]
    mask = positive_anomaly_mask(chl, clim)
    @test mask == BitVector([true, false, false, false])
end

@testset "persistence_filter" begin
    mask = BitVector([false, true, true, false, true, true, true, false])
    out2 = persistence_filter(mask; min_duration=2)
    out3 = persistence_filter(mask; min_duration=3)

    @test out2 == BitVector([false, true, true, false, true, true, true, false])
    @test out3 == BitVector([false, false, false, false, true, true, true, false])
end
