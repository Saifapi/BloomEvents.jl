# Persistence filtering for boolean masks

\"\"\"
    persistence_filter(mask; min_duration=3) -> BitVector

Keep only runs of 	rue in mask that have length >= min_duration.
\"\"\"
function persistence_filter(mask::AbstractVector{Bool}; min_duration::Int=3)
    min_duration >= 1 || throw(ArgumentError(\"min_duration must be >= 1\"))
    out = falses(length(mask))
    n = length(mask)
    i = 1
    while i <= n
        if mask[i]
            j = i
            while j <= n && mask[j]
                j += 1
            end
            runlen = j - i
            if runlen >= min_duration
                out[i:j-1] .= true
            end
            i = j
        else
            i += 1
        end
    end
    return out
end
