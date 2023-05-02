import DataStructures.SortedDict
const SceneID = Int64

struct Scene
    δ_min::Float64
    δ_max::Float64
    relations::Set{Predicate}

    function Scene(δ_min::Number, δ_max::Number, relations::AbstractVector{<:Predicate})
        @assert 0 < δ_min ≤ δ_max < Inf
        # TODO assert that at max 1 OnLanelet predicate
        return new(δ_min, δ_max, Set{Predicate}(relations))
    end
end

struct ScenesDict
    scenes::SortedDict{SceneID, Scene}

    function ScenesDict(scenes::AbstractVector{Scene})
        return new(SortedDict{SceneID, Scene}(zip(eachindex(scenes), scenes)))
    end
end
