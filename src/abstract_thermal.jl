# thermal model interface

abstract type AbstractThermalModel end

"""
    heat_flux(model, p_i, p_j, p_j_data, contact, dt) -> Float64

return the heat energy transferred across the contact this timestep [J].
positive = heat flows from i to j.
"""
function heat_flux(model::AbstractThermalModel, p_i, p_j, p_j_data,
                   contact, dt::Float64)
    error("heat_flux not implemented for $(typeof(model))")
end
