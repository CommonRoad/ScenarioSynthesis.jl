using StaticArrays
using LinearAlgebra

abstract type Position end
abstract type CoordFrame end
struct FCart <: CoordFrame end
struct FCurv <: CoordFrame end

"""
    Pos{F}

Generic position in coordinate frame `F`.
"""
struct Pos{F} <: Position
    p::SVector{2,Float64}

    function Pos(frame::Type{F}, p::SVector{2,<:Number}) where {F<:CoordFrame}
        return new{F}(p)
    end

    function Pos(frame::Type{F}, x::Number, y::Number) where {F<:CoordFrame}
        return new{F}(SVector{2,Float64}(x, y))
    end
end

"""
    Vec{F}

Generic vector in coordinate frame `F`.
"""
struct Vec{F}
    v::SVector{2,Float64}

    function Vec(frame::Type{F}, v::SVector{2,<:Number}) where {F<:CoordFrame}
        return new{F}(v)
    end

    function Vec(frame::Type{F}, ẋ::Number, ẏ::Number) where {F<:CoordFrame}
        return new{F}(SVector{2,Float64}(ẋ, ẏ))
    end
end

function Base.:-(p1::Pos{F}, p2::Pos{F}) where {F<:CoordFrame}
    return Vec(F, p1.p - p2.p)
end

function distance(p1::Pos{F}, p2::Pos{F}) where {F<:CoordFrame}
    vec = p2 - p1
    return norm(vec.v)
end