using Documenter
using BloomEvents
using NCDatasets
using CairoMakie

# Load the package extension modules explicitly for Documenter.
const BloomEventsNCDatasetsExt =
    Base.get_extension(BloomEvents, :BloomEventsNCDatasetsExt)

const BloomEventsCairoMakieExt =
    Base.get_extension(BloomEvents, :BloomEventsCairoMakieExt)

makedocs(
    sitename = "BloomEvents.jl",
    modules = [
        BloomEvents,
        BloomEventsNCDatasetsExt,
        BloomEventsCairoMakieExt,
    ],
    checkdocs = :exports,

    pages = [
        "Home" => "index.md",
        "Theory" => "theory.md",
        "API" => "api.md",
        "Examples" => "examples.md",
    ],
)

# Enable this later when you publish to GitHub Pages:
deploydocs(repo = "github.com/Saifapi/BloomEvents.jl.git")