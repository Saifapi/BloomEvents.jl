# Spatial annual metric stacks (year × lat × lon)

"""
    annual_metric_stack(dates, chl3d, years; bloom_options=BloomOptions(), grid_options=GridOptions())

Compute annual bloom metric stacks for multiple years from a chl cube shaped:
    chl3d[time, lat, lon]

Returns a NamedTuple:
- years::Vector{Int}
- stacks for each metric: Array{Float64,3} with size (nyears, nlat, nlon)

Policy:
- If pixel is NOT computable (insufficient valid data or threshold failure): all metrics remain NaN
- If pixel is computable but has NO events in a given year:
    frequency = 0, total_days = 0
    other metrics remain NaN (mean_duration, intensities, rates)
"""
function annual_metric_stack(dates::AbstractVector{Date},
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

    # allocate stacks (nyears × nlat × nlon)
    frequency = fill(NaN, ny, nlat, nlon)
    total_days = fill(NaN, ny, nlat, nlon)
    mean_duration = fill(NaN, ny, nlat, nlon)

    mean_intensity = fill(NaN, ny, nlat, nlon)
    max_intensity = fill(NaN, ny, nlat, nlon)
    cumulative_intensity = fill(NaN, ny, nlat, nlon)

    mean_rate_onset = fill(NaN, ny, nlat, nlon)
    mean_rate_decline = fill(NaN, ny, nlat, nlon)

    # pixel loop (serial for now; we add threading later)
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

        # compute analysis for this pixel
        analysis = try
            analyze_bloom(dates, ts; options=bloom_options)
        catch
            continue
        end

        # compute annual summaries (only years with events appear)
        sums = try
            annual_summaries(analysis, ts)
        catch
            continue
        end

        # mark computable pixel: set freq/total_days to 0 for all requested years
        for yi in 1:ny
            frequency[yi, j, i] = 0.0
            total_days[yi, j, i] = 0.0
        end

        # fill years that exist in summary
        for s in sums
            y = s.year
            yi = findfirst(==(y), years)
            yi === nothing && continue

            frequency[yi, j, i] = float(s.frequency)
            total_days[yi, j, i] = float(s.total_days)
            mean_duration[yi, j, i] = s.mean_duration

            mean_intensity[yi, j, i] = s.mean_intensity
            max_intensity[yi, j, i] = s.max_intensity
            cumulative_intensity[yi, j, i] = s.cumulative_intensity

            mean_rate_onset[yi, j, i] = s.mean_rate_onset
            mean_rate_decline[yi, j, i] = s.mean_rate_decline
        end
    end

    return (;
        years,
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
