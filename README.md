# BloomEvents.jl

[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://saifapi.github.io/BloomEvents.jl/)

**BloomEvents.jl** is a Julia package for detecting and analyzing phytoplankton bloom conditions from chlorophyll-a time series and gridded ocean-colour products using a percentile-threshold approach.

The workflow is inspired by the chlorophyll-a threshold methodology of Raulo et al. (2025), with persistence-based event detection and spatial analysis capabilities.

## Features

* Daily chlorophyll-a climatology
* Positive anomaly selection
* Persistence-based bloom detection
* Percentile thresholds:

  * Q25 — Likely
  * Q50 — Bloom
  * Q75 — Intense
  * Q90 — Extreme
* Bloom event detection and metrics
* Annual bloom summaries
* Spatial bloom metric stacks
* Spatial mean and trend analysis
* Data-quality and missing-data checks
* CSV export of events and annual summaries
* NetCDF input and output
* Optional CairoMakie-based visualization

## Scientific approach

BloomEvents.jl uses daily climatological chlorophyll-a distributions to characterize elevated chlorophyll-a conditions.

The percentile thresholds are used to classify daily conditions into four categories:

| Category | Threshold |
| -------- | --------- |
| Likely   | Q25–Q50   |
| Bloom    | Q50–Q75   |
| Intense  | Q75–Q90   |
| Extreme  | ≥ Q90     |

Bloom events are identified using a persistence criterion. The example workflows use a **3-day minimum duration**, allowing short-lived chlorophyll-a excursions to be distinguished from persistent bloom conditions.

For the scientific background and detailed methodology, see the [theory documentation](https://saifapi.github.io/BloomEvents.jl/theory/).

## Installation

BloomEvents.jl can be installed using Julia's package manager:

```julia
using Pkg
Pkg.add("BloomEvents")
```

Then load the package with:

```julia
using BloomEvents
```

## Quick start

The basic workflow operates on a chlorophyll-a time series and corresponding dates.

```julia
using BloomEvents
using Dates

dates = collect(Date(2021, 1, 1):Day(1):Date(2022, 12, 31))

chl = vcat(
    fill(1.0, 365),
    fill(1.0, 200),
    fill(3.0, 10),
    fill(1.2, 155)
)

options = BloomOptions(
    min_duration = 3,
    max_gap = 0,
    event_min_category = BloomEvents.Likely
)

analysis = analyze_bloom(dates, chl; options=options)

println("Events detected: ", length(analysis.events))
println("Missing fraction: ", missing_fraction(chl))
```

Thresholds can be inspected from the resulting analysis:

```julia
analysis.result.thresholds.q25
analysis.result.thresholds.q50
analysis.result.thresholds.q75
analysis.result.thresholds.q90
```

Annual summaries and event tables can also be generated:

```julia
summaries = annual_summaries(analysis, chl)

write_events_csv("events.csv", analysis.events)
write_annual_csv("annual.csv", summaries)
```

The complete validation example is available in:

```text
examples/validate_hotspot_1d.jl
```

## Spatial analysis

BloomEvents.jl also supports gridded chlorophyll-a data stored in NetCDF format.

A typical workflow is:

```julia
using BloomEvents
using NCDatasets
using Dates

dates, chl3d, lat, lon = load_chl_cube_netcdf(
    ["chlorophyll.nc"];
    varname = "CHL",
    timename = "time",
    latname = "latitude",
    lonname = "longitude",
    start_date = Date(2003, 1, 1),
    end_date = Date(2023, 12, 31),
    lat_range = (16.0, 23.0),
    lon_range = (80.0, 95.0)
)

years = 2021:2023

bloom_options = BloomOptions(
    min_duration = 3,
    max_gap = 0,
    event_min_category = BloomEvents.Likely
)

grid_options = GridOptions(
    min_valid_fraction = 0.3,
    threads = true
)

stacks = annual_metric_stack(
    dates,
    chl3d,
    years;
    bloom_options = bloom_options,
    grid_options = grid_options
)
```

The resulting spatial metric stacks can be exported to NetCDF:

```julia
write_metric_stack_netcdf(
    "spatial_metric_stacks.nc",
    lat,
    lon,
    stacks
)
```

Spatial annual and mean products can also be visualized when the CairoMakie extension is available:

```julia
fig = plot_spatial_panels_year(
    lat,
    lon,
    stacks;
    year = 2023,
    title = "Annual bloom metrics"
)
```

The complete spatial validation workflow is available in:

```text
examples/validate_spatial_stacks.jl
```

## Examples

The `examples/` directory contains workflows covering:

* 1D hotspot validation
* Spatial metric stacks
* NetCDF metric-stack export
* Bloom-category spatial products
* Peak-event category products
* Time-series and annual plots
* Spatial annual, mean, and trend plots
* Persistence-rule validation
* NetCDF-based spatial processing

See the [Examples documentation](https://saifapi.github.io/BloomEvents.jl/examples/).

## Optional dependencies

BloomEvents.jl keeps plotting and NetCDF functionality as optional extensions.

### CairoMakie

[CairoMakie](https://docs.makie.org/) enables plotting functionality such as bloom time series, annual panels, and spatial maps.

```julia
using Pkg
Pkg.add("CairoMakie")
```

### NCDatasets

[NCDatasets.jl](https://github.com/Alexander-Barth/NCDatasets.jl) enables NetCDF input/output functionality.

```julia
using Pkg
Pkg.add("NCDatasets")
```

These packages are not required for the core time-series analysis functionality.

## Documentation

Full documentation is available at:

https://saifapi.github.io/BloomEvents.jl/

The documentation includes:

* [Theory](https://saifapi.github.io/BloomEvents.jl/theory/)
* [API reference](https://saifapi.github.io/BloomEvents.jl/api/)
* [Examples](https://saifapi.github.io/BloomEvents.jl/examples/)

## Scientific reference

The percentile-threshold approach is inspired by:

> Raulo, S. et al. (2025). *Determining chlorophyll-a thresholds for characterizing algal bloom conditions: An ocean colour remote sensing approach.*

## License

See the repository for the applicable license.
