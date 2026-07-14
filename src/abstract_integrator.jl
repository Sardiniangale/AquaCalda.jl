# time integrator interface

abstract type AbstractIntegrator end

"""
    step!(system, integrator, dt)

update particle positions, velocities, and angular velocities for one timestep.
forces must be computed before calling this.
"""
function step!(system, integrator::AbstractIntegrator, dt::Float64)
    error("step! not implemented for $(typeof(integrator))")
end
