module BloomEvents

using Dates
using Statistics

include("types.jl")
include("utils.jl")
include("climatology.jl")
include("anomalies.jl")
include("persistence.jl")
include("thresholds.jl")
include("detection.jl")
include("metrics.jl")
include("annual.jl")
include("export.jl")
include("spatial.jl")
include("spatial_stack.jl")
include("spatial_trends.jl")
include("io_api.jl")
include("plotting_api.jl")
include("spatial_categories.jl")
include("spatial_categories_events.jl")
include("spatial_peak_events.jl")



export BloomThresholds, BloomEvent, BloomResult, BloomAnalysis, BloomOptions
export BloomCategory
export BloomEventMetrics
export AnnualBloomSummary
export GridOptions

export doy365, daily_climatology_mean, climatology_at_dates
export positive_anomaly_mask, anomaly_series
export persistence_filter
export quantile_sorted, bloom_thresholds_from_subset
export label_days, fit_bloom
export event_day_mask, fill_short_gaps, detect_events
export analyze_bloom

export event_intensity, compute_event_metrics
export annual_summaries, annual_table

export write_events_csv, write_annual_csv

export annual_metric_maps
export annual_metric_stack

export nanmean, mean_over_years, linear_trend_map

export plot_bloom_timeseries, plot_annual_panels

export load_chl_cube_netcdf, write_metric_stack_netcdf
export plot_spatial_panels_year, plot_spatial_panels_mean, plot_spatial_panels_trend

export category_day_stack
export write_category_stack_netcdf
export plot_category_panels_year, plot_category_panels_mean, plot_category_panels_trend
export category_event_day_stack
export event_peak_category_stack

end # module BloomEvents
