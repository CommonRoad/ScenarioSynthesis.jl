import StaticArrays.FieldVector, StaticArrays.SVector, StaticArrays.SMatrix
import Plots

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

    function ConvexSet(vertices::Union{Vector{SVector{2, Float64}}, Vector{State}}, check_properties::Bool=true)
        if check_properties
            length(vertices) ≥ 2 || throw(error("Less than two vertices."))
            is_counterclockwise_convex(vertices) || throw(eror("Vertices are not counter-clockwise convex."))
        end
        return new(vertices)
    end
end

function is_counterclockwise_convex(vertices::Vector{SVector{2, Float64}})
    lenvert = length(vertices)
    rotmat = SMatrix{2, 2, Float64, 4}(0, 1, -1, 0)
    @inbounds for i in 1:lenvert-1
        vec_to_next = vertices[i] - cycle(vertices, i-1) 
        test_vec = rotmat * vec_to_next
        @inbounds for j = i+1:lenvert
            dot(test_vec, vertices[j] - vertices[i]) < 0 && return false
        end
    end
    return true
end