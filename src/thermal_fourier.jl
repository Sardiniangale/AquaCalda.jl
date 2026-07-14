# fourier conduction across contact area, default thermal model

struct FourierContact <: AbstractThermalModel end

"""
    heat_flux(::FourierContact, p_i, p_j, p_j_data, contact, dt) -> Float64

steady-state conduction across a circular contact area.
returns heat transferred this timestep [J].
"""
function heat_flux(::FourierContact, p_i, p_j, p_j_data, contact, dt::Float64)
    # contact radius from overlap and particle radii
    r_star = if p_j_data === nothing
        p_i.radius
    else
        p_i.radius * p_j.radius / (p_i.radius + p_j.radius)
    end
    contact_radius = sqrt(r_star * contact.overlap)
    contact_area = pi * contact_radius^2

    # effective conductivity (series resistance)
    k_eff = if p_j_data === nothing
        p_i.conductivity
    else
        2 * p_i.conductivity * p_j.conductivity /
        (p_i.conductivity + p_j.conductivity)
    end

    delta_t = p_j_data === nothing ? 0.0 : p_i.temperature - p_j.temperature
    return k_eff * contact_area * delta_t * dt /
           (p_i.radius + (p_j_data === nothing ? 0.0 : p_j.radius)) * 2
end
