module AcquaCalda

using LinearAlgebra
using StaticArrays

#extremely basic implimentation

# abstract interfaces
include("abstract_contact.jl")
include("abstract_integrator.jl")
include("abstract_neighbor.jl")
include("abstract_thermal.jl")

# core types
include("types.jl")

# contact model implementations
include("contact_linear.jl")
include("contact_hertz.jl")

# integrator implementations
include("integrator_verlet.jl")

# neighbor search implementations
include("neighbor_brute.jl")
include("neighbor_cell.jl")

# thermal model implementations
include("thermal_fourier.jl")

# callbacks
include("callbacks.jl")

# simulation loop
include("system.jl")

# exports , types
export Particle, Wall, Contact, System

# exports , abstract interfaces (for user extensions)
export AbstractContactModel, AbstractIntegrator
export AbstractNeighborSearch, AbstractThermalModel

# exports , contact models
export LinearSpringDashpot, HertzMindlin

# exports , integrators
export VelocityVerlet

# exports , neighbor search
export BruteForce, CellList

# exports , thermal models
export FourierContact

# exports , simulation
export run!, reset_forces!, apply_gravity!, compute_forces!, compute_thermal!

# exports , callbacks
export Callback, every

# exports , velocity verlet helpers
export step!, finish_step!

end # module AcquaCalda
