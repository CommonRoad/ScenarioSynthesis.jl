from commonroad.common.file_reader import CommonRoadFileReader
from src.types.map.python.lanes import LaneSectionNetwork
from src.types.map.python.scenario_parameters import ScenarioParamsBase


path = "/home/florian/git/ScenarioSynthesis.jl/example_files/USA_US101-10_5_T-1.xml"
scenario, planning_problem = CommonRoadFileReader(path).open()


lsn = LaneSectionNetwork.create_from_lanelet_network(scenario.lanelet_network, ScenarioParamsBase())

type(lsn.lanelet_network.lanelets[10].predecessor[0])

lt = lsn.lanelet_network.lanelets[10]

lt.adj_left.

## qualfieres etc.
LaneSectionNetwork.__qualname__

from src.types.map.python.lanes import LaneID

LaneID.__module__
LaneID.__qualname__

from commonroad.scenario.lanelet import LaneletNetwork

LaneletNetwork.__module__
LaneletNetwork.__qualname__
