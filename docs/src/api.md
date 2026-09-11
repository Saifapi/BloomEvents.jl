# API

This page documents the main public types and functions of **BloomEvents.jl**.

Optional methods become available after loading their corresponding dependency:

* `using NCDatasets` enables NetCDF I/O and export.
* `using CairoMakie` enables plotting.

---

## Types

```@docs
BloomCategory
BloomOptions
BloomThresholds
BloomEvent
BloomEventMetrics
AnnualBloomSummary
BloomResult
BloomAnalysis
```

---

## Climatology and thresholds

```@docs
doy365
daily_climatology_mean
climatology_at_dates
bloom_thresholds_from_subset
quantile_sorted
```

---

## Bloom detection

```@docs
positive_anomaly_mask
label_days
persistence_filter
fill_short_gaps
detect_events
event_day_mask
event_intensity
fit_bloom
analyze_bloom
```

---

## Event and annual metrics

```@docs
compute_event_metrics
annual_summaries
annual_table
```

---

## Spatial and temporal analysis

```@docs
category_day_stack
category_event_day_stack
event_peak_category_stack
annual_metric_stack
annual_metric_maps
mean_over_years
linear_trend_map
anomaly_series
```

---

## Data quality and date utilities

```@docs
is_sorted_dates
daily_gaps
check_daily
missing_fraction
valid_fraction
count_valid_pixels
fraction_valid_pixels
nanmean
```

---

## Output

```@docs
write_events_csv
write_annual_csv
```

---

## Optional NetCDF I/O

NetCDF input/output methods are provided through the optional `NCDatasets` dependency.

They will be documented separately when the extension documentation is configured.
