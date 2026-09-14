# Climatology utilities for BloomEvents.jl

"""
    doy365(d::Date) -> Int

Map a Date to a 1..365 day-of-year index by ignoring Feb 29.
- Feb 29 is mapped to the Feb 28 index (59).
- Dates after Feb 28 in leap years are shifted by -1.
"""
function doy365(d::Date)::Int
    if month(d) == 2 && day(d) == 29
        return 59  # map leap day to Feb-28 index in 365-day climatology
    end
    doy = dayofyear(d)
    if isleapyear(year(d)) && d > Date(year(d), 2, 28)
        return doy - 1
    else
        return doy
    end
end

"""
    daily_climatology_mean(dates, chl; baseline_years=nothing) -> Vector{Float64}

Compute 365-day climatological mean chlorophyll-a by day-of-year (`doy365`),
ignoring missing values.

If `baseline_years` is provided, only observations from those years are used
to compute the climatology.

Returns a length-365 vector with `NaN` for days that have no valid data.
"""
function daily_climatology_mean(dates::AbstractVector{Date},
                                chl::AbstractVector;
                                baseline_years::Union{Nothing,UnitRange{Int}}=nothing
                                )::Vector{Float64}
    length(dates) == length(chl) || throw(ArgumentError("dates and chl must have same length"))

    bins = [Float64[] for _ in 1:365]

    for (d, x) in zip(dates, chl)
        ismissing(x) && continue
        # ADD THIS:
        if baseline_years !== nothing && !(year(d) in baseline_years)
            continue
        end
        idx = doy365(d)
        push!(bins[idx], Float64(x))
    end

    clim = fill(NaN, 365)
    for i in 1:365
        if !isempty(bins[i])
            clim[i] = mean(bins[i])
        end
    end
    return clim
end

"""
    climatology_at_dates(dates, clim365) -> Vector{Float64}

Expand a 365-day climatology vector to the same length as dates.
"""
function climatology_at_dates(dates::AbstractVector{Date},
                              clim365::AbstractVector{<:Real})::Vector{Float64}
    length(clim365) == 365 || throw(ArgumentError("clim365 must have length 365"))
    out = Vector{Float64}(undef, length(dates))
    for (i, d) in pairs(dates)
        out[i] = Float64(clim365[doy365(d)])
    end
    return out
end
