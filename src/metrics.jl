# Event metrics

"""
    event_intensity(chl, clim_at_dates) -> Vector{Union{Missing,Float64}}

Intensity is defined as chl - climatology_at_date.
"""
function event_intensity(chl::AbstractVector, clim_at_dates::AbstractVector{<:Real})
    return anomaly_series(chl, clim_at_dates)
end

"""
    compute_event_metrics(events, chl, clim_at_dates) -> Vector{BloomEventMetrics}

Compute intensity and rate metrics for each detected bloom event.

Intensity is defined as `chl - climatology_at_date`.

For each event, the following metrics are computed:
- `mean_intensity`: mean valid intensity during the event.
- `max_intensity`: maximum valid intensity during the event.
- `cumulative_intensity`: sum of valid intensity values during the event.
- `rate_onset`: change in intensity from the event start to the peak,
  divided by the number of days to the peak.
- `rate_decline`: change in intensity from the event end to the peak,
  divided by the number of days from the peak to the event end.

Missing chlorophyll or intensity values are ignored in the mean, maximum,
and cumulative calculations. If an event has no valid intensity values,
all intensity and rate metrics are `NaN`.
"""
function compute_event_metrics(events::AbstractVector{BloomEvent},
                               chl::AbstractVector,
                               clim_at_dates::AbstractVector{<:Real})

    length(chl) == length(clim_at_dates) || throw(ArgumentError("chl and clim_at_dates must have same length"))
    intensity = event_intensity(chl, clim_at_dates)

    out = BloomEventMetrics[]
    for ev in events
        s = ev.start_idx
        e = ev.end_idx

        vals = Float64[]
        maxI = -Inf
        peak_idx = s

        for i in s:e
            Ii = intensity[i]
            if !ismissing(Ii)
                v = Float64(Ii)
                push!(vals, v)
                if v > maxI
                    maxI = v
                    peak_idx = i
                end
            end
        end

        if isempty(vals)
            meanI = NaN
            maxI2 = NaN
            cumI  = NaN
            rate_on = NaN
            rate_de = NaN
            peak_idx = s
        else
            meanI = mean(vals)
            maxI2 = maxI
            cumI  = sum(vals)

            # Onset/decline rates based on intensity change to peak.
            Istart = intensity[s]; Iend = intensity[e]
            Istart = ismissing(Istart) ? vals[1] : Float64(Istart)
            Iend   = ismissing(Iend)   ? vals[end] : Float64(Iend)

            days_to_peak = max(1, peak_idx - s)
            days_from_peak = max(1, e - peak_idx)

            rate_on = (maxI2 - Istart) / days_to_peak
            rate_de = (maxI2 - Iend) / days_from_peak
        end

        push!(out, BloomEventMetrics(
            s, e, ev.duration, peak_idx,
            meanI, maxI2, cumI,
            rate_on, rate_de
        ))
    end

    return out
end
