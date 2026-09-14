# Annual summaries (1D)

"""
    annual_summaries(events, metrics) -> Vector{AnnualBloomSummary}

Aggregate event counts and metrics by the year in which each event starts.

For each year:
- `frequency` is the number of events starting in that year.
- `total_days` is the sum of durations of those events.
- `mean_duration` is their mean duration.
- `mean_intensity` is the mean event intensity.
- `max_intensity` is the maximum event intensity.
- `cumulative_intensity` is the sum of cumulative event intensities.
- `mean_rate_onset` is the mean onset rate.
- `mean_rate_decline` is the mean decline rate.

An event spanning multiple calendar years is assigned entirely to the year
of its `start_date`. Overlap-aware calendar-year totals are not currently
used.
"""
function annual_summaries(events::AbstractVector{BloomEvent},
                          metrics::AbstractVector{BloomEventMetrics})

    length(events) == length(metrics) || throw(ArgumentError("events and metrics must have same length"))

    # group indices by year of start_date
    years = Int[year(ev.start_date) for ev in events]
    uy = sort!(unique(years))

    out = AnnualBloomSummary[]
    for y in uy
        idxs = findall(==(y), years)
        freq = length(idxs)
        durs = [events[i].duration for i in idxs]
        total_days = sum(durs)
        mean_dur = mean(Float64.(durs))

        meanI = [metrics[i].mean_intensity for i in idxs]
        maxI  = [metrics[i].max_intensity for i in idxs]
        cumI  = [metrics[i].cumulative_intensity for i in idxs]
        ron   = [metrics[i].rate_onset for i in idxs]
        rdec  = [metrics[i].rate_decline for i in idxs]

        push!(out, AnnualBloomSummary(
            y,
            freq,
            total_days,
            mean_dur,
            mean(meanI),
            maximum(maxI),
            sum(cumI),
            mean(ron),
            mean(rdec)
        ))
    end

    return out
end

"""
    annual_summaries(analysis, chl) -> Vector{AnnualBloomSummary}

Convenience method:
- uses analysis.events
- computes metrics using analysis.result.clim_at_dates
"""
function annual_summaries(analysis::BloomAnalysis, chl::AbstractVector)
    mets = compute_event_metrics(analysis.events, chl, analysis.result.clim_at_dates)
    return annual_summaries(analysis.events, mets)
end

"""
    annual_table(summaries) -> NamedTuple of vectors

Returns column vectors convenient for CSV writing or plotting.
"""
function annual_table(summaries::AbstractVector{AnnualBloomSummary})
    years = [s.year for s in summaries]
    frequency = [s.frequency for s in summaries]
    total_days = [s.total_days for s in summaries]
    mean_duration = [s.mean_duration for s in summaries]
    mean_intensity = [s.mean_intensity for s in summaries]
    max_intensity = [s.max_intensity for s in summaries]
    cumulative_intensity = [s.cumulative_intensity for s in summaries]
    mean_rate_onset = [s.mean_rate_onset for s in summaries]
    mean_rate_decline = [s.mean_rate_decline for s in summaries]

    return (; years, frequency, total_days, mean_duration,
            mean_intensity, max_intensity, cumulative_intensity,
            mean_rate_onset, mean_rate_decline)
end
