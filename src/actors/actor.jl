abstract type Actor end

struct Vehicle <: Actor
    id::Int64
    len::Float64 # m 
    wid::Float64 # m
    v_min::Float64 # m/s
    v_max::Float64 # m/s
    a_min::Float64 # m/s²
    a_max::Float64 # m/s²

    function Vehicle(
        id::Int; 
        len::Float64=5.0,
        wid::Float64=2.2,
        v_min::Float64=-4.0,
        v_max::Float64=40.0,
        a_min::Float64=-7.0,
        a_max::Float64=3.0
    )
        @assert len > 0
        @assert wid > 0
        @assert v_min < 0 # backward
        @assert v_max > 0 # forward
        @assert a_min < 0 # breaking 
        @assert a_max > 0 # accelerating

        return new(id, len, wid, v_min, v_max, a_min, a_max)
    end
end