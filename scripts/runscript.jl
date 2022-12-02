using ScenarioSynthesis

scene01 = Scene(1, 4.0, 8.0)
scene02 = Scene(2, 2.0, 6.0)

actor01 = Vehicle(1)
actor02 = Vehicle(2; a_min=-2.0)

scenario01 = Scenario([actor01, actor02], [scene01, scene02])

ln = ln_from_path("/home/florian/git/ScenarioSynthesis.jl/example_files/USA_US101-10_5_T-1.xml");
ln = ln_from_path("/home/florian/git/ScenarioSynthesis.jl/example_files/DEU_Cologne-9_6_I-1.cr.xml");

route = Route(LaneletID.([23, 108, 66, 146, 7]), ln)
route.frame.cum_dst[end]