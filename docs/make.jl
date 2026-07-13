using Documenter
using AcquaCalda

makedocs(
    sitename = "Acqua Calda",
    format = Documenter.HTML(
        canonical = "https://acquacalda.github.io/AcquaCalda.jl/",
    ),
    pages = [
        "Home" => "index.md",
    ]
)

deploydocs(
    repo = "github.com/AcquaCalda/AcquaCalda.jl.git",
)
