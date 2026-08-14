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

export BloomThresholds, BloomEvent, BloomResult, BloomOptions
export BloomCategory

export doy365, daily_climatology_mean, climatology_at_dates
export positive_anomaly_mask, anomaly_series
export persistence_filter
export quantile_sorted, bloom_thresholds_from_subset
export label_days, fit_bloom

end # module BloomEvents
