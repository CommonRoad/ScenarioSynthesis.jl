import LinearAlgebra.cross

struct LineSection{F}
    v1::Pos{F}
    v2::Pos{F}
end

"""
    is_intersection

implementation based on https://stackoverflow.com/questions/563198/how-do-you-detect-where-two-line-segments-intersect
"""
function is_intersect(
    ls1::LineSection{F},
    ls2::LineSection{F}
) where {F<:CoordFrame}
    p = ls1.v1
    r = ls1.v2 - ls1.v1
    q = ls2.v1
    s = ls2.v2 - ls2.v1

    t = cross((q-p), s) / cross(r, s)
    u = cross((q-p), r) / cross(r, s)

    return (0 < t < 1 && 0 < u < 1) # TODO simplified evaulation; is this correct in all cases? # TODO ≤ instead of < ?
end

function pos_intersect(
    ls1::LineSection{F},
    ls2::LineSection{F}
) where {F<:CoordFrame}
    p = ls1.v1
    r = ls1.v2 - ls1.v1
    q = ls2.v1
    s = ls2.v2 - ls2.v1

    t = cross((q-p), s) / cross(r, s)
    u = cross((q-p), r) / cross(r, s)

    if (0 < t < 1 && 0 < u < 1)
        return p + t * r, true
    else
        return Pos(F, Inf64, Inf64), false
    end
end

struct LineStrech{F}
    vertices::Vector{Pos{F}}
end

function is_intersect(
    p1::LineStrech{F},
    p2::LineStrech{F}
) where {F<:CoordFrame}
    @inbounds for i = 1:length(p1.vertices)-1
        ls1 = LineSection(p1.vertices[i], p1.vertices[i+1])
        @inbounds for j = 1:length(p2.vertices)-1
            ls2 = LineSection(p2.vertices[j], p2.vertices[j+1])
            is_intersect(ls1, ls2) && return true
        end
    end
    return false
end

function pos_intersect(
    p1::LineStrech{F},
    p2::LineStrech{F}
) where {F<:CoordFrame}
    @inbounds for i = 1:length(p1.vertices)-1
        ls1 = LineSection(p1.vertices[i], p1.vertices[i+1])
        @inbounds for j = 1:length(p2.vertices)-1
            ls2 = LineSection(p2.vertices[j], p2.vertices[j+1])
            is_intersect(ls1, ls2) && return pos_intersect(ls1, ls2)
        end
    end
    return Pos(F, Float64, Float64), false
end

struct Polygon{F}
    vertices::Vector{Pos{F}} # TODO change to Matrix oder SMatrix? 

    function Polygon(::Type{F}, matrix::AbstractMatrix{<:Number}) where {F<:CoordFrame}
        m, n = size(matrix)
        m == 2 || throw(error("Vertices must consist of exactly 2 values."))
        n ≥ 3 || throw(error("Polygon must consist of at least 3 vertices."))

        return new{F}([Pos{F}(matrix[:,i]) for i=1:n])
    end

    function Polygon(vector::AbstractVector{Pos{F}}) where {F<:CoordFrame}
        n = length(vector)
        n ≥ 3 || throw(error("Polygon must consist of at least 3 vertices."))

        return new{F}(vector)
    end

    function Polygon(::Type{F}, vector::AbstractVector{<:AbstractVector}) where {F<:CoordFrame}
        n = length(vector)
        n ≥ 3 || throw(error("Polygon must consist of at least 3 vertices."))

        vec = map(x -> (@assert length(x)==2; Pos(FCart, x...)), vector) 

        return new{F}(vec)
    end
end

# TODO replace by more advanced implementation 
function is_intersect(
    p1::Polygon{F},
    p2::Polygon{F}
) where {F<:CoordFrame}
    return is_intersect(
        LineStrech([p1.vertices..., p1.vertices[1]]),
        LineStrech([p2.vertices..., p2.vertices[1]])
    )
end