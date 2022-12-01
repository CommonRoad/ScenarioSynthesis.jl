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
struct StateCurve <: State
    lon::StateLon
    lat::StateLat
end

function Pos(sc::StateCurve)
    return Pos(FCurv, sc.lon.s, sc.lat.d)
end