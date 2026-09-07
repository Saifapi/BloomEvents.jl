# Spatial category day-count stacks restricted to EVENT days (year × lat × lon)

"""
    category_event_day_stack(dates, chl3d, years; bloom_options=BloomOptions(), grid_options=GridOptions())

Compute day counts in each bloom category for each pixel and year, but ONLY for days
that belong to detected events (as defined by bloom_options).

Returns a NamedTuple:
- years
- event_days_likely, event_days_bloom, event_days_intense, event_days_extreme
(all shaped: year × lat × lon)

NaN policy:
- pixel not computable => NaN
- pixel computable but no events in a requested year => 0
"""
function category_event_day_stack(dates::AbstractVector{Date},
                                  chl3d::AbstractArray,
                                  years_in;
                                  bloom_options::BloomOptions = BloomOptions(),
                                  grid_options::GridOptions = GridOptions())

    size(chl3d, 1) == length(dates) || throw(ArgumentError("size(chl3d,1) must equal length(dates)"))
    nt = size(chl3d, 1)
    nlat = size(chl3d, 2)
    nlon = size(chl3d, 3)

    years = collect(Int.(years_in))
    ny = length(years)
    ny > 0 || throw(ArgumentError("years must be non-empty"))

    # precompute time indices for each requested year
    y2i = Dict{Int,Int}(y => k for (k,y) in enumerate(years))
    idx_by_year = [Int[] for _ in 1:ny]
    for t in 1:nt
        y = year(dates[t])
        k = get(y2i, y, 0)
        k == 0 && continue
        push!(idx_by_year[k], t)
    end

    event_days_likely  = fill(NaN, ny, nlat, nlon)
    event_days_bloom   = fill(NaN, ny, nlat, nlon)
    event_days_intense = fill(NaN, ny, nlat, nlon)
    event_days_extreme = fill(NaN, ny, nlat, nlon)

    for j in 1:nlat, i in 1:nlon
        ts = view(chl3d, :, j, i)

        # valid fraction check
        valid = 0
        for t in 1:nt
            valid += ismissing(ts[t]) ? 0 : 1
        end
        if valid / nt < grid_options.min_valid_fraction
            continue
        end

        # Compute thresholds + labels
        res = try
            fit_bloom(dates, ts; min_duration=bloom_options.min_duration)
        catch
            continue
        end
        labels = res.labels

        # Detect events using the SAME event rules as your main pipeline
        evs = try
            detect_events(dates, ts, labels;
                min_category = bloom_options.event_min_category,
                min_duration = bloom_options.min_duration,
                max_gap      = bloom_options.max_gap
            )
        catch
            continue
        end

        # Build an event mask for time indices
        eventmask = falses(nt)
        for ev in evs
            eventmask[ev.start_idx:ev.end_idx] .= true
        end

        # mark computable pixel: initialize to 0 for all requested years
        for k in 1:ny
            event_days_likely[k, j, i]  = 0.0
            event_days_bloom[k, j, i]   = 0.0
            event_days_intense[k, j, i] = 0.0
            event_days_extreme[k, j, i] = 0.0
        end

        # count categories by year but only if eventmask[t] is true
        for k in 1:ny
            for t in idx_by_year[k]
                eventmask[t] || continue
                c = labels[t]
                if c == Likely
                    event_days_likely[k, j, i] += 1
                elseif c == Bloom
                    event_days_bloom[k, j, i] += 1
                elseif c == Intense
                    event_days_intense[k, j, i] += 1
                elseif c == Extreme
                    event_days_extreme[k, j, i] += 1
                end
            end
        end
    end

    return (; years, event_days_likely, event_days_bloom, event_days_intense, event_days_extreme)
end
