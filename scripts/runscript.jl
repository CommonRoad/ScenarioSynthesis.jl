ENV["JULIA_PYTHONCALL_EXE"] = "/home/florian/anaconda3/envs/pycall/bin/python3.10"
using ScenarioSynthesis

scene01 = Scene(1, 4.0, 8.0)
scene02 = Scene(2, 2.0, 6.0)

actor01 = Vehicle(1)
actor02 = Vehicle(2; a_min=-2.0)

scenario01 = Scenario([actor01, actor02], [scene01, scene02])

lsn = lsn_from_path("/home/florian/git/ScenarioSynthesis.jl/example_files/USA_US101-10_5_T-1.xml");