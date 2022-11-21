"""
    Scenario

Scenario is defined by its `actors`, and `scenes`.
"""
struct Scenario{T} where {T::Actor}
    actors::Vector{T}
    scenes::Vector{Scene}

    function Scenario()
        return new(Vector{Scene}())
    end

    function Scenario(scenes::Vector{Scene})
        return new(scenes)
    end
end