# Anomaly and anomaly masks

\"\"\"
    positive_anomaly_mask(chl, clim_at_dates) -> BitVector

Return a boolean mask where chl > climatology (strictly greater).
- missing chl => false
- NaN climatology => false
\"\"\"
function positive_anomaly_mask(chl::AbstractVector, clim_at_dates::AbstractVector{<:Real})
    length(chl) == length(clim_at_dates) || throw(ArgumentError(\"chl and clim_at_dates must have same length\"))
    mask = falses(length(chl))
    for i in eachindex(chl)
        x = chl[i]
        c = clim_at_dates[i]
        if ismissing(x) || isnan(c)
            mask[i] = false
        else
            mask[i] = Float64(x) > Float64(c)
        end
    end
    return mask
end

\"\"\"
    anomaly_series(chl, clim_at_dates) -> Vector{Union{Missing,Float64}}

Compute chl - climatology. Missing chl => missing. NaN climatology => missing.
\"\"\"
function anomaly_series(chl::AbstractVector, clim_at_dates::AbstractVector{<:Real})
    length(chl) == length(clim_at_dates) || throw(ArgumentError(\"chl and clim_at_dates must have same length\"))
    out = Vector{Union{Missing,Float64}}(undef, length(chl))
    for i in eachindex(chl)
        x = chl[i]
        c = clim_at_dates[i]
        if ismissing(x) || isnan(c)
            out[i] = missing
        else
            out[i] = Float64(x) - Float64(c)
        end
    end
    return out
end
