using Documenter

makedocs(
    sitename = "Acqua Calda",
    format = Documenter.HTML(
        canonical = "https://github.com/AcquaCalda/AcquaCalda.jl/",
    ),
    pages = [
        "Home" => "index.md",
    ],
)

deploydocs(
    repo = "github.com/AcquaCalda/AcquaCalda.jl.git",
)
