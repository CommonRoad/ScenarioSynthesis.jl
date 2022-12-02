###
# TODO which implementation is better suited? 
###
#=
@enum TrafficSign begin 
    TS_right_before_left # "Achtung, rechts vor links"
    TS_yield # "Vorfahrt gewähren"
    TS_stop # "Stopp-Schild"
    TS_right_of_way # "Vorfahrt an nächster Krezung"
    TS_priority_road # "Vorfahrtsstraße"
    TS_speed_limit # "Höchstgeschwindigkeit"
    TS_required_speed # "Mindestgeschwindigkeit"
    TS_advised_speed # "Richtgeschwindigkeit"
    TS_no_overtaking # "Überholverbot (außer nicht-motorisiert, Züge, Motorräder ohne Beiwagen)"
    TS_green_arrow_sign # "Grüner Pfeil für Rechtsabbieger"
    TS_town_sign # "Ortsschild
end
=#
###
abstract type TrafficSignType end

struct TS_right_before_left <: TrafficSignType end # "Achtung, rechts vor links"
struct TS_yield <: TrafficSignType end # "Vorfahrt gewähren"
# TODO continue...

struct TrafficSign{T} where {T<:TrafficSignType}
    val::Float64
end