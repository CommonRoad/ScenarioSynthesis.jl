import StaticArrays.SMatrix, StaticArrays.SVector

const ActorID = Int64

abstract type ActorType end # TODO replace with RoadUser type? @enum instead of sttucts? 
struct Vehicle <: ActorType end # TODO is this even useful? 

struct Actor # TODO add type as label or element? or skip? or bool VRU?  
    route::Route
    states::Vector{ConvexSet}
    lenwid::SVector{2, Float64} # m 
    v_lb::Float64 # m/s
    v_ub::Float64 # m/s
    a_lb::Float64 # m/s²
    a_ub::Float64 # m/s²

    function Actor(
        route::Route,
        initial_state::ConvexSet;
        len::Number=5.0,
        wid::Number=2.2,
        v_lb::Number=-1.0,
        v_ub::Number=30.0,
        a_lb::Number=-6.0,
        a_ub::Number=3.0
    )
        @assert len > 0
        @assert wid > 0
        @assert v_lb < 0 # backward
        @assert v_ub > 0 # forward
        @assert a_lb < 0 # breaking 
        @assert a_ub > 0 # accelerating

        return new(route, [initial_state], SVector{2, Float64}(len, wid), v_lb, v_ub, a_lb, a_ub)
    end
end

struct ActorsDict
    actors::Dict{ActorID, Actor}
    offset::Dict{Tuple{ActorID, ActorID}, Float64}

    function ActorsDict(actors::AbstractVector{Actor}, ln::LaneletNetwork)
        offset = Dict{Tuple{ActorID, ActorID}, Float64}()

        for i in eachindex(actors)
            for j in i+1:length(actors)
                ref_pos_fcart_i, ref_pos_fcart_j, does_exist = reference_pos(actors[i].route, actors[j].route, ln)

                if does_exist
                    ref_pos_i = transform(FRoute, ref_pos_fcart_i, actors[i].route.frame)
                    ref_pos_j = transform(FRoute, ref_pos_fcart_j, actors[j].route.frame)

                    offset[(i,j)] = ref_pos_j.c1 - ref_pos_i.c1
                    offset[(j,i)] = ref_pos_i.c1 - ref_pos_j.c1
                end
            end
        end

        return new(Dict{ActorID, Actor}(zip(eachindex(actors), actors)), offset) # assign each actor a unique ActorID
    end
end

#=
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
    lon1, #::Number,
    actor2::Actor,
    lon2, #::Number,
    ln::LaneletNetwork
)
    ref_pos1, ref_pos2, does_exist = reference_pos(actor1.route, actor2.route, ln)
    
    return (does_exist ? (lon1 - lon2 - transform(ref_pos1, actor1.route.frame).c1 + transform(ref_pos2, actor2.route.frame).c1, true) : (Inf64, false))
end
=#