# callbacks , observer pattern for simulation monitoring

struct Callback
    f::Function
    interval::Int
    counter::Int
end

"""
    every(n_steps) do sys ... end

create a callback that fires every `n_steps` timesteps.
"""
function every(interval::Int)
    return function (f::Function)
        return Callback(f, interval, 0)
    end
end

function maybe_fire!(cb::Callback, system)
    cb.counter += 1
    if cb.counter >= cb.interval
        cb.f(system)
        cb.counter = 0
    end
end

function fire_callbacks!(callbacks::Vector{Callback}, system)
    for cb in callbacks
        maybe_fire!(cb, system)
    end
end
