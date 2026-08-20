module BloomEventsCairoMakieExt

using BloomEvents
using CairoMakie
using Dates

# Simple color map for categories
_category_color(cat::BloomEvents.BloomCategory) = cat == BloomEvents.Likely  ? (0.2, 0.6, 1.0, 0.25) :
                                                 cat == BloomEvents.Bloom   ? (1.0, 0.7, 0.2, 0.25) :
                                                 cat == BloomEvents.Intense ? (1.0, 0.3, 0.2, 0.25) :
                                                 cat == BloomEvents.Extreme ? (0.6, 0.0, 0.0, 0.25) :
                                                                            (0, 0, 0, 0.0)

"""
Plot chl-a time series with climatology, thresholds, and shaded bloom events.

Note: uses x = 1:N (index axis) and formats date labels on x ticks.
"""
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

    # plot data first
    lines!(ax, x, y; color=:black, linewidth=1.2, label="chl-a")

    if show_climatology
        lines!(ax, x, res.clim_at_dates; color=:green, linewidth=2, label="climatology")
    end

    # shade events using index ranges
    for ev in analysis.events
        c = _category_color(ev.peak_category)
        vspan!(ax, ev.start_idx, ev.end_idx; color=c)
    end

    if show_thresholds
        hlines!(ax, [thr.q25, thr.q50, thr.q75, thr.q90];
                color=[:dodgerblue, :red, :darkgreen, :saddlebrown],
                linestyle=:dash)
    end

    # format x ticks as dates
    stride = max(1, xtick_stride)
    tickpos = collect(1:stride:n)
    ticklab = Dates.format.(dates[tickpos], dateformat"yyyy-mm-dd")
    ax.xticks = (tickpos, ticklab)
    ax.xticklabelrotation = pi/6

    axislegend(ax; position=:rb)
    return fig
end

"""
Plot annual summary panels (frequency, duration, intensity, total days, onset/decline).
"""
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

end # module

# -------------------------
# Spatial panel plots (lon/lat heatmaps)
# -------------------------

function _metric_map_from_stacks(stacks, metric::Symbol, year_index::Int)
    A = getproperty(stacks, metric)           # (year, lat, lon)
    return @view A[year_index, :, :]          # (lat, lon)
end

function _panel_heatmap!(fig, pos, lon, lat, Z; title="", units="", colormap=:thermal)
    ax = Axis(fig[pos...], title=title, xlabel="Longitude", ylabel="Latitude")
    hm = heatmap!(ax, lon, lat, Z; colormap=colormap)
    Colorbar(fig[pos[1], pos[2]+1], hm, label=units)
    return ax
end

"""
    plot_spatial_panels_year(lat, lon, stacks; year=YYYY)

Plot 8 spatial metrics for a chosen year from stacks (year×lat×lon).
"""
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

    # 4 rows × (2 plot columns + 2 colorbar columns)
    r = 1
    for k in 1:2:length(metrics)
        (m1, t1, u1, c1) = metrics[k]
        (m2, t2, u2, c2) = metrics[k+1]

        Z1 = _metric_map_from_stacks(stacks, m1, yi)
        Z2 = _metric_map_from_stacks(stacks, m2, yi)

        _panel_heatmap!(fig, (r,1), lon, lat, Z1; title=t1, units=u1, colormap=c1)
        _panel_heatmap!(fig, (r,3), lon, lat, Z2; title=t2, units=u2, colormap=c2)

        r += 1
    end

    return fig
end

"""
    plot_spatial_panels_mean(lat, lon, stacks)

Mean across years (ignoring NaNs) for each metric.
Uses BloomEvents.mean_over_years(stack).
"""
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
        (m1, t1, u1, c1) = metrics[k]
        (m2, t2, u2, c2) = metrics[k+1]

        Z1 = BloomEvents.mean_over_years(getproperty(stacks, m1))
        Z2 = BloomEvents.mean_over_years(getproperty(stacks, m2))

        _panel_heatmap!(fig, (r,1), lon, lat, Z1; title=t1, units=u1, colormap=c1)
        _panel_heatmap!(fig, (r,3), lon, lat, Z2; title=t2, units=u2, colormap=c2)

        r += 1
    end

    return fig
end

"""
    plot_spatial_panels_trend(lat, lon, stacks; min_points=10, per_decade=true)

Linear trend per pixel for each metric using BloomEvents.linear_trend_map.
"""
function BloomEvents.plot_spatial_panels_trend(lat::AbstractVector,
                                               lon::AbstractVector,
                                               stacks;
                                               min_points::Int=10,
                                               per_decade::Bool=true,
                                               title::AbstractString="Trend (linear slope)")

    yrs = stacks.years

    metrics = (
        (:frequency,            "Frequency Trend",            "events/decade", :balance),
        (:total_days,           "Total Days Trend",           "days/decade",   :balance),
        (:mean_duration,        "Mean Duration Trend",        "days/decade",   :balance),
        (:mean_intensity,       "Mean Intensity Trend",       "mg m⁻³/decade", :balance),
        (:max_intensity,        "Max Intensity Trend",        "mg m⁻³/decade", :balance),
        (:cumulative_intensity, "Cumulative Intensity Trend", "mg m⁻³·days/decade", :balance),
        (:mean_rate_onset,      "Rate of Onset Trend",        "(int/day)/decade", :balance),
        (:mean_rate_decline,    "Rate of Decline Trend",      "(int/day)/decade", :balance),
    )

    fig = Figure(size=(1400, 900))
    fig[0, :] = Label(fig, title, fontsize=18)

    r = 1
    for k in 1:2:length(metrics)
        (m1, t1, u1, c1) = metrics[k]
        (m2, t2, u2, c2) = metrics[k+1]

        Z1 = BloomEvents.linear_trend_map(getproperty(stacks, m1), yrs; min_points=min_points, per_decade=per_decade)
        Z2 = BloomEvents.linear_trend_map(getproperty(stacks, m2), yrs; min_points=min_points, per_decade=per_decade)

        _panel_heatmap!(fig, (r,1), lon, lat, Z1; title=t1, units=u1, colormap=c1)
        _panel_heatmap!(fig, (r,3), lon, lat, Z2; title=t2, units=u2, colormap=c2)

        r += 1
    end

    return fig
end
