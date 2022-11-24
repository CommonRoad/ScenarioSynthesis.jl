ENV["JULIA_PYTHONCALL_EXE"] = "/home/florian/anaconda3/envs/pycall/bin/python3.10"
using ScenarioSynthesis
using PythonCall
#import ScenarioSynthesis.pyconvert_lanelet_network
#import PythonCall.pyconvert
#import PythonCall.pyconvert_add_rule

scene01 = Scene(1, 4.0, 8.0)
scene02 = Scene(2, 2.0, 6.0)

actor01 = Vehicle(1)
actor02 = Vehicle(2; a_min=-2.0)

scenario01 = Scenario([actor01, actor02], [scene01, scene02])

lsn = LaneSectionNetwork("/home/florian/git/ScenarioSynthesis.jl/example_files/USA_US101-10_5_T-1.xml");

for rule in keys(PythonCall.PYCONVERT_RULES)
    println(rule)
end

PythonCall.PYCONVERT_RULES["src.types.map.python.lanes:LaneID"]
PythonCall.PYCONVERT_RULES["src.types.map.python.lanes:LaneSectionNetwork"]

PythonCall.pyconvert_add_rule(
    "src.types.map.python.lanes:LaneID",
    ScenarioSynthesis.LaneID,
    ScenarioSynthesis.pyconvert_lane_id,
    PythonCall.PYCONVERT_PRIORITY_NORMAL
)

pyconvert(ScenarioSynthesis.LaneID, lsn.lanelet_network.lanelets[10].predecessor[0])

ScenarioSynthesis.pyconvert_lane_id(ScenarioSynthesis.LaneID, lsn.lanelet_network.lanelets[10].predecessor[0])

ln = pyconvert(LaneletNetwork, lsn.lanelet_network)

ScenarioSynthesis.pyconvert_lanelet_network(lsn.lanelet_network)

rel1  = Relation(IsBehind, actor01, actor02)

ScenarioSynthesis.is_valid(rel1)

p1 = Pos(FCart, 4.0, 5.0)
p2 = Pos(FCart, 1.0, 1.0)
v = p1-p2
@code_warntype ScenarioSynthesis.distance(p1::Pos{FCart},p2::Pos{FCart})