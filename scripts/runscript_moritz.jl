using ScenarioSynthesis
using StaticArrays
using Plots; plotly()

# steps of generating scenarios: 
# 1. load LaneletNetwork
# 2. define Actors (incl. their routes)
# 3. define formal specifications / sequence of Predicates
# 4. synthesis

### load LaneletNetwork
#ln = ln_from_xml("example_files/DEU_Cologne-9_6_I-1.cr.xml");
ln = ln_from_xml("example_files/ZAM_Zip-1_64_T-1.xml");
#ln = ln_from_xml("example_files/ZAM_Tjunction-1_55_T-1.xml");
process!(ln)
plot_lanelet_network(ln; annotate_id=true)


lenwid = SVector{2, Float64}(5.0, 2.2)
### define Actors
route1 = Route(LaneletID.([25, 28, 24]), ln, lenwid); plot_route(route1);
route2 = Route(LaneletID.([25, 26, 27, 24]), ln, lenwid); plot_route(route2);
@warn "TODO -- fix lanlet interval calculation"
route2.lanelet_interval[25] = ScenarioSynthesis.LaneletInterval(0, 100, 0)
route2.lanelet_interval[26] = ScenarioSynthesis.LaneletInterval(80, 165, 80)
route2.lanelet_interval[27] = ScenarioSynthesis.LaneletInterval(160, 180, -2.5)
route2.lanelet_interval[27] = ScenarioSynthesis.LaneletInterval(175, 320, -2.5)
route3 = Route(LaneletID.([26, 27, 24]), ln, lenwid);
route4 = Route(LaneletID.([26, 27, 24]), ln, lenwid);

cs = ConvexSet([
    State(0, 0),
    State(1, 0),
    State(1, 1),
    State(0, 1),
])

actor1 = Actor(route1, cs; a_lb = -4.0, v_lb = 0.0);
actor2 = Actor(route2, cs; a_lb = -2.0, v_lb = 0.0);
actor3 = Actor(route3, cs; a_lb = -2.0, v_lb = 0.0);
actor4 = Actor(route4, cs; a_lb = -2.0, v_lb = 10.0);

actors = ActorsDict([
    actor1,
    actor2,
    actor3,
    actor4
], ln);

scene1 = Scene(
    0.2, 
    0.4, 
    [
        OnLanelet(1, Set(25)),
        OnLanelet(2, Set(25)),
        OnLanelet(3, Set(26)),
        OnLanelet(4, Set(26)),
    ]
)

scene2 = Scene(
    0.1, 
    4.0,
    Vector{Predicate}()
)

scene3 = Scene(
    0.2,
    2.0, 
    [
        OnLanelet(1, Set(25)),
        OnLanelet(2, Set(24)),
        OnLanelet(3, Set(27)),
        OnLanelet(4, Set(26))
    ]
)

scene4 = Scene(
    0.2, 
    0.4, 
    [
        OnLanelet(1, Set(25)),
        OnLanelet(2, Set(24)),
        OnLanelet(3, Set(24)),
        OnLanelet(4, Set(27))
    ]
)

scene5 = Scene(
    0.2,
    0.4,
    [
        OnLanelet(1, Set(24)),
        OnLanelet(2, Set(24)),
        OnLanelet(3, Set(24)),
        OnLanelet(4, Set(24))
    ]
)

scenes = ScenesDict([
    scene1, 
    scene2, 
    scene3, 
    scene2,
    scene4,
    scene2, 
    scene5
]);

scenario = Scenario(actors, scenes, ln);

optimization_problem = synthesize_optimization_problem(scenario, 0.25)

import JuMP

JuMP.optimize!(optimization_problem)

plot(JuMP.value.(optimization_problem.obj_dict[:scene_active]))
plot(JuMP.value.(optimization_problem.obj_dict[:state][:,:,1]); xlabel="step [1]", ylabel="s [m]")
plot(JuMP.value.(optimization_problem.obj_dict[:state][:,:,2]); xlabel="step [1]", ylabel="v [m/s]")
plot(JuMP.value.(optimization_problem.obj_dict[:state][:,:,3]); xlabel="step [1]", ylabel="a [m/s²]")

