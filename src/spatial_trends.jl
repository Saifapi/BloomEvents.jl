# Spatial mean/trend utilities for stacks shaped as (year, lat, lon)
# Supports NaN and missing.

"""
    nanmean(v) -> Float64

Mean ignoring NaNs and missings. Returns NaN if no valid values.
"""
function nanmean(v::AbstractVector)
    s = 0.0
    n = 0
    for x in v
        if ismissing(x)
            continue
        end
        fx = Float64(x)
        if !isnan(fx)
            s += fx
            n += 1
        end
    end
    return n == 0 ? NaN : s / n
end

"""
    mean_over_years(stack) -> Matrix{Float64}

Compute mean across the year dimension (dim=1), ignoring NaNs and missings.

Input:
- stack: Array with size (nyears, nlat, nlon); element type may include Missing

Output:
- mean_map: Matrix{Float64} with size (nlat, nlon)
"""
function mean_over_years(stack::AbstractArray{T,3}) where {T}
    ny, nlat, nlon = size(stack)
    out = fill(NaN, nlat, nlon)
    for j in 1:nlat, i in 1:nlon
        out[j,i] = nanmean(view(stack, :, j, i))
    end
    return out
end

"""
    linear_trend_map(stack, years; min_points=10, per_decade=true) -> Matrix{Float64}

Compute linear trend slope per pixel using least squares, ignoring NaNs and missings.

- stack: (nyears, nlat, nlon), element type may include Missing
- years: Vector{Int} of length nyears
- min_points: minimum valid years required to compute slope
- per_decade: if true, slope is scaled by 10

Returns:
- slope_map: (nlat, nlon), NaN where not computable
"""
function linear_trend_map(stack::AbstractArray{T,3},
                          years::AbstractVector{<:Integer};
                          min_points::Int = 10,
                          per_decade::Bool = true) where {T}

    ny, nlat, nlon = size(stack)
    length(years) == ny || throw(ArgumentError("length(years) must match size(stack,1)"))
    min_points >= 2 || throw(ArgumentError("min_points must be >= 2"))

    xall = Float64.(years)
    out = fill(NaN, nlat, nlon)

    for j in 1:nlat, i in 1:nlon
        yv = view(stack, :, j, i)

        xs = Float64[]
        ys = Float64[]
        for k in 1:ny
            y = yv[k]
            if ismissing(y)
                continue
            end
            fy = Float64(y)
            if !isnan(fy)
                push!(xs, xall[k])
                push!(ys, fy)
            end
        end

        if length(ys) < min_points
            continue
        end

        xmean = mean(xs)
        ymean = mean(ys)

        num = 0.0
        den = 0.0
        for k in eachindex(ys)
            dx = xs[k] - xmean
            dy = ys[k] - ymean
            num += dx * dy
            den += dx * dx
        end

        den == 0.0 && continue

        slope = num / den
        out[j,i] = per_decade ? slope * 10.0 : slope
    end

    return out
end
