module BloomEvents

using Dates
using Statistics

# ---- Core types ----
include("types.jl")

# ---- Core workflow components (to be implemented next) ----
include("utils.jl")
include("climatology.jl")
include("anomalies.jl")
include("persistence.jl")
include("thresholds.jl")
include("detection.jl")

# ---- Public API (we will fill functions later) ----
export BloomThresholds, BloomEvent, BloomResult, BloomOptions
export BloomCategory
export doy365, daily_climatology_mean, climatology_at_dates`nexport positive_anomaly_mask, anomaly_series`nexport persistence_filter

end # module BloomEvents
