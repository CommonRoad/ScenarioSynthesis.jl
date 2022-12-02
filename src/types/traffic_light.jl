const TrafficLightID = Int64

@enum TL_Direction begin
    TL_Straight
    TL_Right
    TL_Left
    TL_StraightRight
    TL_StraightLeft
    TL_All
end

@enum TL_Color begin
    TL_Red
    TL_RedYellow
    TL_Yellow
    TL_Green
end

struct TL_CycleElement
    duration::Float64
    color::TL_Color

    function TL_CycleElement(duration::Number, color::TL_Color)
        0 < duration || throw(error("Duration must be positive."))
        return new(duration, color)
    end
end

struct TL_Cycle 
    cycle::Vector{TL_CycleElement}
    time_offset::Float64

    function TL_Cycle(cycle::Vector{TL_CycleElement}, time_offset::Number)
        0 ≤ time_offset || throw(error("Time offset must be positive."))
        1 ≤ length(cycle) || throw(error("at least one traffic light cycle element necessary."))
        return new(cycle, time_offset)
    end

    function TL_Cycle(cycle::TL_CycleElement)
        return new(cycle, 0.0)
    end
end

struct TrafficLight
    cycle::TL_Cycle
    position::Pos{FCurv} # only longitudinal coordinate relevant
    direction::TL_Direction
    is_active::Bool

    # TODO add constructors with default values in case position, direction, or is_active are not specified
end
