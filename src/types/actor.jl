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

"""
    lon_distance

Longitudinal distance of `lon1` in CoordFrame of `actor1` and `lon2`in CoordFrame of `actor2`. 
Positive: `lon1` ahead of `lon2`
Negative: vice versa
Inf: routes of `actor1`and `actor2` do not merge at any point.
"""
function lon_distance(
    actor1::Actor,
    lon1::Number,
    actor2::Actor,
    lon2::Number,
    ln::LaneletNetwork
)
    ref_pos, does_exist = ref_pos_of_merging_routes(actor1.route, actor2.route, ln) # TODO also enable for neighboring and intersecting lanes? 
    
    return (does_exist ? (lon1 - lon2 - transform(ref_pos, actor1.route.frame).c1 + transform(ref_pos, actor2.route.frame).c1, true) : (Inf64, false))
end

function LaneletID(actor::Actor, state::StateCurv, ln::LaneletNetwork)
    0 ≤ state.lon.s < actor.route.transition_points[end] || throw(error("out of bounds."))
    trid = findlast(x -> x ≤ state.lon.s, actor.route.transition_points)
    ltid = actor.route.route[trid]
    lt = ln.lanelets[ltid]

    # check whether lateral position is within bounds # TODO linear interpolation of distances before and after actual position would be even more accurate
    s_lt = state.lon.s - actor.route.transition_points[trid] # longitudial coordinate in lanelet frame
    trid_lt = findlast(x -> x ≤ s_lt, lt.frame.cum_dst) # last center support point before longitudinal pos
    d_rght = distance(lt.frame.ref_pos[trid_lt], lt.boundRght.vertices[trid_lt]) # distance to right boundary
    d_left = distance(lt.frame.ref_pos[trid_lt], lt.boundLeft.vertices[trid_lt])

    -d_rght ≤ state.lat.d ≤ d_left || throw(error("could not determine LaneletID."))

    return ltid
end