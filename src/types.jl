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

"""
One detected bloom event.

- start_idx/end_idx refer to positions in the input time series
- start_date/end_date are inclusive
"""
struct BloomEvent
    start_idx::Int
    end_idx::Int
    start_date::Date
    end_date::Date
    duration::Int
    peak_chl::Float64
    peak_category::BloomCategory
end

"""User options controlling persistence and event rules."""
Base.@kwdef struct BloomOptions
    # persistence used when forming the anomaly subset for thresholds
    min_duration::Int = 3

    # gap bridging for event detection (0 = strict consecutive days)
    max_gap::Int = 0

    # event definition: event days are those with category >= this level
    event_min_category::BloomCategory = Likely

    baseline_years::Union{Nothing,UnitRange{Int}} = nothing
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

"""High-level output: day-level result + event list + options used."""
struct BloomAnalysis
    result::BloomResult
    events::Vector{BloomEvent}
    options::BloomOptions
end

"""Event-level metrics computed from chl and climatology (intensity = chl - clim)."""
struct BloomEventMetrics
    start_idx::Int
    end_idx::Int
    duration::Int
    peak_idx::Int

    mean_intensity::Float64
    max_intensity::Float64
    cumulative_intensity::Float64

    rate_onset::Float64     # intensity/day
    rate_decline::Float64   # intensity/day
end

"""Per-year summary statistics derived from events and event metrics."""
struct AnnualBloomSummary
    year::Int
    frequency::Int
    total_days::Int
    mean_duration::Float64

    mean_intensity::Float64
    max_intensity::Float64
    cumulative_intensity::Float64

    mean_rate_onset::Float64
    mean_rate_decline::Float64
end
