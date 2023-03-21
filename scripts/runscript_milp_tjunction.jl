using ScenarioSynthesis
using StaticArrays
using Plots; plotly()
import ScenarioSynthesis.ActorID
using JuMP

# steps of generating scenarios: 
# 1. load LaneletNetwork
# 2. define Actors (incl. their routes)
# 3. define formal specifications / sequence of Predicates
# 4. synthesis

### load LaneletNetwork
#ln = ln_from_xml("example_files/DEU_Cologne-9_6_I-1.cr.xml");
#ln = ln_from_xml("example_files/ZAM_Zip-1_64_T-1.xml");
ln = ln_from_xml("example_files/ZAM_Tjunction-edit.xml");
process!(ln);
plot_lanelet_network(ln; annotate_id=true)


lenwid = SVector{2, Float64}(5.0, 2.2)
### define Actors
route1 = Route(LaneletID.([50195, 50209, 50203]), ln, lenwid); plot_route(route1);
route2 = Route(LaneletID.([50201, 50213, 50197]), ln, lenwid); plot_route(route2);
route3 = Route(LaneletID.([50205, 50217, 50199]), ln, lenwid); plot_route(route3);


cs1 = ConvexSet([
    State(130, 12),
    State(140, 12),
    State(140, 14),
    State(130, 14),
])

cs2 = ConvexSet([
    State(80, 12),
    State(90, 12),
    State(90, 14),
    State(80, 14),
])

cs3 = ConvexSet([
    State(40, 12),
    State(50, 12),
    State(50, 14),
    State(40, 14),
])

cs4 = ConvexSet([
    State(10, 12),
    State(20, 12),
    State(20, 14),
    State(10, 14),
])

cs5 = ConvexSet([
    State(120, 12),
    State(130, 12),
    State(130, 14),
    State(120, 14),
])

cs6 = ConvexSet([
    State(100, 12),
    State(110, 12),
    State(110, 14),
    State(100, 14),
])

actor1 = Actor(route1, cs1);
actor2 = Actor(route1, cs2);
actor3 = Actor(route2, cs3);
actor4 = Actor(route2, cs4);
actor5 = Actor(route3, cs5);
actor6 = Actor(route3, cs6);
 
actors = ActorsDict([actor1, actor2, actor3, actor4, actor5, actor6], ln);

### define formal specifications
scene_free = Scene(
    0.25, 
    1.5,
    [
        BehindActor(2, 1), 
        BehindActor(4, 3),
        BehindActor(6, 5),
    ]
)

scene1 = Scene(
    0.25, 
    1.0, 
    [
        OnLanelet(1, Set(50195)),
        BehindActor(2, 1),
        OnLanelet(3, Set(50201)),
        BehindActor(4, 3),
        OnLanelet(5, Set(50205)),
        BehindActor(6, 5)
    ]
)

scene2 = Scene(
    0.25, 
    1.0, 
    [
       BehindConflictSection(1, 1),
       BeforeConflictSection(2, 2),
       BeforeConflictSection(3, 9),
       BehindActor(4, 3),
       BeforeConflictSection(5, 6),
       BehindActor(6, 5)
    ]
)

scene3 = Scene(
    0.25, 
    1.0, 
    [
        BeforeConflictSection(2, 2),
        BehindConflictSection(3, 8),
        BeforeConflictSection(4, 9),
        BeforeConflictSection(5, 6),
        BehindActor(6, 5)
    ]
)

scene4 = Scene(
    0.25,
    1.0, 
    [
        BeforeConflictSection(2, 2),
        BeforeConflictSection(4, 9),
        BehindConflictSection(5, 5),
        BeforeConflictSection(6, 6)
    ]
)

scene5 = Scene(
    0.25, 
    1.0, 
    [
        BehindConflictSection(2, 1),
        BehindActor(2, 1), 
        BeforeConflictSection(4, 9),
        BeforeConflictSection(6, 6)
    ]
)

scene6 = Scene(
    0.25, 
    1.0, 
    [
        BehindActor(2, 1),
        BehindConflictSection(4, 8),
        BehindActor(4, 3),
        BeforeConflictSection(6, 6)
    ]
)

scene7 = Scene(
    0.25, 
    1.0, 
    [
        BehindActor(2, 1),
        BehindActor(4, 3),
        BehindConflictSection(6, 5), 
        BehindActor(6, 5)
    ]
)

scenes = ScenesDict([
    scene1,
    scene_free, 
    scene2, 
    scene_free, 
    scene3,
    scene_free, 
    scene4,
    scene_free, 
    scene5,
    scene_free, 
    scene6,
    scene_free, 
    scene7,
]);

scenario = Scenario(actors, scenes, ln);

Δt = 0.25
optimization_problem = synthesize_optimization_problem(scenario, Δt)
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

animate_scenario(ln, actors, traj, Δt, k_max; playback_speed=1, filename="milp_tjunction")