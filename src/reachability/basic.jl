import StaticArrays.FieldVector, StaticArrays.SVector, StaticArrays.SMatrix
import Plots

@inline function cycle(vec::Vector, ind::Integer) # TODO use CircularArrays instead?
    lenvec = length(vec)
    ind = mod(ind, 1:lenvec)
    return vec[ind]
end

struct State <: FieldVector{2, Float64}
    pos::Float64
    vel::Float64
end

struct ConvexStates
    vertices::Vector{State}

    function ConvexStates(vertices::Vector{SVector{2, Float64}}, check_properties::Bool=true)
        if check_properties
            length(vertices) ≥ 2 || throw(error("Less than two vertices."))
            is_convex(vertices) || throw(error("Vertices are non-convex."))
            is_counter_clockwise(vertices) || throw(eror("Vertices are not ordered counter-clockwise."))
        end
        return new(vertices)
    end
end

function is_convex(vertices::Vector{SVector{2, Float64}})
    @warn "function not implement yet."
    return true # TODO add code
end

function is_counter_clockwise(vertices::Vector{SVector{2, Float64}})
    val, ind = findmin(x -> x[2], vertices) # minimum velocity
    vec_from_prev = vertices[ind] - cycle(vertices, ind-1)
    vec_to_next = cycle(vertices, ind+1) - vertices[ind]
    
    dotprod = dot(vec_to_next, SVector{2, Float64}(-vec_from_prev[2], vec_from_prev[1]))
    
    return dotprod > 0.0 ? true : false
end