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

end # module BloomEvents
