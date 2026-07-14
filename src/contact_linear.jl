# linear spring-dashpot contact model

struct LinearSpringDashpot{T<:Float64} <: AbstractContactModel
    kn::T
    kt::T
    gamma_n::T
    mu::T
end

LinearSpringDashpot(; kn=1e5, kt=1e4, gamma_n=1e3, mu=0.3) =
    LinearSpringDashpot(Float64(kn), Float64(kt), Float64(gamma_n), Float64(mu))

function normal_force(model::LinearSpringDashpot, p_i, p_j, p_j_data,
                      overlap::Float64, overlap_dot::Float64)
    return model.kn * overlap + model.gamma_n * overlap_dot
end

function tangential_force(model::LinearSpringDashpot, p_i, p_j, p_j_data,
                          contact, dt::Float64)
    kt = model.kt
    delta_t = contact.tangential_displacement

    # relative tangential velocity at contact
    v_rel = p_i.velocity - (p_j_data === nothing ? SA[0.0,0.0,0.0] : p_j.velocity)
    v_t = v_rel - dot(v_rel, contact.normal) * contact.normal
    delta_t += v_t * dt

    # check coulomb limit
    fn = normal_force(model, p_i, p_j, p_j_data, contact.overlap, 0.0)
    ft_max = model.mu * abs(fn)
    ft_trial = kt * norm(delta_t)

    ft_vec = if ft_trial > ft_max && ft_max > 0
        -ft_max * delta_t / norm(delta_t)
    else
        -kt * delta_t
    end

    # update stored tangential displacement (coulomb slip truncation)
    if ft_trial > ft_max && ft_max > 0 && kt > 0
        contact.tangential_displacement = -ft_max / kt * delta_t / norm(delta_t)
    else
        contact.tangential_displacement = delta_t
    end

    return ft_vec
end
