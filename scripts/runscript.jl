using ScenarioSynthesis

# steps of generating scenarios: 
# 1. load LaneletNetwork
# 2. define Actors (incl. their routes)
# 3. define Scenes containing further specifications / predicates
# 4. build scenario
# 5. synthesis

### load LaneletNetwork
ln = ln_from_xml("example_files/DEU_Cologne-9_6_I-1.cr.xml");
process!(ln)
# plot_lanelet_network(ln; annotate_id=true)


### define Actors
route0 = Route(LaneletID.([64]), ln)
route1 = Route(LaneletID.([64, 143, 11]), ln)
route2 = Route(LaneletID.([8, 92, 11]), ln)
route3 = Route(LaneletID.([66, 147, 63]), ln)
route4 = Route(LaneletID.([25, 112, 66, 146]), ln)

actor1 = Actor(route1)
actor2 = Actor(route2; a_min=-2.0)
actor3 = Actor(route3)
actor4 = Actor(route4)

actors = ActorsDict([actor1, actor2, actor3, actor4]);

### define scenes
rel1 = [Relation(IsOnLanelet, 1, 64), Relation(IsOnLanelet, 2, 8), Relation(IsOnLanelet, 3, 66), Relation(IsBehind, 4, 3)]
rel2 = [Relation(IsBehind, 4, 3)]
rel3 = [Relation(IsBehind, 4, 3)]
rel4 = [Relation(IsBehind, 4, 3)]
rel5 = [Relation(IsBehind, 4, 3)]

scene1 = Scene(4.0, 8.0, rel1)
scene2 = Scene(4.0, 8.0, rel2)
scene3 = Scene(4.0, 8.0, rel3)
scene4 = Scene(4.0, 8.0, rel4)
scene5 = Scene(4.0, 8.0, rel5)

scenes = ScenesDict([scene1, scene2, scene3, scene4, scene5]);

### build scenario
scenario = Scenario(actors, scenes, ln);


### testing relations
using BenchmarkTools
is_valid(rel1[1], scenario, StateCurv(20.0, 0, 0, 1.0, 0, 0))
is_valid(Relation(IsRoutesMerge, 1, 2), scenario)
is_valid(Relation(IsInFront, 1, 2), scenario, StateCurv(120.0, 0, 0, 0, 0, 0), StateCurv(20.0, 0, 0, 0, 0, 0))
is_valid(Relation(IsOnSameLaneSection, 1, 2), scenario, StateCurv(140.0, 0, 0, 0, 0, 0), StateCurv(190.0, 0, 0, 0, 0, 0))
is_valid(Relation(IsFaster, 1, 2), scenario, StateCurv(0.0, 20.0, 0, 0, 0, 0), StateCurv(0.0, 18.0, 0, 0, 0, 0))

### synthesis



### misc
st = StateCurv(StateLon(0.0, 0.0, 0.0), StateLat(0.0, 0.0, 0.0))
st = run_timestep(
    st,
    JerkInput(3.0, 0.0),
    1.0
)

st = run_timestep(
    st, 
    AccInput(3.0, 0.0), 
    1.0
)


ln = ln_from_xml("example_files/DEU_Cologne-9_6_I-1.cr.xml")

###
using LightXML

file = parse_file("example_files/DEU_Cologne-9_6_I-1.cr.xml")
xmlroot = root(file)
xml_lanelet = xmlroot["lanelet"]


xmlintersection = xmlroot["intersection"]

content(lt["leftBound"][1]["point"][1]["x"][1]) #["x"][1]
