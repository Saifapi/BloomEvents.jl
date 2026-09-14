# Spatial event-frequency stacks by peak category (year × lat × lon)

"""
    event_peak_category_stack(dates, chl3d, years;
                              bloom_options=BloomOptions(),
                              grid_options=GridOptions())

Count detected bloom events by their peak category for every spatial grid
cell and requested year.

The input `chl3d` must have dimensions:

    chl3d[time, lat, lon]

Returns a `NamedTuple` containing:
- `years`: requested years.
- `events_peak_likely`: number of events peaking in `Likely`.
- `events_peak_bloom`: number of events peaking in `Bloom`.
- `events_peak_intense`: number of events peaking in `Intense`.
- `events_peak_extreme`: number of events peaking in `Extreme`.
- `events_total`: total number of detected events.

All event-count arrays have dimensions `year × lat × lon`.

Event membership follows the rules in `BloomOptions`, including minimum
duration, minimum event category, optional gap bridging, and
`baseline_years` when provided.

Cells that do not satisfy the validity requirements remain `NaN`.
Computable cells with no events in a requested year contain zeros.

The validity requirements are controlled by `GridOptions`.
"""
function event_peak_category_stack(dates::AbstractVector{Date},
                                   chl3d::AbstractArray,
                                   years_in;
                                   bloom_options::BloomOptions = BloomOptions(),
                                   grid_options::GridOptions = GridOptions())
    if bloom_options.check_dates
        check_daily(dates; strict=bloom_options.strict_daily)
    end

    size(chl3d, 1) == length(dates) || throw(ArgumentError("size(chl3d,1) must equal length(dates)"))
    nt = size(chl3d, 1)
    nlat = size(chl3d, 2)
    nlon = size(chl3d, 3)

    years = collect(Int.(years_in))
    ny = length(years)
    ny > 0 || throw(ArgumentError("years must be non-empty"))

    y2i = Dict{Int,Int}(y => k for (k,y) in enumerate(years))

    events_peak_likely  = fill(NaN, ny, nlat, nlon)
    events_peak_bloom   = fill(NaN, ny, nlat, nlon)
    events_peak_intense = fill(NaN, ny, nlat, nlon)
    events_peak_extreme = fill(NaN, ny, nlat, nlon)
    events_total        = fill(NaN, ny, nlat, nlon)

    for j in 1:nlat, i in 1:nlon
        ts = view(chl3d, :, j, i)

        # valid fraction check
        valid = 0
        for t in 1:nt
            valid += ismissing(ts[t]) ? 0 : 1
        end
        if (grid_options.min_valid_points > 0 && valid < grid_options.min_valid_points) ||
            (valid / nt < grid_options.min_valid_fraction)
            continue
        end

        # thresholds + labels
        res = try
            fit_bloom(dates, ts; min_duration=bloom_options.min_duration, baseline_years=bloom_options.baseline_years)
        catch
            continue
        end

        # detect events using configured rule (Option A default: event_min_category=Likely)
        evs = try
            detect_events(dates, ts, res.labels;
                min_category = bloom_options.event_min_category,
                min_duration = bloom_options.min_duration,
                max_gap      = bloom_options.max_gap
            )
        catch
            continue
        end

        # mark computable: initialize all requested years to 0
        for k in 1:ny
            events_peak_likely[k,j,i]  = 0.0
            events_peak_bloom[k,j,i]   = 0.0
            events_peak_intense[k,j,i] = 0.0
            events_peak_extreme[k,j,i] = 0.0
            events_total[k,j,i]        = 0.0
        end

        # count events
        for ev in evs
            y = year(ev.start_date)
            k = get(y2i, y, 0)
            k == 0 && continue

            events_total[k,j,i] += 1

            pc = ev.peak_category
            if pc == Likely
                events_peak_likely[k,j,i] += 1
            elseif pc == Bloom
                events_peak_bloom[k,j,i] += 1
            elseif pc == Intense
                events_peak_intense[k,j,i] += 1
            elseif pc == Extreme
                events_peak_extreme[k,j,i] += 1
            end
        end
    end

    return (; years,
            events_peak_likely, events_peak_bloom, events_peak_intense, events_peak_extreme,
            events_total)
end
