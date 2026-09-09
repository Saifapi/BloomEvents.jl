# Day-level classification (categories) + high-level workflow + events

"""
    label_days(chl, thr::BloomThresholds) -> Vector{BloomCategory}

Classify each day by chlorophyll-a thresholds:
- Likely:  Q25 ≤ chl < Q50
- Bloom:   Q50 ≤ chl < Q75
- Intense: Q75 ≤ chl < Q90
- Extreme: chl ≥ Q90
- NoBloom: chl < Q25 or missing
"""
function label_days(chl::AbstractVector, thr::BloomThresholds)
    out = Vector{BloomCategory}(undef, length(chl))
    for i in eachindex(chl)
        x = chl[i]
        if ismissing(x)
            out[i] = NoBloom
            continue
        end
        v = Float64(x)
        if v < thr.q25
            out[i] = NoBloom
        elseif v < thr.q50
            out[i] = Likely
        elseif v < thr.q75
            out[i] = Bloom
        elseif v < thr.q90
            out[i] = Intense
        else
            out[i] = Extreme
        end
    end
    return out
end

"""
    fit_bloom(dates, chl; min_duration=3) -> BloomResult

Raulo et al.-style workflow:
1) 365-day climatology mean
2) positive anomalies: chl > climatology
3) persistence filter (default 3 days)
4) thresholds (Q25/Q50/Q75/Q90) computed from the persistent positive-anomaly subset
5) label all days into bloom categories using thresholds
"""
function fit_bloom(dates::AbstractVector{Date},
                   chl::AbstractVector;
                   min_duration::Int = 3,
                   baseline_years::Union{Nothing,UnitRange{Int}} = nothing)

    clim365 = daily_climatology_mean(dates, chl; baseline_years=baseline_years)
    clim_at = climatology_at_dates(dates, clim365)

    posmask = positive_anomaly_mask(chl, clim_at)
    posmask_persist = persistence_filter(posmask; min_duration=min_duration)

    thr = bloom_thresholds_from_subset(chl, posmask_persist)
    labels = label_days(chl, thr)

    return BloomResult(clim365, clim_at, posmask, posmask_persist, thr, labels)
end

"""
    event_day_mask(labels; min_category=Likely) -> BitVector

Days considered part of an event are those with category >= min_category.
"""
function event_day_mask(labels::AbstractVector{BloomCategory};
                        min_category::BloomCategory = Likely)
    out = falses(length(labels))
    minv = Int(min_category)
    for i in eachindex(labels)
        out[i] = Int(labels[i]) >= minv
    end
    return out
end

"""
    fill_short_gaps(mask; max_gap=0) -> BitVector

If max_gap > 0, fill false-runs of length <= max_gap that are between true runs.
"""
function fill_short_gaps(mask::AbstractVector{Bool}; max_gap::Int = 0)
    max_gap >= 0 || throw(ArgumentError("max_gap must be >= 0"))
    out = BitVector(mask)
    max_gap == 0 && return out

    n = length(out)
    i = 1
    while i <= n
        if !out[i]
            j = i
            while j <= n && !out[j]
                j += 1
            end
            gaplen = j - i
            left_true  = (i > 1) && out[i-1]
            right_true = (j <= n) && out[j]
            if left_true && right_true && gaplen <= max_gap
                out[i:j-1] .= true
            end
            i = j
        else
            i += 1
        end
    end
    return out
end

"""
    detect_events(dates, chl, labels; min_category=Likely, min_duration=3, max_gap=0) -> Vector{BloomEvent}

Segment consecutive (optionally gap-bridged) event days into events.
"""
function detect_events(dates::AbstractVector{Date},
                       chl::AbstractVector,
                       labels::AbstractVector{BloomCategory};
                       min_category::BloomCategory = Likely,
                       min_duration::Int = 3,
                       max_gap::Int = 0)

    length(dates) == length(chl) == length(labels) || throw(ArgumentError("dates/chl/labels must have same length"))
    min_duration >= 1 || throw(ArgumentError("min_duration must be >= 1"))

    base = event_day_mask(labels; min_category=min_category)
    bridged = fill_short_gaps(base; max_gap=max_gap)
    keep = persistence_filter(bridged; min_duration=min_duration)

    events = BloomEvent[]
    n = length(keep)
    i = 1
    while i <= n
        if keep[i]
            j = i
            while j <= n && keep[j]
                j += 1
            end
            s = i
            e = j - 1

            # peak chl (ignore missing)
            peak = -Inf
            peakcat = NoBloom
            for k in s:e
                if !ismissing(chl[k])
                    v = Float64(chl[k])
                    if v > peak
                        peak = v
                    end
                end
                if Int(labels[k]) > Int(peakcat)
                    peakcat = labels[k]
                end
            end
            peak = isfinite(peak) ? peak : NaN

            push!(events, BloomEvent(
                s, e,
                dates[s], dates[e],
                e - s + 1,
                peak,
                peakcat
            ))

            i = j
        else
            i += 1
        end
    end

    return events
end

"""
    analyze_bloom(dates, chl; options=BloomOptions()) -> BloomAnalysis

Convenience function that runs the full workflow:
- thresholds + labels (fit_bloom)
- event segmentation (detect_events)
"""
function analyze_bloom(dates::AbstractVector{Date},
                       chl::AbstractVector;
                       options::BloomOptions = BloomOptions())
    if options.check_dates
        check_daily(dates; strict=options.strict_daily)
    end

    res = fit_bloom(dates, chl; min_duration=options.min_duration, baseline_years = options.baseline_years)

    ev = detect_events(dates, chl, res.labels;
        min_category = options.event_min_category,
        min_duration = options.min_duration,
        max_gap      = options.max_gap
    )

    return BloomAnalysis(res, ev, options)
end
