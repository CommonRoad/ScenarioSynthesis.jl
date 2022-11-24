ENV["JULIA_PYTHONCALL_EXE"] = "/home/florian/anaconda3/envs/pycall/bin/python3.10"
using PythonCall


@pyexec """
print("PythonCall")

import sys
from pprint import pprint

pprint(sys.path)

import commonroad

print(type({'a':1, 'b':2}))
"""


#### Example Code ####
path = "/home/florian/git/ScenarioSynthesis.jl/example_files/USA_US101-10_5_T-1.xml"

@pyexec path => """
from commonroad.common.file_reader import CommonRoadFileReader
import sys

sys.path.append("/home/florian/git/ScenarioSynthesis.jl/")

from src.types.map.python.lanes import LaneSectionNetwork
from src.types.map.python.scenario_parameters import ScenarioParamsBase

scenario, planning_problem = CommonRoadFileReader(path).open()
lsn = LaneSectionNetwork.create_from_lanelet_network(scenario.lanelet_network, ScenarioParamsBase())
print(lsn)
""" => lsn