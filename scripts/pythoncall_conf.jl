#=
1. Create a Python environment with Conda (not the Julia package!)
2. Install necessary dependencies in that env: 'pip install commonroad-io'
3. Set Julia Pythoncall path: e.g., 'ENV["JULIA_PYTHONCALL_EXE"] = "/home/florian/anaconda3/envs/pycall/bin/python3.10"'
    a: execute command above manually, or
    b: add this entry to ~/.julia/config/startup.jl
4. Now, everything should work. Test by executing the code below. 
=#
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

scenario, planning_problem = CommonRoadFileReader(path).open()
""" => scenario