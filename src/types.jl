# Core types and enums for BloomEvents.jl

"""
Bloom category based on percentile thresholds (Raulo et al., 2025):

- Likely:  Q25 ≤ chl < Q50
- Bloom:   Q50 ≤ chl < Q75
- Intense: Q75 ≤ chl < Q90
- Extreme: chl ≥ Q90
"""
@enum BloomCategory begin
    NoBloom = 0
    Likely
    Bloom
    Intense
    Extreme
end

"""Holds percentile thresholds (Q25, Q50, Q75, Q90)."""
struct BloomThresholds
    q25::Float64
    q50::Float64
    q75::Float64
    q90::Float64
end

"""One detected bloom event (start/end are inclusive)."""
struct BloomEvent
    start_date::Date
    end_date::Date
end

"""User options controlling persistence and handling of missing data."""
Base.@kwdef struct BloomOptions
    min_duration::Int = 3
    max_gap::Int = 0   # reserved for later; not used yet
end

"""Container for outputs from the detection pipeline."""
struct BloomResult
    clim365::Vector{Float64}
    clim_at_dates::Vector{Float64}
    posmask::BitVector
    posmask_persist::BitVector
    thresholds::BloomThresholds
    labels::Vector{BloomCategory}
end
