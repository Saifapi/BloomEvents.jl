using Documenter
using BloomEvents

makedocs(
    sitename = "BloomEvents.jl",
    modules = [BloomEvents],

    pages = [
        "Home" => "index.md",
        "Theory" => "theory.md",
        "API" => "api.md",
        "Examples" => "examples.md",
    ],
)

# Enable this later when you publish to GitHub Pages:
deploydocs(repo = "github.com/Saifapi/BloomEvents.jl.git")