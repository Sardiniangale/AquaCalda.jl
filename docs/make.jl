using Documenter
using AcquaCalda

makedocs(
    sitename = "Acqua Calda",
    format = Documenter.HTML(
        canonical = "https://sardiniangale.github.io/AcquaCalda.jl/",
    ),
    pages = [
        "Home" => "index.md",
    ]
)

deploydocs(
    repo = "github.com/Sardiniangale/AcquaCalda.jl.git",
)
