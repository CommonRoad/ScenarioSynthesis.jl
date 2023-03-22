using ScenarioSynthesis
using StaticArrays
using Plots; plotly()
using JuMP

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
route2.lanelet_interval[24] = ScenarioSynthesis.LaneletInterval(175, 320, -2.5)
route3 = Route(LaneletID.([26, 27, 24]), ln, lenwid);
route4 = Route(LaneletID.([26, 27, 24]), ln, lenwid);

cs1 = ConvexSet([
    State(110, 12),
    State(114, 12),
    State(114, 20),
    State(110, 20),
])

cs2 = ConvexSet([
    State(50, 20),
    State(58, 20),
    State(58, 28),
    State(50, 28),
])

cs3 = ConvexSet([
    State(50, 16),
    State(55, 16),
    State(55, 20),
    State(50, 20),
])

cs4 = ConvexSet([
    State(40, 16),
    State(45, 16),
    State(45, 24),
    State(40, 24),
])

actor1 = Actor(route1, cs1);
actor2 = Actor(route2, cs2);
actor3 = Actor(route3, cs3);
actor4 = Actor(route4, cs4);

actors = ActorsDict([
    actor1,
    actor2,
    actor3,
    actor4
], ln);

# define formal specifications
scene1 = Scene(
    0.25, 
    2.5, 
    [
        OnLanelet(1, Set(25)),
        OnLanelet(2, Set(25)),
        OnLanelet(3, Set(26)),
        OnLanelet(4, Set(26)),
        BehindActor(2, 1),
        BehindActor(4, 3)
    ]
)

scene2 = Scene(
    0.25, 
    2.5, 
    [
        OnLanelet(1, Set(25)),
        OnLanelet(2, Set(26)),
        OnLanelet(3, Set(26)),
        OnLanelet(4, Set(26)),
        BehindActor(3, 2),
        BehindActor(4, 3),
    ]
)

scene3 = Scene(
    0.25,
    2.5,
    [
        OnLanelet(1, Set(25)),
        OnLanelet(2, Set(27)),
        OnLanelet(3, Set(26)),
        OnLanelet(4, Set(26)),
        BehindActor(3, 2),
        BehindActor(4, 3)
    ]
)

scene4a = Scene(
    0.25, 
    2.5, 
    [
        OnLanelet(1, Set(25)),
        OnLanelet(2, Set(27)),
        OnLanelet(3, Set(27)),
        OnLanelet(4, Set(26)),
        BehindActor(3, 2),
        BehindActor(4, 3)
    ]
)

scene4b = Scene(
    0.25, 
    2.5, 
    [
        OnLanelet(1, Set(25)),
        OnLanelet(2, Set(24)),
        OnLanelet(3, Set(26)),
        OnLanelet(4, Set(26)),
        BehindActor(3, 2),
        BehindActor(4, 3)
    ]
)

scene5 = Scene(
    0.25, 
    2.5, 
    [
        OnLanelet(1, Set(25)),
        OnLanelet(2, Set(24)),
        OnLanelet(3, Set(27)),
        OnLanelet(4, Set(26)),
        BehindActor(3, 2),
        BehindActor(4, 3)
    ]
)

scene6 = Scene(
    0.25, 
    2.5, 
    [
        OnLanelet(1, Set(25)),
        OnLanelet(2, Set(24)),
        OnLanelet(3, Set(24)),
        OnLanelet(4, Set(26)),
        BehindActor(3, 2),
        BehindActor(4, 3),
        BehindActor(4, 1)
    ]
)

scene7 = Scene(
    0.25, 
    2.5, 
    [
        OnLanelet(1, Set(28)),
        OnLanelet(2, Set(24)),
        OnLanelet(3, Set(24)),
        OnLanelet(4, Set(26)),
        BehindActor(3, 2),
        BehindActor(4, 3),
        BehindActor(4, 1)
    ]
)

scene8a = Scene(
    0.25, 
    2.5, 
    [
        OnLanelet(1, Set(24)),
        OnLanelet(2, Set(24)),
        OnLanelet(3, Set(24)),
        OnLanelet(4, Set(26)),
        BehindActor(3, 2),
        BehindActor(4, 3),
        BehindActor(4, 1)
    ]
)

scene8b = Scene(
    0.25, 
    2.5, 
    [
        OnLanelet(1, Set(28)),
        OnLanelet(2, Set(24)),
        OnLanelet(3, Set(24)),
        OnLanelet(4, Set(27)),
        BehindActor(3, 2),
        BehindActor(4, 3),
        BehindActor(4, 1)
    ]
)

scene9 = Scene(
    0.25, 
    2.5, 
    [
        OnLanelet(1, Set(24)),
        OnLanelet(2, Set(24)),
        OnLanelet(3, Set(24)),
        OnLanelet(4, Set(27)),
        BehindActor(3, 2),
        BehindActor(4, 3),
        BehindActor(4, 1),
        SlowerActor(4, 1),
        SlowerActor(2, 4),
        #SlowerActor(3, 2)
    ]
)

scenes = ScenesDict([
    scene1, 
    scene2, 
    scene3, 
    #scene4a,
    #scene4b,
    scene5,
    scene6,
    scene7,
    #scene8a,
    #scene8b, 
    scene9
]);

scenario = Scenario(actors, scenes, ln);

Δt = 0.25
optimization_problem = synthesize_optimization_problem(scenario, Δt); 
JuMP.optimize!(optimization_problem)

last_scene_activated_at = findfirst(x -> x>0, JuMP.value.(optimization_problem.obj_dict[:scene_active])[:, end])
last_scene_duration = findlast(x -> x>0, JuMP.value.(optimization_problem.obj_dict[:scene_active])[last_scene_activated_at:end, end])
k_max = last_scene_activated_at + last_scene_duration - 1

plot(JuMP.value.(optimization_problem.obj_dict[:scene_active][1:k_max, :]))
plot(JuMP.value.(optimization_problem.obj_dict[:state][:,:,1][1:k_max, :]); xlabel="step [1]", ylabel="s [m]")
plot(JuMP.value.(optimization_problem.obj_dict[:state][:,:,2][1:k_max, :]); xlabel="step [1]", ylabel="v [m/s]")
plot(JuMP.value.(optimization_problem.obj_dict[:state][:,:,3][1:k_max, :]); xlabel="step [1]", ylabel="a [m/s²]")

traj = Dict{ActorID, Trajectory}()
for (actor_id, actor) in actors.actors
    traj[actor_id] = Trajectory(Vector{State}(undef, k_max))
    counter = 0
    for val in eachrow(JuMP.value.(optimization_problem.obj_dict[:state][:,actor_id,1:2])[1:k_max,:])
        counter += 1
        traj[actor_id][counter] = State(val[1], val[2])
    end
end

animate_scenario(ln, actors, traj, Δt, k_max; playback_speed=1, filename="milp_zip")