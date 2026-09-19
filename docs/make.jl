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

release_tag = get(ENV, "BLOOMEVENTS_DOC_TAG", "")

if isempty(release_tag)
    deploydocs(
        repo = "github.com/Saifapi/BloomEvents.jl.git",
        devbranch = "main",
    )
else
    deploy_config = Documenter.GitHubActions(
        "Saifapi/BloomEvents.jl",
        "push",
        "refs/tags/$(release_tag)",
    )

    deploydocs(
        repo = "github.com/Saifapi/BloomEvents.jl.git",
        devbranch = "main",
        deploy_config = deploy_config,
    )
end
