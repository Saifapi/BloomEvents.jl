# Simple CSV export (no external dependencies)

# Escape CSV field if needed
function _csv_escape(x)::String
    s = string(x)
    if occursin('"', s)
        s = replace(s, '"' => "\"\"")
    end
    if occursin(',', s) || occursin('"', s) || occursin('\n', s)
        return "\"" * s * "\""
    else
        return s
    end
end

"""
    write_events_csv(path, events)

Write bloom events to a CSV file.
"""
function write_events_csv(path::AbstractString, events::AbstractVector{BloomEvent})
    open(path, "w") do io
        println(io, "start_date,end_date,duration,peak_chl,peak_category,start_idx,end_idx")
        for ev in events
            row = join((
                _csv_escape(ev.start_date),
                _csv_escape(ev.end_date),
                _csv_escape(ev.duration),
                _csv_escape(ev.peak_chl),
                _csv_escape(ev.peak_category),
                _csv_escape(ev.start_idx),
                _csv_escape(ev.end_idx),
            ), ",")
            println(io, row)
        end
    end
    return path
end

"""
    write_annual_csv(path, summaries)

Write annual summaries to a CSV file.
"""
function write_annual_csv(path::AbstractString, summaries::AbstractVector{AnnualBloomSummary})
    open(path, "w") do io
        println(io, "year,frequency,total_days,mean_duration,mean_intensity,max_intensity,cumulative_intensity,mean_rate_onset,mean_rate_decline")
        for s in summaries
            row = join((
                _csv_escape(s.year),
                _csv_escape(s.frequency),
                _csv_escape(s.total_days),
                _csv_escape(s.mean_duration),
                _csv_escape(s.mean_intensity),
                _csv_escape(s.max_intensity),
                _csv_escape(s.cumulative_intensity),
                _csv_escape(s.mean_rate_onset),
                _csv_escape(s.mean_rate_decline),
            ), ",")
            println(io, row)
        end
    end
    return path
end
