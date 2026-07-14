# main simulation loop and force accumulation

function reset_forces!(particles::Vector{Particle})
    @inbounds for p in particles
        p.force = SA[0.0, 0.0, 0.0]
        p.torque = SA[0.0, 0.0, 0.0]
    end
end

function apply_gravity!(particles::Vector{Particle}, g::Float64)
    grav = SA[0.0, 0.0, -g]
    @inbounds for p in particles
        p.force += p.mass * grav
    end
end

function compute_forces!(system)
    particles = system.particles
    model = system.contact_model
    dt = system.dt

    @inbounds for contact in system.contacts
        pi = particles[contact.i]
        pj = contact.j > 0 ? particles[contact.j] : nothing
        pj_data = pj

        # overlap rate
        v_rel = pi.velocity - (pj === nothing ? SA[0.0, 0.0, 0.0] : pj.velocity)
        overlap_dot = -dot(v_rel, contact.normal)

        # normal force
        fn = normal_force(model, pi, pj, pj_data, contact.overlap, overlap_dot)
        f_vec = fn * contact.normal

        # tangential force
        ft_vec = tangential_force(model, pi, pj, pj_data, contact, dt)
        f_vec += ft_vec

        # accumulate on particle i
        pi.force += f_vec
        pi.torque += cross(contact.branch_i, ft_vec)

        # accumulate on particle j (equal and opposite)
        if pj !== nothing
            pj.force -= f_vec
            branch_j = contact.contact_point - pj.position
            pj.torque -= cross(branch_j, ft_vec)
        end
    end
end

function compute_thermal!(system)
    particles = system.particles
    model = system.thermal_model
    dt = system.dt

    @inbounds for contact in system.contacts
        pi = particles[contact.i]
        pj = contact.j > 0 ? particles[contact.j] : nothing

        q = heat_flux(model, pi, pj, pj, contact, dt)
        pi.temperature -= q / pi.heat_capacity
        if pj !== nothing
            pj.temperature += q / pj.heat_capacity
        end
    end
end

"""
    run!(system; t_end=1.0, callbacks=Callback[]) -> system

run the simulation from system.time to t_end.
"""
function run!(system; t_end::Float64 = 1.0,
        callbacks::Vector{Callback} = Callback[])
    dt = system.dt
    n_steps = Int(ceil((t_end - system.time) / dt))

    for step in 1:n_steps
        reset_forces!(system.particles)
        apply_gravity!(system.particles, system.gravity)

        # update contacts (dispatch on neighbor search type)
        update!(system, system.neighbor_search)

        # first half of velocity verlet
        step!(system, system.integrator, dt)

        # recompute forces with new positions
        reset_forces!(system.particles)
        apply_gravity!(system.particles, system.gravity)
        update!(system, system.neighbor_search)
        compute_forces!(system)

        # thermal step
        compute_thermal!(system)

        # second half of velocity verlet
        finish_step!(system, dt)

        system.time += dt
        fire_callbacks!(callbacks, system)
    end

    return system
end
