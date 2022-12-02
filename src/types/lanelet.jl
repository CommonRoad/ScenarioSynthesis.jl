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
        # TODO speed lims checks? 
        length(laneletType) ≥ 1 || throw(error("lanelet type not specified.")) # TODO relax by setting laneletType = LT_Unknown ? 

        transFrame = TransFrame(vertCntr)

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

#=
function Lanelet(
    lanelet_network::Py, 
    mapping::Dict{LaneletID, LaneletPyID}, 
    lanelet_id::Integer,
    merging_with::DefaultDict{LaneletID, Set{LaneletID}},
    diverging_with::DefaultDict{LaneletID, Set{LaneletID}},
    intersecting_with::DefaultDict{LaneletID, Set{LaneletID}}
)
    # @warn "interface not complete" # TODO complete interface
    lanelet = lanelet_network.find_lanelet_by_id(lanelet_id)

    mapping_inv = Dict{LaneletPyID, LaneletID}((v, k) for (k, v) in mapping)

    vertLeft = [Pos(FCart, x, y) for (x, y) in eachrow(pyconvert(Array, lanelet.left_vertices))]
    vertRght = [Pos(FCart, x, y) for (x, y) in eachrow(pyconvert(Array, lanelet.right_vertices))]
    vertCntr = [Pos(FCart, x, y) for (x, y) in eachrow(pyconvert(Array, lanelet.center_vertices))]

    pred = Set(map(id -> mapping_inv[id], pyconvert(Vector{Int64}, lanelet.predecessor)))
    succ = Set(map(id -> mapping_inv[id], pyconvert(Vector{Int64}, lanelet.successor)))

    adjLeft = try
        pyconvert(Bool, lanelet.adj_right_same_direction)
    catch e
        false
    end
    adjRght = try
        pyconvert(Bool, lanelet.adj_left_same_direction)
    catch
        false
    end

    merg = merging_with[mapping_inv[lanelet_id]]
    dive = diverging_with[mapping_inv[lanelet_id]]
    inte = intersecting_with[mapping_inv[lanelet_id]]

    # TODO remove hardcoded values!
    laneletType = LT_Unknown
    lineMarkingType = LM_Unknown

    speedMax = 28.0
    speedMin = -5.0
    speedAdv = Inf64
    stopLine = Inf64

    return Lanelet(
        vertLeft, vertRght, vertCntr, pred, succ, adjLeft, adjRght, laneletType, lineMarkingType, speedMax, speedMin, speedAdv, stopLine, merg, dive, inte
    )
end
=#