# QA / diagnostics utilities (core, no extra dependencies)

"""
    is_sorted_dates(dates) -> Bool

Return true if `dates` is nondecreasing.
"""
is_sorted_dates(dates::AbstractVector{Date}) = issorted(dates)

"""
    daily_gaps(dates) -> Vector{Tuple{Int,Day}}

Return a vector of (i, Δ) where Δ = dates[i+1] - dates[i] is not Day(1).
Useful to diagnose missing days or irregular sampling.
"""
function daily_gaps(dates::AbstractVector{Date})
    gaps = Tuple{Int,Day}[]
    n = length(dates)
    n <= 1 && return gaps
    for i in 1:(n-1)
        Δ = dates[i+1] - dates[i]
        if Δ != Day(1)
            push!(gaps, (i, Δ))
        end
    end
    return gaps
end

"""
    check_daily(dates; strict=true) -> Bool

Check whether dates are sorted and daily (Δ=1 day).
- If strict=true: throws ArgumentError when not daily/sorted
- If strict=false: returns false when not daily/sorted
"""
function check_daily(dates::AbstractVector{Date}; strict::Bool=true)
    if !is_sorted_dates(dates)
        strict && throw(ArgumentError("dates are not sorted"))
        return false
    end
    gaps = daily_gaps(dates)
    if !isempty(gaps)
        strict && throw(ArgumentError("dates are not daily; found $(length(gaps)) gaps (first gap at index $(gaps[1][1]) with Δ=$(gaps[1][2]))"))
        return false
    end
    return true
end

# Treat missing and NaN as invalid
_invalid(x) = ismissing(x) || (x isa Real && isnan(Float64(x)))

"""
    missing_fraction(x) -> Float64

Fraction of elements that are invalid (missing or NaN).
"""
function missing_fraction(x::AbstractVector)
    n = length(x)
    n == 0 && return NaN
    bad = 0
    for v in x
        bad += _invalid(v) ? 1 : 0
    end
    return bad / n
end

"""
    valid_fraction(x) -> Float64

Fraction of elements that are valid (not missing and not NaN).
"""
function valid_fraction(x::AbstractVector)
    n = length(x)
    n == 0 && return NaN
    good = 0
    for v in x
        good += _invalid(v) ? 0 : 1
    end
    return good / n
end

"""
    count_valid_pixels(map2d) -> Int

Count valid pixels in a 2D array (not missing, not NaN).
"""
function count_valid_pixels(map2d::AbstractArray)
    n = 0
    for v in map2d
        n += _invalid(v) ? 0 : 1
    end
    return n
end

"""
    fraction_valid_pixels(map2d) -> Float64

Fraction of valid pixels in a 2D array (not missing, not NaN).
"""
function fraction_valid_pixels(map2d::AbstractArray)
    total = length(map2d)
    total == 0 && return NaN
    return count_valid_pixels(map2d) / total
end
