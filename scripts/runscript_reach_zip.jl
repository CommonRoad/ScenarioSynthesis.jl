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

actor1 = Actor(route1, cs1; a_lb = -4.0, v_lb = 0.0);
actor2 = Actor(route2, cs2; a_lb = -2.0, v_lb = 0.0);
actor3 = Actor(route3, cs3; a_lb = -2.0, v_lb = 0.0);
actor4 = Actor(route4, cs4; a_lb = -2.0, v_lb = 10.0);
 
#actors = ActorsDict([actor1, actor2, actor3, actor4], ln);
actors = ActorsDict([actor1, actor2, actor3, actor4], ln);

actors.offset # TODO why no offset for actors 1 & 3??

A = SMatrix{2, 2, Float64, 4}(0, 0, 1, 0) # add as default to propagate functions? 

### define formal specifications
Δt = 0.25
k_max = 35 # → scene duration: Δt * (k_max - 1) = 4 sec

empty_set = Set{Predicate}()
pred1 = VelocityLimits(1); pred2 = VelocityLimits(2); pred3 = VelocityLimits(3); pred4 = VelocityLimits(4); pred5 = BehindActor(4, 3);
pred6 = BehindActor(2, 1);
pred7 = BehindActor(3, 2); pred8 = BehindActor(1, 3); pred9 = BehindActor(4, 1);
pred10 = OnLanelet(1, Set([24]));
pred11 = SlowerActor(2, 4);

ψ = 0.5

spec = Vector{Set{Predicate}}(undef, k_max)
for i=1:k_max
    spec[i] = copy(empty_set)
    push!(spec[i], pred1)
    push!(spec[i], pred2)
    push!(spec[i], pred3)
    push!(spec[i], pred4)
    push!(spec[i], pred5)
end
for i=1:5
    push!(spec[i], pred6)
end
for i=k_max-10:k_max
    push!(spec[i], pred7)
    push!(spec[i], pred8)
    push!(spec[i], pred9)
end
for i=k_max-5:k_max
    push!(spec[i], pred10)
    push!(spec[i], pred11)
end

push!(spec[k_max], SlowerActor(4, 1))
push!(spec[k_max], SlowerActor(3, 2))
#push!(spec[k_max], SlowerActor(4, 1))

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
        @info actor_id, i
        backward = propagate_backward(actor.states[i+1], A, actor.a_ub, actor.a_lb, Δt)
        intersect = ScenarioSynthesis.intersection(actor.states[i], backward) 
        actor.states[i] = intersect
    end
end

# plot
plot();
for i=1:10:length(actor1.states)
    plot!(plot_data(actor1.states[i]); color=:blue); 
    plot!(plot_data(actor2.states[i] + State(actors.offset[2, 1], 0)); color=:green); 
    plot!(plot_data(actor3.states[i] + State(actors.offset[3, 1], 0)); color=:orange);
    plot!(plot_data(actor4.states[i] + State(actors.offset[4, 1], 0)); color=:brown);
end
plot!(; xlabel = "s", ylabel = "v")

traj = synthesize_trajectories(actors, k_max, Δt; relax=2.0)

plot(hcat(traj[1]...)[1,:], hcat(traj[1]...)[2,:]);
plot!(hcat(traj[2]...)[1,:], hcat(traj[2]...)[2,:]);
plot!(hcat(traj[3]...)[1,:], hcat(traj[3]...)[2,:]);
plot!(hcat(traj[4]...)[1,:], hcat(traj[4]...)[2,:]); @warn "not offset-corrected"
plot!(; xlabel = "s", ylabel = "v")

animate_scenario(ln, actors, traj, Δt, k_max; playback_speed=1, filename="reach_zip")

function foo(spec, actors_input, ψ)
    actors = deepcopy(actors_input)
    for i = 1:k_max
        # @info i
        # restrict convex set to match specifications
        for pred in sort([spec[i]...], lt=type_ranking)
            # @info pred
            apply_predicate!(pred, actors, i, ψ)
            #bounds = Bounds(pred, actors, i, ψ) # TODO first apply static constraints, subseqeuntly dynamic ones (ordering can influence result)
            #apply_bounds!(actors.actors[pred.actor_ego].states[i], bounds)
        end
    
        # propagate convex set to get next time step
        for (actor_id, actor) in actors.actors
            @assert length(actor.states) == i 
            prop = propagate(actor.states[i], A, actor.a_ub, actor.a_lb, Δt)
            push!(actor.states, prop)
        end
    end

    for (actor_id, actor) in actors.actors
        for i in reverse(1:k_max-1)
            #@info actor_id, i
            backward = propagate_backward(actor.states[i+1], A, actor.a_ub, actor.a_lb, Δt)
            intersect = ScenarioSynthesis.intersection(actor.states[i], backward) 
            actor.states[i] = intersect
        end
    end

    traj = synthesize_trajectories(actors, k_max, Δt; relax=2.0)

    return nothing
end

actors_input = deepcopy(actors);

using BenchmarkTools
foo(spec, actors_input, 0.5)

@profview for i=1:10
    foo(spec, actors_input, 0.5)
end

@benchmark foo(spec, actors_input, 0.5)