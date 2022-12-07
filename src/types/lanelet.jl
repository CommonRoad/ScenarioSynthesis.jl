import LinearAlgebra.norm

const LaneletID = Int64

@enum LineMarkingType LM_Dashed LM_Solid LM_BroadDashed LM_BroadSolid LM_Unknown LM_NoMarking
@enum LaneletType LT_Urban LT_Country LT_Highway LT_DriveWay LT_MainCarriageWay LT_AccessRamp LT_Shoulder LT_BusLane LT_BusStop LT_BicycleLane LT_Sidewalk LT_Crosswalk LT_Interstate LT_Intersection LT_Border LT_Parking LT_Restricted LT_Unknown
@enum RoadUserType RU_Vehicle RU_Car RU_Truck RU_Bus RU_PriorityVehicle RU_Motorcycle RU_Bicycle RU_Pedestrian RU_Train RU_Taxi

abstract type Side end
struct Right <: Side end
struct Left <: Side end
struct Bound{S}
    vertices::Vector{Pos{FCart}}
    lineMarking::LineMarkingType

    function Bound(::Type{S}, vertices::Vector{Pos{FCart}}) where {S<:Side}
        length(vertices) ≥ 2 || throw(error("At least two vertices needed for a Bound."))
        return new{S}(vertices, LM_Unknown)
    end

    function Bound(::Type{S}, vertices::Vector{Pos{FCart}}, lineMarking::LineMarkingType) where {S<:Side}
        length(vertices) ≥ 2 || throw(error("At least two vertices needed for a Bound."))
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

struct StopLine
    is_active::Bool
    has_pos::Bool
    pos1::Pos{FCurv}
    pos2::Pos{FCurv}
    is_ref_to_traffic_light::Bool
    ref_traffic_light::TrafficLightID
    is_ref_to_traffic_sign::Bool
    ref_to_traffic_sign::TrafficSignID

    function StopLine()
        return new(false, false, Pos(FCurv, 0.0, 0.0), Pos(FCurv, 0.0, 0.0), false, -1, false, -1)
    end
end

struct Lanelet
    is_lanelet::Bool # true, except if constructed by null constructor. Simpliefies working with DataStructures.DefaultDicts
    boundLeft::Bound{Left}
    boundRght::Bound{Right}
    vertCntr::Vector{Pos{FCart}}
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
    frame::TransFrame 

    # TODO speed lims? max, min, adv

    # standrad constructor with speed values check
    function Lanelet(
        boundLeft, boundRght, vertCntr, pred, succ, adjLeft, adjRght, stopLine, laneletType, userOneWay, userBidirectional, trafficSign, trafficLight, merging_with, diverging_with, intersecting_with
    )
        length(laneletType) ≥ 1 || throw(error("lanelet type not specified.")) # TODO relax by setting laneletType = LT_Unknown ? 

        transFrame = TransFrame(vertCntr)

        length(vertCntr) == length(boundRght.vertices) == length(boundLeft.vertices) || throw(error("different number of support points for lanelet."))

        return new(
            true, boundLeft, boundRght, vertCntr, pred, succ, adjLeft, adjRght, stopLine, laneletType, userOneWay, userBidirectional, trafficSign, trafficLight, merging_with, diverging_with, intersecting_with, transFrame
        )
    end

    # null constructor
    function Lanelet()
        return new(
            false, Vector{Pos{FCart}}(), Vector{Pos{FCart}}(), Vector{Pos{FCart}}(), Set{LaneletID}(), Set{LaneletID}(), false, false, LT_Unknown, LM_Unknown, Inf64, 0.0, Inf64, Inf64, Set{LaneletID}(), Set{LaneletID}(), Set{LaneletID}(), TransFrame()
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
    
    vertices = Vector{Pos{FCart}}()
    
    trid = findfirst(x -> x > e, lt.frame.cum_dst)

    append!(vertices, lt.boundRght.vertices[trid:end])
    append!(vertices, reverse(lt.boundLeft.vertices[trid:end]))

    e_remain = e - lt.frame.cum_dst[trid]

    vec_to_next_left = lt.boundLeft.vertices[trid-1] - lt.boundLeft.vertices[trid]

    push!(vertices, lt.boundLeft.vertices[trid] + vec_to_next_left * e_remain / norm(vec_to_next_left))

    vec_to_next_rght = lt.boundRght.vertices[trid-1] - lt.boundRght.vertices[trid]

    push!(vertices, lt.boundRght.vertices[trid] + vec_to_next_rght * e_remain / norm(vec_to_next_rght))

    return Polygon(vertices)
end