using Test
using BloomEvents

@testset "mean_over_years and linear_trend_map" begin
    years = [2001, 2002, 2003]
    ny, nlat, nlon = 3, 2, 2

    stack = fill(NaN, ny, nlat, nlon)

    # Pixel (1,1): y = [1,2,3] -> slope = 1/year -> 10/decade
    stack[:,1,1] = [1.0, 2.0, 3.0]

    # Pixel (1,2): constant -> slope 0
    stack[:,1,2] = [5.0, 5.0, 5.0]

    # Pixel (2,1): NaNs -> remains NaN
    stack[:,2,1] = [NaN, NaN, NaN]

    # Pixel (2,2): partial -> slope from two points (use min_points=2)
    stack[:,2,2] = [NaN, 1.0, 3.0]  # slope 2/year -> 20/decade

    m = mean_over_years(stack)
    @test m[1,1] == 2.0
    @test m[1,2] == 5.0
    @test isnan(m[2,1])
    @test m[2,2] == 2.0

    slope = linear_trend_map(stack, years; min_points=2, per_decade=true)
    @test isapprox(slope[1,1], 10.0; atol=1e-8)
    @test isapprox(slope[1,2], 0.0; atol=1e-8)
    @test isnan(slope[2,1])
    @test isapprox(slope[2,2], 20.0; atol=1e-8)
end
