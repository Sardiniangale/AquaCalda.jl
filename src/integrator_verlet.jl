# velocity verlet integrator , symplectic, second-order accurate

struct VelocityVerlet <: AbstractIntegrator end

function step!(system, ::VelocityVerlet, dt::Float64)
    particles = system.particles
    n = length(particles)

    # half-step velocity + full-step position
    @inbounds for i in 1:n
        p = particles[i]
        a = p.force / p.mass
        p.velocity += 0.5 * a * dt
        p.position += p.velocity * dt
    end

    # angular velocity half-step
    @inbounds for i in 1:n
        p = particles[i]
        alpha = p.torque / p.moment_of_inertia
        p.angular_velocity += 0.5 * alpha * dt
    end
    # note: angular position is not tracked (sphere, only velocity matters for friction)

    # forces must be recomputed by the caller after position update
    # then the second half-step is applied:
    # p.velocity += 0.5 * (new_force / p.mass) * dt
    # this is done by calling finish_step! after force recomputation
end

function finish_step!(system, dt::Float64)
    particles = system.particles
    @inbounds for i in eachindex(particles)
        p = particles[i]
        a = p.force / p.mass
        p.velocity += 0.5 * a * dt
        alpha = p.torque / p.moment_of_inertia
        p.angular_velocity += 0.5 * alpha * dt
    end
end
