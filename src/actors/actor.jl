import DataStructures.OrderedDict

const ActorID = Int64

abstract type ActorType end # TODO replace with RoadUser type? @enum instead of sttucts? 
struct Vehicle <: ActorType end # TODO is this even useful? 

struct Actor # TODO add type as label or element? 
    route::Route
    state::StateCurv
    len::Float64 # m 
    wid::Float64 # m
    v_min::Float64 # m/s
    v_max::Float64 # m/s
    a_min::Float64 # m/s²
    a_max::Float64 # m/s²

    function Actor(
        route::Route,
        state::StateCurv; 
        len::Number=5.0,
        wid::Number=2.2,
        v_min::Number=-4.0,
        v_max::Number=40.0,
        a_min::Number=-7.0,
        a_max::Number=3.0
    )
        @assert len > 0
        @assert wid > 0
        @assert v_min < 0 # backward
        @assert v_max > 0 # forward
        @assert a_min < 0 # breaking 
        @assert a_max > 0 # accelerating
        @assert route.frame.cum_dst[1] ≤ state.lon.s < route.frame.cum_dst[end]

        return new(route, state, len, wid, v_min, v_max, a_min, a_max)
    end
end

LaneletID(actor::Actor) = LaneletID(actor.route, actor.state.lon.s)

struct ActorDict
    actors::OrderedDict{ActorID, Actor}

    function ActorDict(actors::AbstractVector{Actor})
        return new(OrderedDict{Actor, ActorID}(zip(1:length(actors), actors)))
    end
end