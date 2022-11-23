using ScenarioSynthesis
using BenchmarkTools

scene01 = Scene(1, 4.0, 8.0)
scene02 = Scene(2, 2.0, 6.0)

actor01 = Vehicle(1)
actor02 = Vehicle(2; a_min=-2.0)

scenario01 = Scenario([actor01, actor02], [scene01, scene02])

lsn = LaneSectionNetwork("/home/florian/git/ScenarioSynthesis.jl/example_files/USA_US101-10_5_T-1.xml");

rel1  = Relation(IsBehind, actor01, actor02)

ScenarioSynthesis.is_valid(rel1)

p1 = Pos(FCart, 4.0, 5.0)
p2 = Pos(FCart, 1.0, 1.0)
v = p1-p2
@code_warntype ScenarioSynthesis.distance(p1::Pos{FCart},p2::Pos{FCart})