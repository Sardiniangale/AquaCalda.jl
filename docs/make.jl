using Documenter
using AcquaCalda

makedocs(
    sitename = "Acqua Calda",
    format = Documenter.HTML(
        canonical = "https://sardiniangale.github.io/AcquaCalda.jl/",
    ),
    pages = [
        "Home" => "index.md",
        "INTERNAL_DOC" => "internal_docs.md"
        "Installation" => "installation.md",
        "Quick Start" => "quickstart.md",
        "Physics" => "physics.md",
        "API Reference" => "api.md",
        "Extensions" => "extensions.md",
        "Citation" => "citation.md"
    ]
)

deploydocs(
    repo = "github.com/Sardiniangale/AquaCalda.jl.git",
)
