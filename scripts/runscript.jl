using ScenarioSynthesis
using StaticArrays
using Plots; plotly()
using BenchmarkTools

# steps of generating scenarios: 
# 1. load LaneletNetwork
# 2. define Actors (incl. their routes)
# 3. define fornal specifications / sequence of Predicates
# 4. synthesis

### load LaneletNetwork
#ln = ln_from_xml("example_files/DEU_Cologne-9_6_I-1.cr.xml");
#ln = ln_from_xml("example_files/ZAM_Zip-1_64_T-1.xml");
ln = ln_from_xml("example_files/ZAM_Tjunction-edit.xml");
process!(ln)
plot_lanelet_network(ln; annotate_id=true)


lenwid = SVector{2, Float64}(5.0, 2.2)
### define Actors
route1 = Route(LaneletID.([50195, 50209, 50203]), ln, lenwid); plot_route(route1)
route2 = Route(LaneletID.([50201, 50213, 50197]), ln, lenwid); plot_route(route2)
route3 = Route(LaneletID.([50205, 50217, 50199]), ln, lenwid); plot_route(route3)


cs1 = ConvexSet([
    State(120, 12),
    State(130, 12),
    State(130, 14),
    State(120, 14),
])

cs2 = ConvexSet([
    State(110, 12),
    State(120, 12),
    State(120, 14),
    State(110, 14),
])

cs3 = ConvexSet([
    State(20, 12),
    State(60, 12),
    State(60, 14),
    State(20, 14),
])

cs4 = ConvexSet([
    State(25, 12),
    State(40, 12),
    State(40, 14),
    State(25, 14),
])

cs5 = ConvexSet([
    State(140, 12),
    State(150, 12),
    State(150, 14),
    State(140, 14),
])

cs6 = ConvexSet([
    State(120, 12),
    State(130, 12),
    State(130, 14),
    State(120, 14),
])

actor1 = Actor(route1, cs1; a_lb = -4.0, v_lb = 0.0);
actor2 = Actor(route1, cs2; a_lb = -4.0, v_lb = 0.0);
actor3 = Actor(route2, cs3; a_lb = -4.0, v_lb = 0.0);
actor4 = Actor(route2, cs4; a_lb = -4.0, v_lb = 0.0);
actor5 = Actor(route3, cs5; a_lb = -4.0, v_lb = 0.0);
actor6 = Actor(route3, cs6; a_lb = -4.0, v_lb = 0.0);
 
actors = ActorsDict([actor1, actor2, actor3, actor4, actor5, actor6], ln);

actors.offset

A = SMatrix{2, 2, Float64, 4}(0, 0, 1, 0) # add as default to propagate functions? 

### define formal specifications
Δt = 0.25
k_max = 35 # → scene duration: Δt * (k_max - 1) = 4 sec

empty_set = Set{Predicate}()

ψ = 0.5

spec = Vector{Set{Predicate}}(undef, k_max)
for i=1:k_max
    spec[i] = copy(empty_set)
    push!(spec[i], BehindActor(2, 1))
    push!(spec[i], BehindActor(4, 3))
    push!(spec[i], BehindActor(6, 5))
    push!(spec[i], VelocityLimits(1))
    push!(spec[i], VelocityLimits(1))
    push!(spec[i], VelocityLimits(2))
    push!(spec[i], VelocityLimits(3))
    push!(spec[i], VelocityLimits(4))
    push!(spec[i], VelocityLimits(5))
    push!(spec[i], VelocityLimits(6))
    push!(spec[i], SlowerActor(1, 2))
    push!(spec[i], SlowerActor(3, 4))
    push!(spec[i], SlowerActor(5, 6))
    #push!(spec[i], BehindActor(3, 1))
    #push!(spec[i], BehindActor(5, 3))
end

push!(spec[15], BehindConflictSection(1, 1))
push!(spec[15], BeforeConflictSection(2, 2))
push!(spec[15], BeforeConflictSection(3, 9))
push!(spec[15], BeforeConflictSection(5, 6))

push!(spec[35], BehindConflictSection(3, 8))
push!(spec[35], BeforeConflictSection(2, 2))
push!(spec[35], BeforeConflictSection(5, 6))

for i = 1:k_max
    @info i
    # restrict convex set to match specifications
    for pred in sort([spec[i]...], lt=type_ranking)
        @info pred
        apply_predicate!(pred, actors, i, ψ)
        #bounds = Bounds(pred, actors, i, ψ) # TODO first apply static constraints, subseqeuntly dynamic ones (ordering can influence result)
        #apply_bounds!(actors.actors[pred.actor_ego].states[i], bounds)
    end

    # propagate convex set to get next time step
    for (actor_id, actor) in actors.actors
        @assert length(actor.states) == i 
        push!(actor.states, propagate(actor.states[i], A, actor.a_ub, actor.a_lb, Δt))
    end
end

#=
if !@isdefined actor1_states_copy
    actor1_states_copy = deepcopy(actor1.states)
end 
if !@isdefined actor2_states_copy
    actor2_states_copy = deepcopy(actor2.states)
end

if true # true to reload states
    actor1.states[:] = deepcopy.(actor1_states_copy)
    actor2.states[:] = deepcopy.(actor2_states_copy)
end
=#

# backwards propagate reachable sets and intersect with forward propagated ones to tighten convex sets
for (actor_id, actor) in actors.actors
    for i in reverse(1:k_max-1)
        backward = propagate_backward(actor.states[i+1], A, actor.a_ub, actor.a_lb, Δt)
        intersect = ScenarioSynthesis.intersection(actor.states[i], backward) 
        actor.states[i] = intersect
    end
end

# plot
plot(); colors = palette(:tab10);
for i=1:10:length(actor1.states)
    plot!(plot_data(actor1.states[i]); color=colors[1]); 
    plot!(plot_data(actor2.states[i] + State(actors.offset[2, 1], 0)); color=colors[2]); 
    plot!(plot_data(actor3.states[i] + State(actors.offset[3, 1], 0)); color=colors[3]);
    plot!(plot_data(actor4.states[i] + State(actors.offset[4, 1], 0)); color=colors[4]);
    plot!(plot_data(actor5.states[i] + State(actors.offset[5, 1], 0)); color=colors[5]);
    plot!(plot_data(actor6.states[i] + State(actors.offset[6, 1], 0)); color=colors[6]);
end
plot!(; xlabel = "s", ylabel = "v")

traj = synthesize_trajectories(actors, k_max, Δt; relax=3.0)

plot(hcat(traj[1]...)[1,:], hcat(traj[1]...)[2,:]);
plot!(hcat(traj[2]...)[1,:], hcat(traj[2]...)[2,:]);
plot!(hcat(traj[3]...)[1,:], hcat(traj[3]...)[2,:]);
plot!(hcat(traj[4]...)[1,:], hcat(traj[4]...)[2,:]);
plot!(hcat(traj[5]...)[1,:], hcat(traj[5]...)[2,:]);
plot!(hcat(traj[6]...)[1,:], hcat(traj[6]...)[2,:]); @warn "not offset-corrected"
plot!(; xlabel = "s", ylabel = "v")

animate_scenario(ln, actors, traj, Δt, k_max; playback_speed=1)



cs = ConvexSet(vertices, false, false)
plot(cs)

### corner cutting # TODO move to tests
using BenchmarkTools
using Plots
ls = [Pos(FCart, 2*i, 4*sin(i)) for i=1:20]
@benchmark corner_cutting($ls, 1)

ls = [Pos(FCart, 2*i, 4*sin(i)) for i=1:20]
ls = corner_cutting(ls, 1)
plot(hcat(ls...)'[:,1], hcat(ls...)'[:,2])

### MTL
using ScenarioSynthesis

pred1 = OnLanelet(1, Set([143]))
pred2 = OnConflictSection(1, 75)
pred3 = BehindActor(1, 2)
pred4 = SlowerActor(1, 2)

mtl = MTLPredicate(
    Globally, 
    Absolute, 
    And, 
    UnitRange(1, 4), [
        MTLPredicate(
            Globally,
            Relative,
            And,
            UnitRange(2, 7), [
                pred1,
                pred2
            ]
        ), 
        pred3,
    ])

result = mtl2config(mtl, 10)