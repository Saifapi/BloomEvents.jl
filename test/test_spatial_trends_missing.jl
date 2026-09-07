using Test
using BloomEvents

@testset "mean_over_years handles missing" begin
    years = [2001,2002,2003]
    stack = Array{Union{Missing,Float64}}(undef, 3, 1, 1)
    stack[:,1,1] = [1.0, missing, 3.0]

    m = mean_over_years(stack)
    @test m[1,1] == 2.0

    slope = linear_trend_map(stack, years; min_points=2, per_decade=false)
    @test isfinite(slope[1,1])
end
