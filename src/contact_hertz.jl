# hertz-mindlin contact model , nonlinear elastic + damping

struct HertzMindlin{T <: Float64} <: AbstractContactModel
    youngs_modulus::T
    poisson_ratio::T
    restitution::T
    mu::T
end

function HertzMindlin(;
        youngs_modulus = 1e9, poisson_ratio = 0.3, restitution = 0.9, mu = 0.3)
    HertzMindlin(Float64(youngs_modulus), Float64(poisson_ratio),
        Float64(restitution), Float64(mu))
end

# effective material properties for a particle pair
function _effective_props(model::HertzMindlin, p_i, p_j)
    e_star = model.youngs_modulus / (2 * (1 - model.poisson_ratio^2))
    r_star = p_i.radius * p_j.radius / (p_i.radius + p_j.radius)
    return e_star, r_star
end

function _effective_props_wall(model::HertzMindlin, p_i)
    e_star = model.youngs_modulus / (1 - model.poisson_ratio^2)
    r_star = p_i.radius
    return e_star, r_star
end

function normal_force(model::HertzMindlin, p_i, p_j, p_j_data,
        overlap::Float64, overlap_dot::Float64)
    e_star, r_star = if p_j_data === nothing
        _effective_props_wall(model, p_i)
    else
        _effective_props(model, p_i, p_j)
    end

    # hertz elastic force
    kn = (4 / 3) * e_star * sqrt(r_star)
    f_el = kn * overlap^(3 / 2)

    # damping from restitution coefficient
    m_star = if p_j_data === nothing
        p_i.mass
    else
        p_i.mass * p_j.mass / (p_i.mass + p_j.mass)
    end
    if model.restitution < 1.0
        beta = -log(model.restitution) / sqrt(pi^2 + log(model.restitution)^2)
        gamma = 2 * beta * sqrt(m_star * kn) * overlap^(1 / 4)
    else
        gamma = 0.0
    end

    return f_el + gamma * overlap_dot
end

function tangential_force(model::HertzMindlin, p_i, p_j, p_j_data,
        contact, dt::Float64)
    e_star, r_star = if p_j_data === nothing
        _effective_props_wall(model, p_i)
    else
        _effective_props(model, p_i, p_j)
    end

    g_star = e_star / (2 * (1 + model.poisson_ratio))
    kt = 8 * g_star * sqrt(r_star * contact.overlap)

    delta_t = contact.tangential_displacement
    v_rel = p_i.velocity - (p_j_data === nothing ? SA[0.0, 0.0, 0.0] : p_j.velocity)
    v_t = v_rel - dot(v_rel, contact.normal) * contact.normal
    delta_t += v_t * dt

    fn = normal_force(model, p_i, p_j, p_j_data, contact.overlap, 0.0)
    ft_max = model.mu * abs(fn)
    ft_trial = kt * norm(delta_t)

    ft_vec = if ft_trial > ft_max && ft_max > 0
        -ft_max * delta_t / norm(delta_t)
    else
        -kt * delta_t
    end

    if ft_trial > ft_max && ft_max > 0 && kt > 0
        contact.tangential_displacement = -ft_max / kt * delta_t / norm(delta_t)
    else
        contact.tangential_displacement = delta_t
    end

    return ft_vec
end
