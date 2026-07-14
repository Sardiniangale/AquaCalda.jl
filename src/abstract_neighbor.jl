# neighbor search interface

abstract type AbstractNeighborSearch end

"""
    update!(system, neighbor_search)

rebuild the neighbor list and populate `system.contacts` with all
particle-particle and particle-wall overlaps found this timestep.
"""
function update!(system, ns::AbstractNeighborSearch)
    error("update! not implemented for $(typeof(ns))")
end
