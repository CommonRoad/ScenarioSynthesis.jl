import StaticArrays.FieldVector, StaticArrays.SVector, StaticArrays.SMatrix
import Base

@inline cycle(vec::Vector, ind::Integer) = vec[mod1(ind, length(vec))] # TODO use CircularArrays instead?

struct State <: FieldVector{2, Float64}
    pos::Float64
    vel::Float64
end

"""
    ConvexSet

Vector of states which form a counter-clockwise convex set.
"""
struct ConvexSet
    vertices::Vector{State}
    is_empty::Bool

    function ConvexSet(vertices::Union{Vector{SVector{2, Float64}}, Vector{State}}, is_empty::Union{Bool, Nothing}=nothing, check_properties::Bool=true)
        isa(is_empty, Nothing) ? is_empty = length(vertices)==0 : nothing
        if check_properties && !is_empty
            is_counterclockwise_convex(vertices) || throw(eror("Vertices are not counter-clockwise convex."))
        end
        return new(vertices, is_empty)
    end
end

function is_counterclockwise_convex(vertices::Vector{SVector{2, Float64}})
    lenvert = length(vertices)
    rotmat = SMatrix{2, 2, Float64, 4}(0, 1, -1, 0)
    
    @inbounds for i in 1:lenvert-1
        vec_to_next = vertices[i+1] - vertices[i] 
        @inbounds for j = i+2:lenvert
            dot(rotmat * vec_to_next, vertices[j] - vertices[i]) < 0 && return false # ≤ 0 would mean, that vertices cannot lay on a straight line
        end
    end
    return true
end

function Base.min(cs::ConvexSet, dir::Integer)
    val = Inf64
    @inbounds for st in cs.vertices
        st[dir] < val ? val = st[dir] : nothing
    end
    return val
end

function Base.max(cs::ConvexSet, dir::Integer)
    val = -Inf64
    @inbounds for st in cs.vertices
        st[dir] > val ? val = st[dir] : nothing
    end
    return val
end

Base.copy(cs::ConvexSet) = ConvexSet(copy(cs.vertices), cs.is_empty, false)