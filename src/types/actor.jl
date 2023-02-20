import DataStructures.SortedDict
import StaticArrays.SMatrix, StaticArrays.SVector

const ActorID = Int64

abstract type ActorType end # TODO replace with RoadUser type? @enum instead of sttucts? 
struct Vehicle <: ActorType end # TODO is this even useful? 

struct Actor # TODO add type as label or element? 
    route::Route
    # states::Vector{ConvexSet},
    lenwid::SVector{2, Float64} # m 
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

        return new(route, SVector{2, Float64}(len, wid), v_min, v_max, a_min, a_max)
    end
end

struct ActorsDict
    actors::SortedDict{ActorID, Actor}

    function ActorsDict(actors::AbstractVector{Actor})
        return new(SortedDict{ActorID, Actor}(zip(eachindex(actors), actors))) # assign each actor a unique ActorID
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
    lon1, #::Number,
    actor2::Actor,
    lon2, #::Number,
    ln::LaneletNetwork
)
    ref_pos1, ref_pos2, does_exist = reference_pos(actor1.route, actor2.route, ln)
    
    return (does_exist ? (lon1 - lon2 - transform(ref_pos1, actor1.route.frame).c1 + transform(ref_pos2, actor2.route.frame).c1, true) : (Inf64, false))
end

function LaneletID(actor::Actor, ln::LaneletNetwork, s_r, d) # ref_lt_safe
    ref_ltid, s_l = ref_lanelet(actor, s_r)
    ref_lt = ln.lanelets[ref_ltid]
    ref_d_max, ref_d_min = lanelet_width(ref_lt, s_l)

    ref_d_min ≤ d ≤ ref_d_max || throw(error("could not determine LaneletID."))

    return ref_ltid
end

function ref_lanelet(actor::Actor, s_r) # ref_lt_unsafe
    0.0 ≤ s_r ≤ actor.route.frame.cum_dst[end] || throw(error("out of bounds."))
    ind = findlast(x -> x ≤ s_r, actor.route.transition_points)
    ltid = actor.route.route[ind]
    s_l = s_r - actor.route.transition_points[ind]
    return ltid, s_l
end

# returns only those lanelets, which are logicially connected
# be more accurate by using conflict section information (of lanelets) -- only implemented for on ref lt yet -- should be accurate enough
function lanelets(actor::Actor, ln::LaneletNetwork, s, v, d, ḋ)
    Θ_a = atan(ḋ, v)
    -0.35 ≤ Θ_a ≤ 0.35 || @warn "Θ_a pretty high; please check correctness."
    ref_lt_id, s_l = ref_lanelet(actor, s)
    ref_lt = ln.lanelets[ref_lt_id]

    si, co = sincos(Θ_a)
    # lateral
    proj_wid = abs(si * actor.lenwid[1] + co * actor.lenwid[2])
    d_max = d + proj_wid / 2
    d_min = d - proj_wid / 2
    ref_lt_d_max, ref_lt_d_min = lanelet_width(ref_lt, s_l)

    # longitudial
    proj_len = abs(co * actor.lenwid[1] + si * actor.lenwid[2])
    s_lt_max = s_l + proj_len / 2
    s_lt_min = s_l - proj_len / 2

    # collect results
    lts = Set{LaneletID}()

    (d_max - ref_lt_d_max > 3.0 || d_min - ref_lt_d_min < -3.0 || s_lt_min < -5.0 || s_lt_max - ref_lt.frame.cum_dst[end] > 5.0) && @warn "only valid for small deviations from route"

    # first lateral, then longitudial 
    if ref_lt_d_max ≤ d_max # on adjacent left
        if s_lt_min ≤ 0.0 # on pred
            for p_lt_id in ref_lt.pred
                p_lt = ln.lanelets[p_lt_id]
                p_lt.adjLeft.is_exist && push!(lts, p_lt.adjLeft.lanelet_id)
            end
        end
        
        if  0.0 ≤ s_lt_max || s_lt_min ≤ ref_lt.frame.cum_dst[end] # on ref lanelet
            ref_lt.adjLeft.is_exist && push!(lts, ref_lt.adjLeft.lanelet_id)
        end

        if ref_lt.frame.cum_dst[end] ≤ s_lt_max # on succ
            for s_lt_id in ref_lt.succ
                s_lt = ln.lanelets[s_lt_id]
                s_lt.adjLeft.is_exist && push!(lts, s_lt.adjLeft.lanelet_id)
            end
        end
    end

    if ref_lt_d_min ≤ d_min ≤ ref_lt_d_max || ref_lt_d_min ≤ d_max ≤ ref_lt_d_max # on ref lanelet
        if s_lt_min ≤ 0.0 # on pred
            union!(lts, ref_lt.pred)
        end
        
        if  0.0 ≤ s_lt_max ≤ ref_lt.frame.cum_dst[end] || 0 ≤ s_lt_min ≤ ref_lt.frame.cum_dst[end] # on ref lanelet
            push!(lts, ref_lt_id)
            for (csid, cs) in ref_lt.conflict_sections
                if cs[1] ≤ s_l ≤ cs[2]
                    id1, id2 = ln.conflict_sections[csid]
                    id1 == ref_lt_id && push!(lts, id2)
                    id2 == ref_lt_id && push!(lts, id1)
                end
            end
        end

        if ref_lt.frame.cum_dst[end] ≤ s_lt_max # on succ
            union!(lts, ref_lt.succ)
        end
    end

    if d_min ≤ ref_lt_d_min # on adjacent right
        if s_lt_min ≤ 0.0 # on pred
            for p_lt_id in ref_lt.pred
                p_lt = ln.lanelets[p_lt_id]
                p_lt.adjRght.is_exist && push!(lts, p_lt.adjRght.lanelet_id)
            end
        end
        
        if  0.0 ≤ s_lt_max || s_lt_min ≤ ref_lt.frame.cum_dst[end] # on ref lanelet
            ref_lt.adjRght.is_exist && push!(lts, ref_lt.adjRght.lanelet_id)
        end

        if ref_lt.frame.cum_dst[end] ≤ s_lt_max # on succ
            for s_lt_id in ref_lt.succ
                s_lt = ln.lanelets[s_lt_id]
                s_lt.adjRght.is_exist && push!(lts, s_lt.adjRght.lanelet_id)
            end
        end
    end
    
    !in(ref_lt_id, lts) && @warn "reference lanelet not touched; check for correctness."

    return lts
end