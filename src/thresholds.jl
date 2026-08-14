# Percentile threshold estimation (Raulo et al. style)

"""
    quantile_sorted(v, p)

Compute quantile for p in [0,1] from a sorted vector `v` using linear interpolation.
Assumes v is non-empty and sorted ascending.
"""
function quantile_sorted(v::AbstractVector{<:Real}, p::Real)
    0.0 <= p <= 1.0 || throw(ArgumentError("p must be in [0,1]"))
    n = length(v)
    n > 0 || throw(ArgumentError("empty data"))
    if n == 1
        return Float64(v[1])
    end
    # Hyndman & Fan type=7 like many software defaults:
    h = 1 + (n - 1) * Float64(p)
    lo = floor(Int, h)
    hi = ceil(Int, h)
    if lo == hi
        return Float64(v[lo])
    else
        w = h - lo
        return (1 - w) * Float64(v[lo]) + w * Float64(v[hi])
    end
end

"""
    bloom_thresholds_from_subset(chl, mask) -> BloomThresholds

Compute Q25/Q50/Q75/Q90 from chl values where mask is true.
Missing values are ignored.
Throws if there are no valid values.
"""
function bloom_thresholds_from_subset(chl::AbstractVector, mask::AbstractVector{Bool})::BloomThresholds
    length(chl) == length(mask) || throw(ArgumentError("chl and mask must have same length"))

    vals = Float64[]
    for i in eachindex(chl)
        if mask[i] && !ismissing(chl[i])
            push!(vals, Float64(chl[i]))
        end
    end
    isempty(vals) && throw(ArgumentError("no valid values to compute thresholds"))

    sort!(vals)
    q25 = quantile_sorted(vals, 0.25)
    q50 = quantile_sorted(vals, 0.50)
    q75 = quantile_sorted(vals, 0.75)
    q90 = quantile_sorted(vals, 0.90)
    return BloomThresholds(q25, q50, q75, q90)
end
