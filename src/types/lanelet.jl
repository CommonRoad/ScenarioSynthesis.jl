import LinearAlgebra.norm
import Match.Match, Match.@match

const LaneletID = Int64
const ConflictSectionID = Int64

@enum LineMarkingType LM_Dashed LM_Solid LM_BroadDashed LM_BroadSolid LM_Unknown LM_NoMarking
@enum LaneletType LT_Urban LT_Country LT_Highway LT_DriveWay LT_MainCarriageWay LT_AccessRamp LT_ExitRamp LT_Shoulder LT_BusLane LT_BusStop LT_BicycleLane LT_Sidewalk LT_Crosswalk LT_Interstate LT_Intersection LT_Border LT_Parking LT_Restricted LT_Unknown
@enum RoadUserType RU_Vehicle RU_Car RU_Truck RU_Bus RU_PriorityVehicle RU_Motorcycle RU_Bicycle RU_Pedestrian RU_Train RU_Taxi

function linemarking_typer(str::String)
    return @match str begin
        "dashed" => LM_Dashed
        "solid" => LM_Solid
        "broad_dashed" => LM_BroadDashed
        "borad_solid" => LM_BroadSolid
        "no_marking" => LM_NoMarking
        "unknown" => LM_Unknown
        _ => throw(error("not defined: $str"))
    end
end

function lanelet_typer(str::String)
    return @match str begin
        "urban" => LT_Urban
        "country" => LT_Country
        "highway" => LT_Highway
        "driveWay" => LT_DriveWay
        "mainCarriageWay" => LT_MainCarriageWay
        "accessRamp" => LT_AccessRamp
        "exitRamp" => LT_ExitRamp
        "shoulder" => LT_Shoulder
        "busLane" => LT_BusLane
        "busStop" => LT_BusStop
        "bicycleLane" => LT_BicycleLane
        "sidewalk" => LT_Sidewalk
        "crosswalk" => LT_Crosswalk
        "interstate" => LT_Interstate
        "unknown" => LT_Unknown
        _ => throw(error("not defined: $str"))
    end
end

function roaduser_typer(str::String)
    return @match str begin
        "vehicle" => RU_Vehicle
        "car" => RU_Car
        "truck" => RU_Truck
        "bus" => RU_Bus
        "priorityVehicle" => RU_PriorityVehicle
        "motorcycle" => RU_Motorcycle
        "bicycle" => RU_Bicycle
        "pedestrian" => RU_Pedestrian
        "train" => RU_Train
        "taxi" => RU_Taxi
        _ => throw(error("not defined: $str"))
    end
end

abstract type Side end
struct Right <: Side end
struct Left <: Side end

struct Bound{S}
    vertices::Vector{Pos{FCart}}
    lineMarking::LineMarkingType

    function Bound(::Type{S}, vertices::Vector{Pos{FCart}}) where {S<:Side}
        length(vertices) ≥ 2 || throw(error("At least two vertices needed for a boundary."))
        return new{S}(vertices, LM_Unknown)
    end

    function Bound(::Type{S}, vertices::Vector{Pos{FCart}}, lineMarking::LineMarkingType) where {S<:Side}
        length(vertices) ≥ 2 || throw(error("At least two vertices needed for a boundary."))
        return new{S}(vertices, lineMarking)
    end
end

struct Adjacent{S}
    is_exist::Bool
    lanelet_id::LaneletID
    is_same_direction::Bool

    function Adjacent(::Type{S}, lanelet_id::LaneletID, is_same_direction::Bool) where {S<:Side}
        return new{S}(true, lanelet_id, is_same_direction)
    end

    function Adjacent(::Type{S}) where {S<:Side}
        return new{S}(false, -1, false)
    end
end

struct StopLine{L}
    is_active::Bool
    has_pos::Bool
    pos1::Pos{FCart}
    pos2::Pos{FCart}
    is_ref_to_traffic_sign::Bool
    ref_to_traffic_sign::TrafficSignID
    is_ref_to_traffic_light::Bool
    ref_to_traffic_light::TrafficLightID

    function StopLine(::Type{L}, pos1::Union{Pos{FCart}, Nothing}=Nothing, pos2::Union{Pos{FCart}, Nothing}=Nothing, ref_to_traffic_sign::Union{TrafficSignID, Nothing}=Nothing, ref_to_traffic_light::Union{TrafficLightID, Nothing}=Nothing) where {L<:LineMarkingType}
        has_pos = isa(pos1, Pos{FCart}) && isa(pos2, Pos{FCart})
        is_ref_to_traffic_sign = isa(ref_to_traffic_sign, TrafficSignID)
        is_ref_to_traffic_light = isa(ref_to_traffic_light, TrafficLightID)

        isa(pos1, Pos{FCart}) ? nothing : pos1 = Pos(FCart, Inf64, Inf64)
        isa(pos2, Pos{FCart}) ? nothing : pos2 = Pos(FCart, Inf64, Inf64)
        isa(ref_to_traffic_sign, TrafficSignID) ? nothing : ref_to_traffic_sign = -1
        isa(ref_to_traffic_light, TrafficLightID) ? nothing : ref_to_traffic_light = -1

        is_active = has_pos || is_ref_to_traffic_sign || is_ref_to_traffic_light

        return new{L}(is_active, has_pos, pos1, pos2, is_ref_to_traffic_sign, ref_to_traffic_sign, is_ref_to_traffic_light, ref_to_traffic_light)
    end

    function StopLine()
        return new{LM_Unknown}(false, false, Pos(FCart, Inf64, Inf64), Pos(FCart, Inf64, Inf64), false, -1, false, -1)
    end
end

struct Lanelet
    is_lanelet::Bool # true, except if constructed by null constructor. Simpliefies working with DataStructures.DefaultDicts
    boundLeft::Bound{Left}
    boundRght::Bound{Right}
    pred::Set{LaneletID}
    succ::Set{LaneletID}
    adjLeft::Adjacent{Left} # same driving direction on adjecent left lane? whether the lane exists is implicitly defined by LaneletNetwork.lanelets data structure
    adjRght::Adjacent{Right} # TODO align with commonroad file-format? could enhance interoperability
    stopLine::StopLine
    laneletType::Set{LaneletType}
    userOneWay::Set{RoadUserType}
    userBidirectional::Set{RoadUserType}
    trafficSign::Set{TrafficSignID}
    trafficLight::Set{TrafficLightID}
    merging_with::Set{LaneletID}
    diverging_with::Set{LaneletID}
    intersecting_with::Set{LaneletID}
    conflict_sections::Dict{ConflictSectionID, Tuple{Float64, Float64}}
    frame::TransFrame 

    function Lanelet(
        boundLeft, boundRght, vertCntr, pred, succ, adjLeft, adjRght, stopLine, laneletType, userOneWay, userBidirectional, trafficSign, trafficLight
    )
        if length(laneletType) < 1 
            laneletType = Set([LT_Unknown]) # throw(error("lanelet type not specified.")) # TODO relax by setting laneletType = LT_Unknown ? 
        end
        transFrame = TransFrame(FLanelet, vertCntr)
        length(vertCntr) == length(boundRght.vertices) == length(boundLeft.vertices) || throw(error("different number of support points for lanelet."))
        return new(
            true, boundLeft, boundRght, pred, succ, adjLeft, adjRght, stopLine, laneletType, userOneWay, userBidirectional, trafficSign, trafficLight, Set{LaneletID}(), Set{LaneletID}(), Set{LaneletID}(), Dict{ConflictSectionID, Tuple{Float64, Float64}}(), transFrame
        )
    end
end

function Polygon(lt::Lanelet)
    return Polygon([lt.boundRght.vertices..., reverse(lt.boundLeft.vertices)...])
end

function Polygon_cut_from_start(lt::Lanelet, s::Number)
    0 < s < lt.frame.cum_dst[end] || throw(error("out of bounds."))
    
    vertices = Vector{Pos{FCart}}()
    trid = findlast(x -> x ≤ s, lt.frame.cum_dst)
    append!(vertices, lt.boundRght.vertices[1:trid])
    s_remain = s - lt.frame.cum_dst[trid]
    vec_to_next_rght = lt.boundRght.vertices[trid+1] - lt.boundRght.vertices[trid]
    push!(vertices, lt.boundRght.vertices[trid] + vec_to_next_rght * s_remain / norm(vec_to_next_rght))
    vec_to_next_left = lt.boundLeft.vertices[trid+1] - lt.boundLeft.vertices[trid]
    push!(vertices, lt.boundLeft.vertices[trid] + vec_to_next_left * s_remain / norm(vec_to_next_left))
    append!(vertices, reverse(lt.boundLeft.vertices[1:trid]))

    return Polygon(vertices)
end

function Polygon_cut_from_end(lt::Lanelet, e::Number)
    0 < e < lt.frame.cum_dst[end] || throw(error("out of bounds."))

    e = lt.frame.cum_dst[end] - e 
    vertices = Vector{Pos{FCart}}()
    trid = findfirst(x -> x > e, lt.frame.cum_dst)
    append!(vertices, lt.boundRght.vertices[trid:end])
    append!(vertices, reverse(lt.boundLeft.vertices[trid:end]))
    e_remain = e - lt.frame.cum_dst[trid]
    vec_to_next_left = lt.boundLeft.vertices[trid-1] - lt.boundLeft.vertices[trid]
    push!(vertices, lt.boundLeft.vertices[trid] - vec_to_next_left * e_remain / norm(vec_to_next_left))
    vec_to_next_rght = lt.boundRght.vertices[trid-1] - lt.boundRght.vertices[trid]
    push!(vertices, lt.boundRght.vertices[trid] - vec_to_next_rght * e_remain / norm(vec_to_next_rght))

    return Polygon(vertices)
end

function orientation(lt::Lanelet, s::Real) # TODO check coordinate defs, write test
    0.0 ≤ s < lt.frame.cum_dst[end] || throw(error("out of bounds."))

    ind = findlast(x -> x ≤ s, lt.frame.cum_dst)
    vec_to_next = lt.frame.ref_pos[ind+1] - lt.frame.ref_pos[ind]
    return tan(vec_to_next[2]/vec_to_next[1])
end

# TODO use geometry based approach instead? (4x pos in poly; iterate over all lanelets)
# TODO get first ltid based on route CoordFrame and subsequently check for neighboring lanelets
#=
function lanelets(actor::Actor, s) # s: lon pos in frame of actor
    r = sqrt(actor.len^2 + actor.wid^2) # TODO not fairly accurate 
    s_min = s - r
    s_max = s + r
    (0 ≤ s_min && s_max ≤ actor.route.frame.cum_dst[end]) || throw(error("out of bounds.")) # TODO other handling
    ind_low = findlast(x -> x ≤ s_min, actor.route.transition_points)
    ind_upp = findlast(x -> x ≤ s_max, actor.route.transition_points)

    return actor.route.route[ind_low:ind_upp]
end

function lanelets(actor::Actor, ln::LaneletNetwork, s, v, d=0.0, ḋ=0.0)
    center = transform(Pos(FCurv, s, d), actor.route.frame)
    Θ_a = atan(ḋ/v)
    ref_ltid = findlast(x -> x ≤ s, actor.route.transition_points)
    Θ_l = 0.0
end
=#