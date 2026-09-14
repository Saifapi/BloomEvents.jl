# Spatial / gridded workflows (core, no IO)

"""
    GridOptions(; min_valid_fraction=0.3, min_valid_points=0, threads=false)

Options controlling gridded bloom analysis.

- `min_valid_fraction`: minimum fraction of non-missing observations required
  for a grid cell to be analyzed.
- `min_valid_points`: minimum number of valid observations required for a
  grid cell. A value of `0` disables this criterion.
- `threads`: whether threaded computation may be enabled for gridded
  processing.
"""
Base.@kwdef struct GridOptions
    min_valid_fraction::Float64 = 0.3
    min_valid_points::Int = 0
    threads::Bool = false
end

"""
    annual_metric_maps(dates, chl3d, year;
                       bloom_options=BloomOptions(),
                       grid_options=GridOptions())

Compute annual bloom metrics for a single year at every spatial grid cell.

The input `chl3d` must have dimensions:

    chl3d[time, lat, lon]

For each grid cell, the function applies the bloom detection workflow and
computes annual frequency, total bloom days, mean duration, intensity,
cumulative intensity, and onset/decline rates.

Returns a `NamedTuple` containing 2D `Float64` arrays with dimensions
`lat × lon`.

Grid cells that do not meet the validity requirements remain `NaN`.
For computable cells with no events in the requested year, `frequency`
and `total_days` are `0`, while the remaining event metrics are `NaN`.

The validity requirements are controlled by `GridOptions`.
"""
function annual_metric_maps(dates::AbstractVector{Date},
                            chl3d::AbstractArray,
                            year::Int;
                            bloom_options::BloomOptions = BloomOptions(),
                            grid_options::GridOptions = GridOptions())
    if bloom_options.check_dates
        check_daily(dates; strict=bloom_options.strict_daily)
    end
    size(chl3d, 1) == length(dates) || throw(ArgumentError("size(chl3d,1) must equal length(dates)"))
    nt = size(chl3d, 1)
    ny = size(chl3d, 2)
    nx = size(chl3d, 3)

    # output maps (Float64 + NaN)
    frequency = fill(NaN, ny, nx)
    total_days = fill(NaN, ny, nx)
    mean_duration = fill(NaN, ny, nx)

    mean_intensity = fill(NaN, ny, nx)
    max_intensity = fill(NaN, ny, nx)
    cumulative_intensity = fill(NaN, ny, nx)

    mean_rate_onset = fill(NaN, ny, nx)
    mean_rate_decline = fill(NaN, ny, nx)

    # helper to assign “no events this year”
    function _set_noevents!(j, i)
        frequency[j,i] = 0.0
        total_days[j,i] = 0.0
        # leave others as NaN
    end

    # pixel loop
    for j in 1:ny, i in 1:nx
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

        # analyze bloom; protect against pixels with no persistent anomalies
        analysis = try
            analyze_bloom(dates, ts; options=bloom_options)
        catch
            continue
        end

        sums = try
            annual_summaries(analysis, ts)
        catch
            continue
        end

        # find requested year summary
        s = nothing
        for ss in sums
            if ss.year == year
                s = ss
                break
            end
        end

        if s === nothing
            _set_noevents!(j, i)
            continue
        end

        frequency[j,i] = float(s.frequency)
        total_days[j,i] = float(s.total_days)
        mean_duration[j,i] = s.mean_duration

        mean_intensity[j,i] = s.mean_intensity
        max_intensity[j,i] = s.max_intensity
        cumulative_intensity[j,i] = s.cumulative_intensity

        mean_rate_onset[j,i] = s.mean_rate_onset
        mean_rate_decline[j,i] = s.mean_rate_decline
    end

    return (;
        frequency,
        total_days,
        mean_duration,
        mean_intensity,
        max_intensity,
        cumulative_intensity,
        mean_rate_onset,
        mean_rate_decline
    )
end
