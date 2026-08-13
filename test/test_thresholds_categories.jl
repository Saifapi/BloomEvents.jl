using Test
using BloomEvents

@testset "quantile_sorted" begin
    v = [1.0, 2.0, 3.0, 4.0]
    @test quantile_sorted(v, 0.0) == 1.0
    @test quantile_sorted(v, 1.0) == 4.0
    @test quantile_sorted(v, 0.5) == 2.5
end

@testset "bloom_thresholds_from_subset and label_days" begin
    chl = [0.5, 1.0, 2.0, 3.0, 4.0, missing]
    mask = BitVector([true, true, true, true, true, true])

    thr = bloom_thresholds_from_subset(chl, mask)

    @test thr.q25 >= 0.5
    @test thr.q90 <= 4.0
    @test thr.q25 <= thr.q50 <= thr.q75 <= thr.q90

    labels = label_days(chl, thr)
    @test labels[end] == BloomEvents.NoBloom
end
