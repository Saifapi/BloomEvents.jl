# Day-level classification (categories) + high-level workflow

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
                   min_duration::Int = 3)

    clim365 = daily_climatology_mean(dates, chl)
    clim_at = climatology_at_dates(dates, clim365)

    posmask = positive_anomaly_mask(chl, clim_at)
    posmask_persist = persistence_filter(posmask; min_duration=min_duration)

    thr = bloom_thresholds_from_subset(chl, posmask_persist)
    labels = label_days(chl, thr)

    return BloomResult(clim365, clim_at, posmask, posmask_persist, thr, labels)
end
