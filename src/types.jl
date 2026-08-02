# Core types and enums for BloomEvents.jl

\"\"\"
Bloom category based on percentile thresholds from Raulo et al. (2025):

- Likely:  Q25 ≤ chl < Q50
- Bloom:   Q50 ≤ chl < Q75
- Intense: Q75 ≤ chl < Q90
- Extreme: chl ≥ Q90
\"\"\"
@enum BloomCategory begin
    NoBloom = 0
    Likely
    Bloom
    Intense
    Extreme
end

\"\"\"Holds percentile thresholds (Q25, Q50, Q75, Q90) and metadata.\"\"\"
struct BloomThresholds
    q25::Float64
    q50::Float64
    q75::Float64
    q90::Float64
end

\"\"\"One detected bloom event (start/end are inclusive).\"\"\"
struct BloomEvent
    start_date::Date
    end_date::Date
end

\"\"\"User options controlling persistence and handling of missing data.\"\"\"
Base.@kwdef struct BloomOptions
    min_duration::Int = 3
    max_gap::Int = 0
end

\"\"\"Container for outputs (will expand later).\"\"\"
struct BloomResult
    thresholds::BloomThresholds
end
