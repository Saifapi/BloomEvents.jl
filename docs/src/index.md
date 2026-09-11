# BloomEvents.jl

BloomEvents.jl detects phytoplankton bloom conditions from chlorophyll-a time series and gridded products using a percentile-threshold workflow inspired by:

Raulo, S. et al. (2025) *Determining chlorophyll-a thresholds for characterizing algal bloom conditions: An ocean colour remote sensing approach*.

## Features

- Daily climatology
- Positive anomaly selection + persistence (default 3 days)
- Percentile thresholds: Q25/Q50/Q75/Q90
- Daily categories: Likely, Bloom, Intense, Extreme
- Event detection + metrics
- Annual summaries
- Spatial stacks + mean/trend maps
- Optional extensions:
  - CairoMakie plotting
  - NCDatasets IO and NetCDF export

