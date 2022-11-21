struct Scene
    k::Int64
    δ_min::Float64
    δ_max::Float64
    # relations

    function Scene(k, δ_min, δ_max)
        @assert 0 < δ_min ≤ δ_max < Inf
        return new(k, δ_min, δ_max)
    end
end