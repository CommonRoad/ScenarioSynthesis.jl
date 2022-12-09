import Match.Match, Match.@match

const TrafficSignID = Int64
const TrafficSignTypeID = Int64

# abstract type TrafficSignType end

# struct TS_Right_before_left <: TrafficSignElementType end # "Achtung, rechts vor links"
# struct TS_Yield <: TrafficSignElementType end # "Vorfahrt gewähren"

@enum TrafficSignType begin
    TS_Yield # 205
    TS_Stop # 206
    TS_Prio_of_oncoming_traffic # 208
    TS_Max_speed # 274
    TS_Min_speed # 275
    TS_Unknown # else
end

function type_from_type_id(type_id::TrafficSignTypeID)
    @match type_id begin
        205 => TS_Yield
        206 => TS_Stop
        208 => TS_Prio_of_oncoming_traffic
        274 => TS_Max_speed
        275 => TS_Min_speed
        _ => TS_Unknown
    end
end

# TODO convert to more refined type system 
struct TrafficSignElement{T}
    aditional_values::Vector{Float64}

    function TrafficSignElement(type_id, additional_values)
        type = type_from_type_id(type_id)
        @assert typeof(type) <: TrafficSignType
        return new{type}(additional_values)
    end

end

struct TrafficSign
    elements::Vector{<:TrafficSignElement}
    position::Pos{FCurv} # only longitudinal coordinate relevant
    is_virtual::Bool # false: physical sign exists; true: no physical sign exists # TODO when does this happen? 

    # TODO add constructor which asserts that all elements are either valid from start or end
end

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
    TS_town_sign # "Ortsschild"
end
=#
###