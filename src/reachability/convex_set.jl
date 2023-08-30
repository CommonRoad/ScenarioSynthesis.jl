#import StaticArrays: FieldVector, SVector, SMatrix
#import Base
#import Polygons: State, ConvexSet, area, centroid, is_ccw_convex, rotate_90_ccw

Base.:+(cs::ConvexSet, s::State) = ConvexSet([v+s for v in cs.vertices])

#=
function centroid_and_direction(cs::ConvexSet) # returns main axis of intertia ("Hauptflächenträgheitsmoment") -- this can be unsafe, as two agents an be at the same position at the same time (just with different velocities)
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
=#