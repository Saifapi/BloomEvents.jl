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
