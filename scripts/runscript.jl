using ScenarioSynthesis
import Plotly.plot

# steps of generating scenarios: 
# 1. load LaneletNetwork
# 2. define Actors (incl. their routes)
# 3. define Scenes containing further specifications / predicates
# 4. build scenario
# 5. synthesis

### load LaneletNetwork
ln = ln_from_path("/home/florian/git/ScenarioSynthesis.jl/example_files/DEU_Cologne-9_6_I-1.cr.xml");
plot_lanelet_network(ln; annotate_id=true)


### define Actors
route1 = Route(LaneletID.([64, 143, 11]), ln)
route2 = Route(LaneletID.([8, 92, 11]), ln)
route3 = Route(LaneletID.([66, 147, 63]), ln)
route4 = Route(LaneletID.([25, 112, 66, 146]), ln)

actor1 = Actor(route1, StateCurv(StateLon(20.0, 10.0, 1.0), StateLat(0.8, -0.2, 0.0)))
actor2 = Actor(route2, StateCurv(StateLon(20.0, 10.0, 1.0), StateLat(0.2, 0.1, 0.0)); a_min=-2.0)
actor3 = Actor(route3, StateCurv(StateLon(20.0, 10.0, 1.0), StateLat(0.8, -0.2, 0.0)))
actor4 = Actor(route4, StateCurv(StateLon(20.0, 10.0, 1.0), StateLat(0.8, -0.2, 0.0)))

actors = ActorsDict([actor1, actor2, actor3, actor4])

### define scenes
scene1 = Scene(4.0, 8.0, Vector{Relation}())
scene2 = Scene(4.0, 8.0, Vector{Relation}())
scene3 = Scene(4.0, 8.0, Vector{Relation}())
scene4 = Scene(4.0, 8.0, Vector{Relation}())
scene5 = Scene(4.0, 8.0, Vector{Relation}())

scenes = ScenesDict([scene1, scene2, scene3, scene4, scene5])

### build scenario
scenario = Scenario(actors, scenes, ln)

### synthesis