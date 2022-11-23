using PyCall

const LaneletID = Int64 # type alias
const SectionID = Int64

struct LaneID
    lon::SectionID
    lat::Int64
end

struct Adjacent
    exists::Bool
    adjacent_id::LaneletID
    same_direction::Bool

    function Adjacent()
        return new(false, -1, false)
    end

    function Adjacent(id::Nothing, dir::Nothing)
        return new(false, -1, false)
    end

    function Adjacent(id::Number, dir::Bool)
        return new(true, id, dir)
    end
end

@enum LineMarking begin
    LM_Dashed
    LM_Solid
    LM_BroadDashed
    LM_BroadSolid
    LM_Unknown
    LM_NoMarking
end

@enum LaneletType begin
    LT_Urban
    LT_Country
    LT_Highway
    LT_DriveWay
    LT_MainCarriageWay
    LT_AccessRamp
    LT_Shoulder
    LT_BusLane
    LT_BusStop
    LT_BicycleLane
    LT_Sidewalk
    LT_Crosswalk
    LT_Interstate
    LT_Intersection
    LT_Border
    LT_Parking
    LT_Restricted
    LT_Unknown
end

struct StopLine
    start::Pos{FCart} # TODO is this correct? or Vetor{Pos{FCart}}?
    stop::Pos{FCart} # TODO is this correct? or Vetor{Pos{FCart}}?
    line_marking::LineMarking
    traffic_sign_ref
    traffic_light_ref
end

@enum RoadUser begin
    RU_Vehicle
    RU_Car
    RU_Truck
    RU_Bus
    RU_PriorityVehicle
    RU_Motorcycle
    RU_Bicycle
    RU_Pedestrian
    RU_Train
    RU_Taxi
end

struct Lanelet 
    # TODO enable conversion of ALL attributes
    left_vertices::Vector{Pos{FCart}}
    center_vertices::Vector{Pos{FCart}}
    right_vertices::Vector{Pos{FCart}}
    id::LaneletID
    predecessors::Vector{LaneletID} # vector of predecessor lanelets' indexes
    successors::Vector{LaneletID} # vector of successor lanelets' indexes
    adj_left::Adjacent
    adj_right::Adjacent
    line_marking_left_vertices::LineMarking
    line_marking_right_vertices::LineMarking
    # stop_line::StopLine
    lanelet_type::LaneletType
    # user_one_way::Vector{RoadUser}
    # user_bidirectional::Vector{RoadUser}
    # traffic_signes
    # traffic_lights

    function Lanelet()
        return new(
            Vector{Pos{FCart}}(),
            Vector{Pos{FCart}}(),
            Vector{Pos{FCart}}(),
            -1,
            Vector{LaneletID}(),
            Vector{LaneletID}(),
            Adjacent(),
            Adjacent(),
            LM_Unknown,
            LM_Unknown,
            LT_Unknown
        )
    end

    function Lanelet(
        left_vertices::Vector{Pos{FCart}},
        center_vertices::Vector{Pos{FCart}},
        right_vertices::Vector{Pos{FCart}},
        id::LaneletID,
        predecessors::Vector{LaneletID}, # vector of predecessor lanelets' indexes
        successors::Vector{LaneletID}, # vector of successor lanelets' indexes
        adj_left::Adjacent,
        adj_right::Adjacent,
        line_marking_left_vertices::LineMarking,
        line_marking_right_vertices::LineMarking,
        # stop_line::StopLine
        lanelet_type::LaneletType
        # user_one_way::Vector{RoadUser}
        # user_bidirectional::Vector{RoadUser}
        # traffic_signes
        # traffic_lights
    )
        return new(
            left_vertices,
            center_vertices,
            right_vertices,
            id,
            predecessors,
            successors,
            adj_left,
            adj_right,
            line_marking_left_vertices,
            line_marking_right_vertices,
            lanelet_type
        )
    end
end


struct LaneletNetwork
    lanelets::Dict{LaneletID, Lanelet}
    # TODO add additional fields
end

#=
function read_lanelet_network(path::String) # read_lanelet_network("/home/florian/git/ScenarioSynthesis.jl/example_files/USA_US101-10_5_T-1.xml")
    py"""
    from commonroad.common.file_reader import CommonRoadFileReader
    def open_scenario(x):
        scenario, planning_problem = CommonRoadFileReader(x).open()
        return scenario
    """
    lanelet_network_py = py"open_scenario"(path)._lanelet_network
    
    lanelets = map(
        lanelet -> Lanelet(
            [Pos(FCart, x, y) for (x,y) in eachrow(lanelet.left_vertices)], # left_vertices::Vector{Pos{FCart}}
            [Pos(FCart, x, y) for (x,y) in eachrow(lanelet.center_vertices)], # center_vertices::Vector{Pos{FCart}}
            [Pos(FCart, x, y) for (x,y) in eachrow(lanelet.right_vertices)], #right_vertices::Vector{Pos{FCart}}
            lanelet.lanelet_id, # lanelet_id::LaneletID
            Vector{LaneletID}(lanelet.predecessor), # predecessor::Vector{LaneletID} # vector of predecessor lanelets' indexes
            Vector{LaneletID}(lanelet.successor), # successor::Vector{LaneletID} # vector of successor lanelets' indexes
            Adjacent(lanelet.adj_left, lanelet.adj_left_same_direction), # adjacent_left::Adjacent
            Adjacent(lanelet.adj_right, lanelet.adj_right_same_direction), # adjacent_right::Adjacent
            LM_Dashed, # line_marking_left_vertices::LineMarking
            LM_Dashed, # line_marking_right_vertices::LineMarking
            # StopLine, # #stop_line::StopLine
            LT_Interstate, # lanelet_type::LaneletType
            # user_one_way::Vector{RoadUser}
            # user_bidirectional::Vector{RoadUser}
            # traffic_signes
            # traffic_lig
        ), 
        lanelet_network_py.lanelets
    )
    
    lanelets_dict = Dict([(lanelet.id, lanelet) for lanelet in lanelets])

    return LaneletNetwork(lanelets_dict)
end
=#

struct Lane
    lane_id::LaneID
    lanelet_ids::Vector{Int64}
    successors::Set{Int64}
    predecessors::Set{Inf64}
    is_main_lane::Bool
    merging_lane_ids::Set{LaneID}
    lanelet::Vector{Lanelet}
    center_line::Vector{Pos{FCart}}
    # cosy::CurvlinCosy # TODO add CurvlinCosy ??
    s_range::Tuple{Float64,Float64}
end

struct LaneSection

end

struct LaneSectionNetwork
    sections::Dict{SectionID,LaneSection}
    lanelet2section_map::Dict{Int64,LaneSection} # TODO suitable representation?
    lanelet_network::LaneletNetwork
    lanelets::Vector{Lanelet}
    params # TODO add type for this
end

function LaneSectionNetwork(path::String)
    py"""
    from commonroad.common.file_reader import CommonRoadFileReader
    import sys
    
    sys.path.append("/home/florian/git/ScenarioSynthesis.jl/")
    
    from src.types.map.python.lanes import LaneSectionNetwork
    from src.types.map.python.scenario_parameters import ScenarioParamsBase
    
    def open_as_lsn(path):
        scenario, planning_problem = CommonRoadFileReader(path).open()
        lsn = LaneSectionNetwork.create_from_lanelet_network(scenario.lanelet_network, ScenarioParamsBase())
        return lsn
    """
    lsn_py = py"open_as_lsn"(path)
    
    isa(lsn_py, LaneSectionNetwork) || @warn "wrong return type!" # TODO type wrapper 
    
    return lsn_py
end

struct Route
    # TODO content
end