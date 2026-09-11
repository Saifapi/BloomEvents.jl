# Theory

## Workflow (Raulo et al. style)

1. Compute daily climatology (365-day)
2. Identify positive anomalies: `chl > climatology`
3. Apply persistence filter (default: 3 consecutive days)
4. Compute thresholds from persistent-anomaly subset:
   - Q25, Q50, Q75, Q90
5. Classify each day:
   - Likely:  Q25 ≤ chl < Q50
   - Bloom:   Q50 ≤ chl < Q75
   - Intense: Q75 ≤ chl < Q90
   - Extreme: chl ≥ Q90
6. Detect events from consecutive categorized days (configurable min category, duration, gaps)

## Notes

- Leap day handling: Feb-29 is mapped to the Feb-28 index in 365-day climatology.
- Intensity is defined as `chl - climatology_at_date`.
