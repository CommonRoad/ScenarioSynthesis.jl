import StaticArrays.FieldVector, StaticArrays.SVector, StaticArrays.SMatrix
import Base

@inline cycle(vec::Vector, ind::Integer) = vec[mod1(ind, length(vec))] # TODO use CircularArrays instead?

struct State <: FieldVector{2, Float64}
    pos::Float64
    vel::Float64
end

# TODO replace by: ConvexSet{T} = Vector{State} ; T::Bool → "is_empty"
"""
    ConvexSet

Vector of states which form a counter-clockwise convex set.
"""
struct ConvexSet
    vertices::Vector{State}
    is_empty::Bool

    function ConvexSet(vertices::Union{Vector{SVector{2, Float64}}, Vector{State}}, is_empty::Union{Bool, Nothing}=nothing, check_properties::Bool=true)
        for state in vertices
            (isnan(state[1]) || isnan(state[2])) && throw(error("NaN not a valid state."))
        end
        isa(is_empty, Nothing) ? is_empty = length(vertices)<3 : nothing
        if check_properties && !is_empty
            is_counterclockwise_convex(vertices) || throw(error("Vertices are not counter-clockwise convex. $vertices"))
        end
        return new(vertices, is_empty)
    end
end

function is_counterclockwise_convex(vertices::Union{Vector{SVector{2, Float64}}, Vector{State}})
    lenvert = length(vertices)
    rotmat = SMatrix{2, 2, Float64, 4}(0, 1, -1, 0)
    
    @inbounds for i in 1:lenvert-1
        vec_to_next = vertices[i+1] - vertices[i] 
        @inbounds for j = i+2:lenvert
            dot(rotmat * vec_to_next, vertices[j] - vertices[i]) < 0 && (@info i,j; return false) # ≤ 0 would mean, that vertices cannot lay on a straight line
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

Base.:+(cs::ConvexSet, state::State) = ConvexSet([vert + state for vert in cs.vertices], cs.is_empty, false)

function area(cs::ConvexSet)
    area_twice = 0.0
    @inbounds for i=2:length(cs.vertices)-1
        area_twice += cross(cs.vertices[i] - cs.vertices[1], cs.vertices[i+1] - cs.vertices[1])
    end
    return area_twice / 2
end

function centroid(cs::ConvexSet)
    area_twice = 0.0
    centroid = State(0, 0)
    for i=2:length(cs.vertices)-1
        centroid_temp = (cs.vertices[i+1] + cs.vertices[i] + cs.vertices[1]) / 3
        area_twice_temp = cross(cs.vertices[i] - cs.vertices[1], cs.vertices[i+1] - cs.vertices[1])
        centroid = (centroid * area_twice + centroid_temp * area_twice_temp) / (area_twice + area_twice_temp)
        area_twice += area_twice_temp
    end
    return centroid # also return area? 
end

function centroid_and_direction(cs::ConvexSet) # returns main axis of intertia ("Hauptflächenträgheitsmoment") -- this can be unsafe, as two actors an be at the same position at the same time (just with different velocities)
    centr = centroid(cs)
    Iyy = 0.0
    Izz = 0.0
    Iyz = 0.0

    # init with step i=n
    dir = cs.vertices[end] - centr
    dir_next = cs.vertices[1] - centr
    a = dir[1] * dir_next[2] - dir_next[1] * dir[2]
    Iyy += (dir[2]^2 + dir[2]*dir_next[2] + dir_next[2]^2) * a
    Izz += (dir[1]^2 + dir[1]*dir_next[1] + dir_next[1]^2) * a
    Iyz += (dir[1]*dir_next[2] + 2*dir[1]*dir[2] + 2*dir_next[1]*dir_next[2] + dir_next[1]*dir[2]) * a

    # iterate
    for i=1:length(cs.vertices)-1
        dir = cs.vertices[i] - centr
        dir_next = cs.vertices[i+1] - centr
        a = dir[1] * dir_next[2] - dir_next[1] * dir[2]
        Iyy += (dir[2]^2 + dir[2]*dir_next[2] + dir_next[2]^2) * a
        Izz += (dir[1]^2 + dir[1]*dir_next[1] + dir_next[1]^2) * a
        Iyz += (dir[1]*dir_next[2] + 2*dir[1]*dir[2] + 2*dir_next[1]*dir_next[2] + dir_next[1]*dir[2]) * a
    end

    Iyy /= 12
    Izz /= 12
    Iyz /= -24

    ϕ = atan(-2 * Iyz, (Iyy - Izz)) / 2
    return centr, ϕ
end

"""
    fix_convex_polygon

Remove possible numeric problems which might occur after polygon operations.
"""
function fix_convex_polygon!(vertices::Vector{T}) where {T<:Union{State, SVector}}
    i = 1
    while i ≤ length(vertices) # remove succeeding duplicate points, which are almost identical
        if norm(cycle(vertices, i+1) - vertices[i]) < 1e-6
            # @info "fixing - succeeding points almost identical"
            deleteat!(vertices, mod1(i+1, length(vertices)))
        else
            i += 1
        end
    end
    
    i = 1
    while i ≤ length(vertices) # remove points whose vectors are almost collinear
        prev = cycle(vertices, i-1)
        this = vertices[i]
        next = cycle(vertices, i+1)

        vec_to_this = this-prev
        vec_to_next = next-this

        vec_to_this_norm = vec_to_this/norm(vec_to_this)
        vec_to_next_norm = vec_to_next/norm(vec_to_next)

        dotprod = dot(rotate_ccw90(vec_to_this_norm), vec_to_next_norm)
        dotprod < -1e-6 && throw(error("vertices non-convex. $dotprod"))
        if dotprod < 1e-6 
            # @info "fixing - dotproduct: $dotprod"
            deleteat!(vertices, i) # about straight
        else
            i+=1 # convex vertices
        end
    end

    return nothing
end

function rotate_ccw90(vec::T) where {T<:Union{State, SVector{2, Float64}}}
    @assert length(vec) == 2
    return T(-vec[2], vec[1])
end