using ScenarioSynthesis
using StaticArrays
using Plots; plotly()

# steps of generating scenarios: 
# 1. load LaneletNetwork
# 2. define Actors (incl. their routes)
# 3. define fornal specifications / sequence of Predicates
# 4. synthesis

### load LaneletNetwork
ln = ln_from_xml("example_files/DEU_Cologne-9_6_I-1.cr.xml");
process!(ln)
# plot_lanelet_network(ln; annotate_id=true)

lenwid = SVector{2, Float64}(5.0, 2.2)
### define Actors
route0 = Route(LaneletID.([64]), ln, lenwid);
route1 = Route(LaneletID.([64, 143, 11]), ln, lenwid);
route2 = Route(LaneletID.([8, 92, 11]), ln, lenwid);
route3 = Route(LaneletID.([66, 147, 63]), ln, lenwid);
route4 = Route(LaneletID.([25, 112, 66, 146, 7]), ln, lenwid);

reference_pos(route2, route3, ln)

cs1 = ConvexSet([
    State(105, 12),
    State(110, 12),
    State(110, 15),
    State(105, 15),
])

cs2 = ConvexSet([
    State(100, 12),
    State(140, 12),
    State(140, 15),
    State(100, 15),
])

actor1 = Actor(route1, cs1; a_lb = -2.0, v_lb = 0.0);
actor2 = Actor(route2, cs2; a_lb = -1.0, v_lb = 0.0);
# actor3 = Actor(route3, cs);
# actor4 = Actor(route4, cs);
 
#actors = ActorsDict([actor1, actor2, actor3, actor4], ln);
actors = ActorsDict([actor1, actor2], ln);

actors.offset

A = SMatrix{2, 2, Float64, 4}(0, 0, 1, 0) # add as default to propagate functions? 

### define formal specifications
Δt = 0.2
k_max = 21 # → scene duration: Δt * (k_max - 1) = 4 sec

empty_set = Set{Predicate}()
pred1 = BehindActor(2, 1)
pred2 = OnLanelet(1, Set([143]))
pred3 = SlowerActor(1, 2)
pred4 = VelocityLimits(1); pred5 = VelocityLimits(2)

ψ = 0.99

spec = Vector{Set{Predicate}}(undef, k_max)
for i=1:k_max
    spec[i] = copy(empty_set)
    push!(spec[i], pred1)
    push!(spec[i], pred4)
    push!(spec[i], pred5)
end
for i=8:12
    push!(spec[i], pred2)
end
for i=15:k_max
    push!(spec[i], pred3)
end

for i = 1:k_max
    @info i
    # restrict convex set to match specifications
    for pred in spec[i]
        bounds = Bounds(pred, actors, i, ψ) # TODO first apply static constraints, subseqeuntly dynamic ones (ordering can influence result)
        apply_bounds!(actors.actors[pred.actor_ego].states[i], bounds)
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
plot();
for i=1:k_max
    plot!(actor1.states[i]); plot!(actor2.states[i] + State(actors.offset[2, 1], 0))
end
plot!(; xlabel = "s", ylabel = "v")

traj = synthesize_trajectories(actors, k_max, Δt)

plot(hcat(traj[1]...)[1,:], hcat(traj[1]...)[2,:])
plot!(hcat(traj[2]...)[1,:], hcat(traj[2]...)[2,:])

animate_scenario(ln, actors, traj, Δt, k_max; playback_speed=1)

### corner cutting # TODO move to tests
using BenchmarkTools
using Plots
ls = [Pos(FCart, 2*i, 4*sin(i)) for i=1:20]
@benchmark corner_cutting($ls, 1)

ls = [Pos(FCart, 2*i, 4*sin(i)) for i=1:20]
ls = corner_cutting(ls, 1)
plot(hcat(ls...)'[:,1], hcat(ls...)'[:,2])