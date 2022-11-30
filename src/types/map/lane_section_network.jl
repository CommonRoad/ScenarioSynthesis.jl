const LaneletPyID = Int64

struct LaneSectionID
    sect::Int64
    lane::Int64
end

@enum LineMarkingType LM_Dashed LM_Solid LM_BroadDashed LM_BroadSolid LM_Unknown LM_NoMarking
@enum LaneType LT_Urban LT_Country LT_Highway LT_DriveWay LT_MainCarriageWay LT_AccessRamp LT_Shoulder LT_BusLane LT_BusStop LT_BicycleLane LT_Sidewalk LT_Crosswalk LT_Interstate LT_Intersection LT_Border LT_Parking LT_Restricted LT_Unknown
@enum RoadUserType RU_Vehicle RU_Car RU_Truck RU_Bus RU_PriorityVehicle RU_Motorcycle RU_Bicycle RU_Pedestrian RU_Train RU_Taxi

struct LaneSection
    isLaneSection::Bool
    vertLeft::Vector{Pos{FCart}} # vertices on left hand side of vehicle
    vertRght::Vector{Pos{FCart}}
    vertCntr::Vector{Pos{FCart}}
    prec::Set{LaneSectionID}
    succ::Set{LaneSectionID}
    adjLeft::Bool # same driving direction on adjecent left lane? 
    adjRght::Bool
    laneType::LaneType
    lineMarkingType::LineMarkingType
    speedMax::Float64 # m/s
    speedMin::Float64
    speedAdv::Float64
    stopLine::Float64

    # standrad constructor with speed values check
    function LaneSection(
        vertLeft, vertRght, vertCntr, prec, succ, adjLeft, adjRght, laneType, lineMarkingType, speedMax, speedMin, speedAdv, stopLine
    )
        @assert speedMin < min(speedAdv, speedMax) < Inf

        return new(
            true, vertLeft, vertRght, vertCntr, prec, succ, adjLeft, adjRght, laneType, lineMarkingType, speedMax, speedMin, speedAdv, stopLine
        )
    end

    # null constructor
    function LaneSection()
        return new(
            false, Vector{Pos{FCart}}(), Vector{Pos{FCart}}(), Vector{Pos{FCart}}(), Set{LaneSectionID}(), Set{LaneSectionID}(), false, false, LT_Unknown, LM_Unknown, Inf64, 0.0, Inf64, Inf64
        )
    end
end

function LaneSection(
    lanelet_network::Py, 
    mapping::Dict{LaneSectionID, LaneletPyID}, 
    lanelet_id::Integer
)
    # @warn "interface not complete" # TODO complete interface
    lanelet = lanelet_network.find_lanelet_by_id(lanelet_id)

    inv_mapping = Dict((v, k) for (k, v) in mapping)

    vertLeft = [Pos(FCart, x, y) for (x, y) in eachrow(pyconvert(Array, lanelet.left_vertices))]
    vertRght = [Pos(FCart, x, y) for (x, y) in eachrow(pyconvert(Array, lanelet.right_vertices))]
    vertCntr = [Pos(FCart, x, y) for (x, y) in eachrow(pyconvert(Array, lanelet.center_vertices))]

    prec = Set(map(id -> inv_mapping[id], pyconvert(Vector{Int64}, lanelet.predecessor)))
    succ = Set(map(id -> inv_mapping[id], pyconvert(Vector{Int64}, lanelet.successor)))

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

    laneType = LT_Unknown
    lineMarkingType = LM_Unknown

    speedMax = 28.0
    speedMin = -5.0
    speedAdv = Inf64
    stopLine = Inf64

    return LaneSection(
        vertLeft, vertRght, vertCntr, prec, succ, adjLeft, adjRght, laneType, lineMarkingType, speedMax, speedMin, speedAdv, stopLine
    )
end

struct LaneSectionNetwork
    laneSections::DefaultDict{LaneSectionID, LaneSection} # data structure for ScenarioSynthesis.jl
    mapping::Dict{LaneSectionID, LaneletPyID} # mapping back to Python LaneletNetwork
end

function lsn_from_path(path::String)
    @pyexec path => """
    # import 
    from commonroad.common.file_reader import CommonRoadFileReader
    from commonroad.scenario.lanelet import Lanelet

    # read data
    scenario, planning_problem = CommonRoadFileReader(path).open()
    lanelet_network = scenario._lanelet_network

    # additional inits
    section_ids = set()


    lanelet2section_id = {}
    # sort by lanelet id (important, since lane_ids will be named consistently)
    lanelet_ids, lanelets = zip(*lanelet_network._lanelets.items())
    lanelet_ids, lanelets = zip(*sorted(zip(lanelet_ids, lanelets)))

    # going from right to left lanelet
    for lanelet_id, lanelet in zip(lanelet_ids, lanelets):
        if lanelet_id in lanelet2section_id or lanelet.adj_right is not None:
            # ensures starting at right-most lanelet
            continue

        # create new section # was: sec_id = self.generate_lane_section_id()
        if len(section_ids) > 0:
            sec_id = max(section_ids) + 1
        else:
            sec_id = 1

        section_ids.add(sec_id)

        lanelets_tmp = [lanelet]
        next_lanelet: Lanelet = lanelet

        while next_lanelet.adj_left is not None and next_lanelet.adj_left_same_direction:
            next_lanelet = lanelet_network.find_lanelet_by_id(next_lanelet.adj_left)
            lanelets_tmp.append(next_lanelet)

        # self._sections[sec_id] = LaneSection(sec_id, lanelets_tmp)
        lane_id = 0
        for lanelet in lanelets_tmp:
            lane_id += 1
            lanelet2section_id[lanelet.lanelet_id] = (sec_id, lane_id)
    """ => (lanelet2section_id, lanelet_network)

    mapping = Dict{LaneSectionID, LaneletPyID}()
    for (k, v) in lanelet2section_id.items()
        mapping[LaneSectionID(pyconvert(Int64, v[0]), pyconvert(Int64, v[1]))] = pyconvert(Int64, k)
    end

    laneSections = DefaultDict{LaneSectionID, LaneSection}(LaneSection())
    for (k, v) in mapping
        laneSections[k] = LaneSection(lanelet_network, mapping, v)
    end

    lsn = LaneSectionNetwork(laneSections, mapping)

    return lsn
end