# core domain types, particle, wall, contact, system

using StaticArrays

# particle with mechanical and thermal state
mutable struct Particle
    id::Int
    position::SVector{3, Float64}
    velocity::SVector{3, Float64}
    angular_velocity::SVector{3, Float64}
    force::SVector{3, Float64}
    torque::SVector{3, Float64}
    radius::Float64
    mass::Float64
    moment_of_inertia::Float64
    temperature::Float64
    heat_capacity::Float64
    conductivity::Float64
end

# infinite plane
struct Wall
    normal::SVector{3, Float64}
    point::SVector{3, Float64}
end

# a detected overlap between two bodies (i = particle index, j = particle index or 0 for wall)
mutable struct Contact
    i::Int
    j::Int
    overlap::Float64
    normal::SVector{3, Float64}
    contact_point::SVector{3, Float64}
    branch_i::SVector{3, Float64}
    tangential_displacement::SVector{3, Float64}
end

# the simulation container
mutable struct System{CM <: AbstractContactModel, TM <: AbstractThermalModel,
    I <: AbstractIntegrator, NS <: AbstractNeighborSearch}
    particles::Vector{Particle}
    walls::Vector{Wall}
    contacts::Vector{Contact}
    contact_model::CM
    thermal_model::TM
    integrator::I
    neighbor_search::NS
    gravity::Float64
    dt::Float64
    time::Float64
end
