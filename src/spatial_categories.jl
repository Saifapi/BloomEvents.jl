# Spatial category day-count stacks (year × lat × lon)

"""
    category_day_stack(dates, chl3d, years;
                       bloom_options=BloomOptions(),
                       grid_options=GridOptions())

Compute the number of days in each bloom category for every spatial grid
cell and requested year.

The input `chl3d` must have dimensions:

    chl3d[time, lat, lon]

The returned `NamedTuple` contains:
- `years`: requested years.
- `days_likely`: days classified as `Likely`.
- `days_bloom`: days classified as `Bloom`.
- `days_intense`: days classified as `Intense`.
- `days_extreme`: days classified as `Extreme`.

All category arrays have dimensions `year × lat × lon`.
`NoBloom` days are not returned.

Cells that do not satisfy the validity requirements remain `NaN`.
Computable cells are initialized to zero for requested years with no
days in a particular category.

The bloom classification uses the climatology and percentile thresholds
defined by `BloomOptions`, including `baseline_years` when provided.
"""
function category_day_stack(dates::AbstractVector{Date},
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

    # Precompute time indices for each requested year (saves work in pixel loop)
    y2i = Dict{Int,Int}(y => k for (k,y) in enumerate(years))
    idx_by_year = [Int[] for _ in 1:ny]
    for t in 1:nt
        y = year(dates[t])
        k = get(y2i, y, 0)
        k == 0 && continue
        push!(idx_by_year[k], t)
    end

    days_likely  = fill(NaN, ny, nlat, nlon)
    days_bloom   = fill(NaN, ny, nlat, nlon)
    days_intense = fill(NaN, ny, nlat, nlon)
    days_extreme = fill(NaN, ny, nlat, nlon)

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

        # We only need thresholds + labels, so fit_bloom is enough
        res = try
            fit_bloom(dates,ts; min_duration=bloom_options.min_duration, baseline_years=bloom_options.baseline_years)
        catch
            continue
        end
        labels = res.labels

        # mark computable pixel: initialize all requested years to 0
        for k in 1:ny
            days_likely[k, j, i]  = 0.0
            days_bloom[k, j, i]   = 0.0
            days_intense[k, j, i] = 0.0
            days_extreme[k, j, i] = 0.0
        end

        # count categories by year
        for k in 1:ny
            for t in idx_by_year[k]
                c = labels[t]
                if c == Likely
                    days_likely[k, j, i] += 1
                elseif c == Bloom
                    days_bloom[k, j, i] += 1
                elseif c == Intense
                    days_intense[k, j, i] += 1
                elseif c == Extreme
                    days_extreme[k, j, i] += 1
                end
            end
        end
    end

    return (; years, days_likely, days_bloom, days_intense, days_extreme)
end
