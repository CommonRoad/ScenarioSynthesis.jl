import Match.Match, Match.@match

const TrafficSignID = Int64
const TrafficSignTypeID = Int64

@enum TrafficSignType begin
    TS_Yield # 205
    TS_Stop # 206
    TS_Prio_of_oncoming_traffic # 208
    TS_Max_speed # 274
    TS_Min_speed # 275
    TS_Unknown # else
end

function trafficSign_typer(type_id::TrafficSignTypeID)
    return @match type_id begin
        205 => TS_Yield
        206 => TS_Stop
        208 => TS_Prio_of_oncoming_traffic
        274 => TS_Max_speed
        275 => TS_Min_speed
        _ => throw(error("not defined. $type_id")) # use TS_Unknown + warning instead?
    end
end

# TODO convert to more refined type system 
struct TrafficSignElement{T}
    aditional_values::Vector{Float64}

    function TrafficSignElement(type_id, additional_values)
        type = trafficSign_typer(type_id)
        @assert typeof(type) <: TrafficSignType
        return new{type}(additional_values)
    end

end

struct TrafficSign
    elements::Vector{<:TrafficSignElement}
    position::Pos{FCart}
    has_position::Bool
    is_virtual::Bool # false: physical sign exists; true: no physical sign exists # TODO when does this happen? 

    # TODO add constructor which asserts that all elements are either valid from start or end
end