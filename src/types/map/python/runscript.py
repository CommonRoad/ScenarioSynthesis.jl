from commonroad.common.file_reader import CommonRoadFileReader
from src.types.map.python.lanes import LaneSectionNetwork
from src.types.map.python.scenario_parameters import ScenarioParamsBase
import src.types.map.python.util

def open_scenario(x):
    scenario, planning_problem = CommonRoadFileReader(x).open()
    return scenario

scenario_py = open_scenario("/home/florian/git/ScenarioSynthesis.jl/example_files/USA_US101-10_5_T-1.xml")

lsn = LaneSectionNetwork.create_from_lanelet_network(scenario_py.lanelet_network, ScenarioParamsBase())

