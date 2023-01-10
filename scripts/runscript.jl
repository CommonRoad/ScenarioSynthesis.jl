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
plot_lanelet_network(ln; annotate_id=true)


### define Actors
route0 = Route(LaneletID.([64]), ln);
route1 = Route(LaneletID.([64, 143, 11]), ln);
route2 = Route(LaneletID.([8, 92, 11]), ln);
route3 = Route(LaneletID.([66, 147, 63]), ln);
route4 = Route(LaneletID.([25, 112, 66, 146]), ln);

reference_pos(route2, route3, ln)

actor1 = Actor(route1);
actor2 = Actor(route2; a_min=-2.0);
actor3 = Actor(route3);
actor4 = Actor(route4);
 
actors = ActorsDict([actor1, actor2, actor3, actor4]);

### define scenes
rel1 = [Predicate(LaneletRel(SameLon), 1, [64, 143])] #, Relation(IsOnLanelet, 2, 8), Relation(IsOnLanelet, 3, 66), Relation(IsBehind, 4, 3)];
rel2 = [Predicate(ActorRel(Behind), 4, 3), Predicate(ActorRel(Behind), 3, 147)];
rel3 = [Predicate(ActorRel(Behind), 4, 3), Predicate(LaneletRel(SameLon), 1, [11])];

scene1 = Scene(4.0, 8.0, rel1);
scene2 = Scene(4.0, 8.0, rel2);
scene3 = Scene(4.0, 8.0, rel3);

scenes = ScenesDict([scene1, scene2, scene3]);

### build scenario
scenario = Scenario(actors, scenes, ln);

### synthesis
op = synthesize_optimization_problem(scenario)

### optimization
import JuMP
import Plots

solve_optimization_problem!(op)
JuMP.optimize!(op)

Plots.plot(JuMP.value.(op.obj_dict[:scene_active]))
Plots.plot(JuMP.value.(op.obj_dict[:in_cs]))
Plots.plot(JuMP.value.(op.obj_dict[:state][:,:,1]); xlabel="step [1]", ylabel="s [m]")
Plots.plot(JuMP.value.(op.obj_dict[:state][:,:,2]); xlabel="step [1]", ylabel="v [m/s]")
Plots.plot(JuMP.value.(op.obj_dict[:state][:,:,3]); xlabel="step [1]", ylabel="a [m/s²]")
Plots.plot(JuMP.value.(op.obj_dict[:jerk]); xlabel="step [1]", ylabel="j [m/s³]") 

### corner cutting
using BenchmarkTools
using Plots
ls = [Pos(FCart, 2*i, 4*sin(i)) for i=1:20]
@benchmark corner_cutting($ls, 1)

ls = [Pos(FCart, 2*i, 4*sin(i)) for i=1:20]
ls = corner_cutting(ls, 1)
plot(hcat(ls...)'[:,1], hcat(ls...)'[:,2])