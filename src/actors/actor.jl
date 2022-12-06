import DataStructures.OrderedDict
import StaticArrays.SMatrix, StaticArrays.SVector

const ActorID = Int64

abstract type ActorType end # TODO replace with RoadUser type? @enum instead of sttucts? 
struct Vehicle <: ActorType end # TODO is this even useful? 

struct Actor # TODO add type as label or element? 
    route::Route # TODO maybe detach route from actor and infer rout based on scenes instead? => more freedom for optimizer
    len::Float64 # m 
    wid::Float64 # m
    v_min::Float64 # m/s
    v_max::Float64 # m/s
    a_min::Float64 # m/s²
    a_max::Float64 # m/s²

    function Actor(
        route::Route;
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

        return new(route, len, wid, v_min, v_max, a_min, a_max)
    end
end

struct ActorsDict
    actors::OrderedDict{ActorID, Actor}

    function ActorsDict(actors::AbstractVector{Actor})
        return new(OrderedDict{ActorID, Actor}(zip(1:length(actors), actors)))
    end
end

function run_timestep(
    state::StateCurv,
    input::JerkInput, # constant over time Δt
    Δt::Number
)
    system = SMatrix{3, 3, Float64, 9}(1, 0, 0, Δt, 1, 0, 1/2*Δt^2, Δt, 1)
    excitation = SVector{3, Float64}(1/6*Δt^3, 1/2*Δt^2, Δt)
    
    lon = system * state.lon + excitation * input.lon
    lat = system * state.lat + excitation * input.lat

    return StateCurv(lon, lat) 
end

function run_timestep(
    state::StateCurv,
    input::AccInput,
    Δt::Number
)
    system = SMatrix{3, 3, Float64, 9}(1, 0, 0, Δt, 1, 0, 0, 0, 0)
    excitation = SVector{3, Float64}(1/2*Δt^2, Δt, 1)

    lon = system * state.lon + excitation * input.lon
    lat = system * state.lat + excitation * input.lat

    return StateCurv(lon, lat)
end