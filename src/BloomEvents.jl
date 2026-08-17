module BloomEvents

using Dates
using Statistics

include("types.jl")
include("utils.jl")
include("climatology.jl")
include("anomalies.jl")
include("persistence.jl")
include("thresholds.jl")
include("detection.jl")
include("metrics.jl")

export BloomThresholds, BloomEvent, BloomResult, BloomAnalysis, BloomOptions
export BloomCategory
export BloomEventMetrics

export doy365, daily_climatology_mean, climatology_at_dates
export positive_anomaly_mask, anomaly_series
export persistence_filter
export quantile_sorted, bloom_thresholds_from_subset
export label_days, fit_bloom
export event_day_mask, fill_short_gaps, detect_events
export analyze_bloom

export event_intensity, compute_event_metrics

end # module BloomEvents
