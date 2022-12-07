import StaticArrays.FieldVector

abstract type State end

"""
    StateLon

Longitudinal state, consisting of position `s`, velocity `v`, and acceleration `a`.
"""
struct StateLon <: FieldVector{3, Float64}
    s::Float64
    v::Float64
    a::Float64
end

"""
    StateLat

Lateral state, consisting of position `d`, velocity `ḋ`, and acceleration `d̈`.
"""
struct StateLat <: FieldVector{3, Float64}
    d::Float64
    ḋ::Float64
    d̈::Float64
end

"""
    StateCurv

Curvlinear state, consisting of longitudinal state `lon`, and lateral state `lat`.
"""
struct StateCurv <: State
    lon::StateLon
    lat::StateLat

    function StateCurv(lon::StateLon, lat::StateLat)
        return new(lon, lat)
    end

    function StateCurv(lon::AbstractVector, lat::AbstractVector)
        length(lon) == length(lat) == 3 || throw(error("wrong length of input."))
        return new(lon, lat)
    end

    function StateCurv(a::Number, b::Number, c::Number, d::Number, e::Number, f::Number)
        return new([a, b, c], [d, e, f])
    end

end

function Pos(sc::StateCurv)
    return Pos(FCurv, sc.lon.s, sc.lat.d)
end

struct AccInput <: FieldVector{2, Float64}
    lon::Float64
    lat::Float64
end

struct JerkInput <: FieldVector{2, Float64}
    lon::Float64
    lat::Float64
end