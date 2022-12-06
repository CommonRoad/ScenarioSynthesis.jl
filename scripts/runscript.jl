using ScenarioSynthesis
import Plotly.plot

ln = ln_from_path("/home/florian/git/ScenarioSynthesis.jl/example_files/DEU_Cologne-9_6_I-1.cr.xml");

plot_lanelet_network(ln; annotate_id=true)

route1 = Route(LaneletID.([64, 143, 11]), ln)
route2 = Route(LaneletID.([8, 92, 11]), ln)
route3 = Route(LaneletID.([66, 147, 63]), ln)
route4 = Route(LaneletID.([25, 112, 66, 146]), ln)

ref_pos_of_conflicting_routes(route1, route2, ln) # true
ref_pos_of_conflicting_routes(route1, route3, ln) # false
ref_pos_of_conflicting_routes(route1, route4, ln) # false
ref_pos_of_conflicting_routes(route2, route3, ln) # true
ref_pos_of_conflicting_routes(route2, route4, ln) # false
ref_pos_of_conflicting_routes(route3, route4, ln) # true

actor1 = Vehicle(1, route01, StateCurv(StateLon(20.0, 10.0, 1.0), StateLat(0.8, -0.2, 0.0)))
actor2 = Vehicle(2, route02, StateCurv(StateLon(20.0, 10.0, 1.0), StateLat(0.2, 0.1, 0.0)); a_min=-2.0)

LaneletID(route1, 120.24)
LaneletID(actor1)


scene1 = Scene(1, 4.0, 8.0)
scene2 = Scene(2, 2.0, 6.0)

scenario1 = Scenario([actor1, actor2], [scene1, scene2])