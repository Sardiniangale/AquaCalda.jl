# cell-list O(N) neighbor search, placeholder, not yet implemented

struct CellList{T} <: AbstractNeighborSearch
    bounds::SVector{3,T}
    cell_size::T
end

CellList(; bounds=SA[1.0, 1.0, 1.0], cell_size=0.01) =
    CellList(bounds, Float64(cell_size))

function update!(system, ::CellList)
    error("CellList not yet implemented , use BruteForce")
end
