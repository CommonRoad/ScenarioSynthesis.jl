import DataStructures.OrderedDict

const SceneID = Int64

struct Scene
    δ_min::Float64
    δ_max::Float64
    relations::Vector{Relation} # TODO change to set? 

    function Scene(δ_min::Number, δ_max::Number, relations::AbstractVector{Relation})
        @assert 0 < δ_min ≤ δ_max < Inf
        return new(δ_min, δ_max, relations)
    end
end

struct ScenesDict
    scenes::OrderedDict{SceneID, Scene}

    function ScenesDict(scenes::AbstractVector{Scene})
        return new(OrderedDict{SceneID, Scene}(zip(1:length(scenes), scenes)))
    end
end