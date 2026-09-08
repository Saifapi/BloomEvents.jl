module BloomEventsCairoMakieExt

using BloomEvents
using CairoMakie
using Dates

# -------------------------
# Helpers (module scope)
# -------------------------

_category_color(cat::BloomEvents.BloomCategory) = cat == BloomEvents.Likely  ? (0.2, 0.6, 1.0, 0.25) :
                                                 cat == BloomEvents.Bloom   ? (1.0, 0.7, 0.2, 0.25) :
                                                 cat == BloomEvents.Intense ? (1.0, 0.3, 0.2, 0.25) :
                                                 cat == BloomEvents.Extreme ? (0.6, 0.0, 0.0, 0.25) :
                                                                            (0, 0, 0, 0.0)

# Makie expects Z sized (length(x), length(y)) when given x,y.
# Our maps are (lat, lon), so convert to (lon, lat).
_to_lonlat(Z_latlon) = permutedims(Z_latlon, (2,1))

function _heatmap_latlon!(fig, pos, lon, lat, Z_latlon;
                          title="", units="", colormap=:viridis)
    ax = Axis(fig[pos...], title=title, xlabel="Longitude", ylabel="Latitude")
    hm = heatmap!(ax, lon, lat, _to_lonlat(Z_latlon); colormap=colormap)
    Colorbar(fig[pos[1], pos[2]+1], hm; label=units)
    return ax
end

# -------------------------
# Time series plot (index x-axis)
# -------------------------
function BloomEvents.plot_bloom_timeseries(dates::AbstractVector{Date},
                                           chl::AbstractVector,
                                           analysis::BloomEvents.BloomAnalysis;
                                           show_climatology::Bool=true,
                                           show_thresholds::Bool=true,
                                           title::AbstractString="Bloom events",
                                           xtick_stride::Int=10)

    n = length(dates)
    x = collect(1:n)

    res = analysis.result
    thr = res.thresholds

    fig = Figure(size=(1100, 420))
    ax = Axis(fig[1, 1], title=title, xlabel="Date", ylabel="Chl-a")

    y = Float64.(coalesce.(chl, NaN))
    lines!(ax, x, y; color=:black, linewidth=1.2, label="chl-a")

    if show_climatology
        lines!(ax, x, res.clim_at_dates; color=:green, linewidth=2, label="climatology")
    end

    for ev in analysis.events
        vspan!(ax, ev.start_idx, ev.end_idx; color=_category_color(ev.peak_category))
    end

    if show_thresholds
        hlines!(ax, [thr.q25, thr.q50, thr.q75, thr.q90];
                color=[:dodgerblue, :red, :darkgreen, :saddlebrown],
                linestyle=:dash)
    end

    stride = max(1, xtick_stride)
    tickpos = collect(1:stride:n)
    ticklab = Dates.format.(dates[tickpos], dateformat"yyyy-mm-dd")
    ax.xticks = (tickpos, ticklab)
    ax.xticklabelrotation = pi/6
    axislegend(ax; position=:rb)

    return fig
end

# -------------------------
# Annual bar panels (1D)
# -------------------------
function BloomEvents.plot_annual_panels(summaries::AbstractVector{BloomEvents.AnnualBloomSummary};
                                        title::AbstractString="Annual bloom metrics")
    tab = BloomEvents.annual_table(summaries)
    yrs = tab.years

    fig = Figure(size=(1100, 800))
    fig[0, :] = Label(fig, title, fontsize=18)

    function barpanel(pos, y, ylab, ttl)
        ax = Axis(fig[pos...], xlabel="Year", ylabel=ylab, title=ttl)
        barplot!(ax, yrs, y; color=:red)
        ax.xticks = (yrs, string.(yrs))
        return ax
    end

    barpanel((1,1), tab.frequency, "events", "Frequency")
    barpanel((1,2), tab.mean_duration, "days", "Mean Duration")
    barpanel((1,3), tab.mean_intensity, "mg m⁻³", "Mean Intensity")

    barpanel((2,1), tab.max_intensity, "mg m⁻³", "Max Intensity")
    barpanel((2,2), tab.cumulative_intensity, "mg m⁻³·days", "Cumulative Intensity")
    barpanel((2,3), tab.total_days, "days", "Total Days")

    barpanel((3,1), tab.mean_rate_onset, "intensity/day", "Rate of Onset")
    barpanel((3,2), tab.mean_rate_decline, "intensity/day", "Rate of Decline")

    return fig
end

# -------------------------
# Spatial metric panels from stacks (year×lat×lon)
# -------------------------
function _metric_year_map(stacks, metric::Symbol, yi::Int)
    A = getproperty(stacks, metric)         # (year, lat, lon)
    return @view A[yi, :, :]                # (lat, lon)
end

function BloomEvents.plot_spatial_panels_year(lat::AbstractVector,
                                              lon::AbstractVector,
                                              stacks;
                                              year::Int,
                                              title::AbstractString="Annual bloom metrics")
    yi = findfirst(==(year), stacks.years)
    yi === nothing && throw(ArgumentError("year $year not found in stacks.years"))

    metrics = (
        (:frequency,            "Frequency",            "events",        :viridis),
        (:total_days,           "Total Days",           "days",          :viridis),
        (:mean_duration,        "Mean Duration",        "days",          :viridis),
        (:mean_intensity,       "Mean Intensity",       "mg m⁻³",        :thermal),
        (:max_intensity,        "Max Intensity",        "mg m⁻³",        :thermal),
        (:cumulative_intensity, "Cumulative Intensity", "mg m⁻³·days",   :thermal),
        (:mean_rate_onset,      "Rate of Onset",        "intensity/day", :balance),
        (:mean_rate_decline,    "Rate of Decline",      "intensity/day", :balance),
    )

    fig = Figure(size=(1400, 900))
    fig[0, :] = Label(fig, "$title ($year)", fontsize=18)

    r = 1
    for k in 1:2:length(metrics)
        (m1,t1,u1,c1) = metrics[k]
        (m2,t2,u2,c2) = metrics[k+1]
        _heatmap_latlon!(fig, (r,1), lon, lat, _metric_year_map(stacks, m1, yi); title=t1, units=u1, colormap=c1)
        _heatmap_latlon!(fig, (r,3), lon, lat, _metric_year_map(stacks, m2, yi); title=t2, units=u2, colormap=c2)
        r += 1
    end
    return fig
end

function BloomEvents.plot_spatial_panels_mean(lat::AbstractVector,
                                              lon::AbstractVector,
                                              stacks;
                                              title::AbstractString="Mean bloom metrics")
    metrics = (
        (:frequency,            "Mean Frequency",            "events",        :viridis),
        (:total_days,           "Mean Total Days",           "days",          :viridis),
        (:mean_duration,        "Mean Duration",             "days",          :viridis),
        (:mean_intensity,       "Mean Intensity",            "mg m⁻³",        :thermal),
        (:max_intensity,        "Mean Max Intensity",        "mg m⁻³",        :thermal),
        (:cumulative_intensity, "Mean Cumulative Intensity", "mg m⁻³·days",   :thermal),
        (:mean_rate_onset,      "Mean Rate of Onset",        "intensity/day", :balance),
        (:mean_rate_decline,    "Mean Rate of Decline",      "intensity/day", :balance),
    )

    fig = Figure(size=(1400, 900))
    fig[0, :] = Label(fig, title, fontsize=18)

    r = 1
    for k in 1:2:length(metrics)
        (m1,t1,u1,c1) = metrics[k]
        (m2,t2,u2,c2) = metrics[k+1]
        Z1 = BloomEvents.mean_over_years(getproperty(stacks, m1))
        Z2 = BloomEvents.mean_over_years(getproperty(stacks, m2))
        _heatmap_latlon!(fig, (r,1), lon, lat, Z1; title=t1, units=u1, colormap=c1)
        _heatmap_latlon!(fig, (r,3), lon, lat, Z2; title=t2, units=u2, colormap=c2)
        r += 1
    end
    return fig
end

function BloomEvents.plot_spatial_panels_trend(lat::AbstractVector,
                                               lon::AbstractVector,
                                               stacks;
                                               min_points::Int=10,
                                               per_decade::Bool=true,
                                               title::AbstractString="Trend (linear slope)")
    yrs = stacks.years
    units = per_decade ? "per decade" : "per year"

    metrics = (
        (:frequency,            "Frequency Trend",            units, :balance),
        (:total_days,           "Total Days Trend",           units, :balance),
        (:mean_duration,        "Mean Duration Trend",        units, :balance),
        (:mean_intensity,       "Mean Intensity Trend",       units, :balance),
        (:max_intensity,        "Max Intensity Trend",        units, :balance),
        (:cumulative_intensity, "Cumulative Intensity Trend", units, :balance),
        (:mean_rate_onset,      "Rate of Onset Trend",        units, :balance),
        (:mean_rate_decline,    "Rate of Decline Trend",      units, :balance),
    )

    fig = Figure(size=(1400, 900))
    fig[0, :] = Label(fig, title, fontsize=18)

    r = 1
    for k in 1:2:length(metrics)
        (m1,t1,u1,c1) = metrics[k]
        (m2,t2,u2,c2) = metrics[k+1]
        Z1 = BloomEvents.linear_trend_map(getproperty(stacks, m1), yrs; min_points=min_points, per_decade=per_decade)
        Z2 = BloomEvents.linear_trend_map(getproperty(stacks, m2), yrs; min_points=min_points, per_decade=per_decade)
        _heatmap_latlon!(fig, (r,1), lon, lat, Z1; title=t1, units=u1, colormap=c1)
        _heatmap_latlon!(fig, (r,3), lon, lat, Z2; title=t2, units=u2, colormap=c2)
        r += 1
    end
    return fig
end

# -------------------------
# Category day-count panels (2×2)
# cats: years + days_likely/days_bloom/days_intense/days_extreme (year×lat×lon)
# -------------------------
function BloomEvents.plot_category_panels_year(lat::AbstractVector,
                                               lon::AbstractVector,
                                               cats;
                                               year::Int,
                                               title::AbstractString="Category days")
    yi = findfirst(==(year), cats.years)
    yi === nothing && throw(ArgumentError("year $year not found in cats.years"))

    ZL = @view cats.days_likely[yi, :, :]
    ZB = @view cats.days_bloom[yi, :, :]
    ZI = @view cats.days_intense[yi, :, :]
    ZE = @view cats.days_extreme[yi, :, :]

    fig = Figure(size=(1400, 750))
    fig[0, :] = Label(fig, "$title ($year)", fontsize=18)

    _heatmap_latlon!(fig, (1,1), lon, lat, ZL; title="Likely days", units="days")
    _heatmap_latlon!(fig, (1,3), lon, lat, ZB; title="Bloom days", units="days")
    _heatmap_latlon!(fig, (2,1), lon, lat, ZI; title="Intense days", units="days")
    _heatmap_latlon!(fig, (2,3), lon, lat, ZE; title="Extreme days", units="days")

    return fig
end

function BloomEvents.plot_category_panels_mean(lat::AbstractVector,
                                               lon::AbstractVector,
                                               cats;
                                               title::AbstractString="Mean category days")
    ZL = BloomEvents.mean_over_years(cats.days_likely)
    ZB = BloomEvents.mean_over_years(cats.days_bloom)
    ZI = BloomEvents.mean_over_years(cats.days_intense)
    ZE = BloomEvents.mean_over_years(cats.days_extreme)

    fig = Figure(size=(1400, 750))
    fig[0, :] = Label(fig, title, fontsize=18)

    _heatmap_latlon!(fig, (1,1), lon, lat, ZL; title="Mean Likely days", units="days")
    _heatmap_latlon!(fig, (1,3), lon, lat, ZB; title="Mean Bloom days", units="days")
    _heatmap_latlon!(fig, (2,1), lon, lat, ZI; title="Mean Intense days", units="days")
    _heatmap_latlon!(fig, (2,3), lon, lat, ZE; title="Mean Extreme days", units="days")

    return fig
end

function BloomEvents.plot_category_panels_trend(lat::AbstractVector,
                                                lon::AbstractVector,
                                                cats;
                                                min_points::Int=10,
                                                per_decade::Bool=true,
                                                title::AbstractString="Category days trend")
    yrs = cats.years
    units = per_decade ? "days/decade" : "days/year"

    ZL = BloomEvents.linear_trend_map(cats.days_likely,  yrs; min_points=min_points, per_decade=per_decade)
    ZB = BloomEvents.linear_trend_map(cats.days_bloom,   yrs; min_points=min_points, per_decade=per_decade)
    ZI = BloomEvents.linear_trend_map(cats.days_intense, yrs; min_points=min_points, per_decade=per_decade)
    ZE = BloomEvents.linear_trend_map(cats.days_extreme, yrs; min_points=min_points, per_decade=per_decade)

    fig = Figure(size=(1400, 750))
    fig[0, :] = Label(fig, title, fontsize=18)

    _heatmap_latlon!(fig, (1,1), lon, lat, ZL; title="Likely trend", units=units, colormap=:balance)
    _heatmap_latlon!(fig, (1,3), lon, lat, ZB; title="Bloom trend", units=units, colormap=:balance)
    _heatmap_latlon!(fig, (2,1), lon, lat, ZI; title="Intense trend", units=units, colormap=:balance)
    _heatmap_latlon!(fig, (2,3), lon, lat, ZE; title="Extreme trend", units=units, colormap=:balance)

    return fig
end

# -------------------------
# Peak-category event-frequency panels (2×2)
# peaks must contain:
# - years
# - events_peak_likely/events_peak_bloom/events_peak_intense/events_peak_extreme (year×lat×lon)
# -------------------------

function BloomEvents.plot_peak_event_panels_year(lat::AbstractVector,
                                                 lon::AbstractVector,
                                                 peaks;
                                                 year::Int,
                                                 title::AbstractString="Peak-category event frequency")

    yi = findfirst(==(year), peaks.years)
    yi === nothing && throw(ArgumentError("year $year not found in peaks.years"))

    ZL = @view peaks.events_peak_likely[yi, :, :]
    ZB = @view peaks.events_peak_bloom[yi, :, :]
    ZI = @view peaks.events_peak_intense[yi, :, :]
    ZE = @view peaks.events_peak_extreme[yi, :, :]

    fig = Figure(size=(1400, 750))
    fig[0, :] = Label(fig, "$title ($year)", fontsize=18)

    _heatmap_latlon!(fig, (1,1), lon, lat, ZL; title="Peak Likely events",  units="events")
    _heatmap_latlon!(fig, (1,3), lon, lat, ZB; title="Peak Bloom events",   units="events")
    _heatmap_latlon!(fig, (2,1), lon, lat, ZI; title="Peak Intense events", units="events")
    _heatmap_latlon!(fig, (2,3), lon, lat, ZE; title="Peak Extreme events", units="events")

    return fig
end

function BloomEvents.plot_peak_event_panels_mean(lat::AbstractVector,
                                                 lon::AbstractVector,
                                                 peaks;
                                                 title::AbstractString="Mean peak-category event frequency")

    ZL = BloomEvents.mean_over_years(peaks.events_peak_likely)
    ZB = BloomEvents.mean_over_years(peaks.events_peak_bloom)
    ZI = BloomEvents.mean_over_years(peaks.events_peak_intense)
    ZE = BloomEvents.mean_over_years(peaks.events_peak_extreme)

    fig = Figure(size=(1400, 750))
    fig[0, :] = Label(fig, title, fontsize=18)

    _heatmap_latlon!(fig, (1,1), lon, lat, ZL; title="Mean Peak Likely events",  units="events")
    _heatmap_latlon!(fig, (1,3), lon, lat, ZB; title="Mean Peak Bloom events",   units="events")
    _heatmap_latlon!(fig, (2,1), lon, lat, ZI; title="Mean Peak Intense events", units="events")
    _heatmap_latlon!(fig, (2,3), lon, lat, ZE; title="Mean Peak Extreme events", units="events")

    return fig
end

function BloomEvents.plot_peak_event_panels_trend(lat::AbstractVector,
                                                  lon::AbstractVector,
                                                  peaks;
                                                  min_points::Int=10,
                                                  per_decade::Bool=true,
                                                  title::AbstractString="Peak-category event frequency trend")

    yrs = peaks.years
    units = per_decade ? "events/decade" : "events/year"

    ZL = BloomEvents.linear_trend_map(peaks.events_peak_likely,  yrs; min_points=min_points, per_decade=per_decade)
    ZB = BloomEvents.linear_trend_map(peaks.events_peak_bloom,   yrs; min_points=min_points, per_decade=per_decade)
    ZI = BloomEvents.linear_trend_map(peaks.events_peak_intense, yrs; min_points=min_points, per_decade=per_decade)
    ZE = BloomEvents.linear_trend_map(peaks.events_peak_extreme, yrs; min_points=min_points, per_decade=per_decade)

    fig = Figure(size=(1400, 750))
    fig[0, :] = Label(fig, title, fontsize=18)

    _heatmap_latlon!(fig, (1,1), lon, lat, ZL; title="Likely trend",  units=units, colormap=:balance)
    _heatmap_latlon!(fig, (1,3), lon, lat, ZB; title="Bloom trend",   units=units, colormap=:balance)
    _heatmap_latlon!(fig, (2,1), lon, lat, ZI; title="Intense trend", units=units, colormap=:balance)
    _heatmap_latlon!(fig, (2,3), lon, lat, ZE; title="Extreme trend", units=units, colormap=:balance)

    return fig
end

end # module
