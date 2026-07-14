# contact model interface , every force law subtypes this

abstract type AbstractContactModel end

"""
    normal_force(model, p_i, p_j, p_j_data, overlap, overlap_dot) -> Float64

return the scalar normal force magnitude (positive = repulsive).
`p_j_data` is `nothing` for particle-wall contacts.
"""
function normal_force(model::AbstractContactModel, p_i, p_j, p_j_data,
        overlap::Float64, overlap_dot::Float64)
    error("normal_force not implemented for $(typeof(model))")
end

"""
    tangential_force(model, p_i, p_j, p_j_data, contact) -> SVector{3,Float64}

return the tangential force vector at the contact.
defaults to zero (frictionless).
"""
function tangential_force(model::AbstractContactModel, p_i, p_j, p_j_data,
        contact, dt::Float64)
    return SA[0.0, 0.0, 0.0]
end
