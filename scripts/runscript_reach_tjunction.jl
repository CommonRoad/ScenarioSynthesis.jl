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
#ln = ln_from_xml("example_files/ZAM_Zip-1_64_T-1.xml");
ln = ln_from_xml("example_files/ZAM_Tjunction-edit.xml");
process!(ln);
plot_lanelet_network(ln; annotate_id=true);


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

A = SMatrix{2, 2, Float64, 4}(0, 0, 1, 0) # add as default to propagate functions? 

### define formal specifications
Δt = 0.25
k_max = 49 # → scene duration: Δt * (k_max - 1) = 10 sec

empty_set = Set{Predicate}()

ψ = 0.5

spec = Vector{Set{Predicate}}(undef, k_max);
for i=1:k_max
    spec[i] = copy(empty_set)
    #push!(spec[i], StateLimits(1))
    #push!(spec[i], StateLimits(2))
    #push!(spec[i], StateLimits(3))
    #push!(spec[i], StateLimits(4))
    #push!(spec[i], StateLimits(5))
    #push!(spec[i], StateLimits(6))
    push!(spec[i], VelocityLimits(1))
    push!(spec[i], VelocityLimits(2))
    push!(spec[i], VelocityLimits(3))
    push!(spec[i], VelocityLimits(4))
    push!(spec[i], VelocityLimits(5))
    push!(spec[i], VelocityLimits(6))
    push!(spec[i], BehindActor([2, 1]))
    push!(spec[i], BehindActor([4, 3]))
    push!(spec[i], BehindActor([6, 5]))
end

begin i=1
    push!(spec[i], BeforeConflictSection(1, 50233));
    push!(spec[i], BeforeConflictSection(2, 50233));
    push!(spec[i], BeforeConflictSection(3, 50233));
    push!(spec[i], BeforeConflictSection(4, 50233));
    push!(spec[i], BeforeConflictSection(5, 50233));
    push!(spec[i], BeforeConflictSection(6, 50233));
end

begin i=9
    push!(spec[i], BehindConflictSection(1, 50233));
    push!(spec[i], BeforeConflictSection(2, 50233));
    push!(spec[i], BeforeConflictSection(3, 50233));
    push!(spec[i], BeforeConflictSection(4, 50233));
    push!(spec[i], BeforeConflictSection(5, 50233));
    push!(spec[i], BeforeConflictSection(6, 50233));
end

begin i=17
    push!(spec[i], BehindConflictSection(1, 50233));
    push!(spec[i], BeforeConflictSection(2, 50233));
    push!(spec[i], BehindConflictSection(3, 50233));
    push!(spec[i], BeforeConflictSection(4, 50233));
    push!(spec[i], BeforeConflictSection(5, 50233));
    push!(spec[i], BeforeConflictSection(6, 50233));
end

begin i=25
    push!(spec[i], BehindConflictSection(1, 50233));
    push!(spec[i], BeforeConflictSection(2, 50233));
    push!(spec[i], BehindConflictSection(3, 50233));
    push!(spec[i], BeforeConflictSection(4, 50233));
    push!(spec[i], BehindConflictSection(5, 50233));
    push!(spec[i], BeforeConflictSection(6, 50233));
end

begin i=33
    push!(spec[i], BehindConflictSection(1, 50233));
    push!(spec[i], BehindConflictSection(2, 50233));
    push!(spec[i], BehindConflictSection(3, 50233));
    push!(spec[i], BeforeConflictSection(4, 50233));
    push!(spec[i], BehindConflictSection(5, 50233));
    push!(spec[i], BeforeConflictSection(6, 50233));
end

begin i=41
    push!(spec[i], BehindConflictSection(1, 50233));
    push!(spec[i], BehindConflictSection(2, 50233));
    push!(spec[i], BehindConflictSection(3, 50233));
    push!(spec[i], BehindConflictSection(4, 50233));
    push!(spec[i], BehindConflictSection(5, 50233));
    push!(spec[i], BeforeConflictSection(6, 50233));
end

begin i=49
    push!(spec[i], BehindConflictSection(1, 50233));
    push!(spec[i], BehindConflictSection(2, 50233));
    push!(spec[i], BehindConflictSection(3, 50233));
    push!(spec[i], BehindConflictSection(4, 50233));
    push!(spec[i], BehindConflictSection(5, 50233));
    push!(spec[i], BehindConflictSection(6, 50233));
end

specvec = [sort([specs...], lt=type_ranking) for specs in spec]
actors_input = deepcopy(actors);
actors = deepcopy(actors_input);

for i = 1:k_max
    @info i
    # restrict convex set to match specifications
    for pred in specvec[i] #sort([spec[i]...], lt=type_ranking)
        @info pred
        apply_predicate!(pred, actors, i, ψ)
    end

    # propagate convex set to get next time step
    for (actor_id, actor) in actors.actors
        @assert length(actor.states) == i 
        push!(actor.states, propagate(actor.states[i], A, actor.a_ub, actor.a_lb, Δt))
    end
end

# backwards propagate reachable sets and intersect with forward propagated ones to tighten convex sets
for (actor_id, actor) in actors.actors
    for i in reverse(1:k_max-1)
        @info actor_id, i
        backward = propagate_backward(actor.states[i+1], A, actor.a_ub, actor.a_lb, Δt)
        intersect = ScenarioSynthesis.intersection(actor.states[i], backward) 
        actor.states[i] = intersect
    end
end

# synthesize trajectories using QP
using JuMP, Gurobi

traj = Dict{ActorID, Trajectory}()
grb_env = Gurobi.Env()
for (actor_id, actor) in actors.actors
    optim = synthesize_optimization_problem(actor, Δt, grb_env)
    optimize!(optim)
    @info objective_value(optim)
    traj[actor_id] = Trajectory(Vector{State}(undef, length(actor.states)))
    counter = 0 
    for val in eachrow(JuMP.value.(optim.obj_dict[:state][:,1:2]))
        counter += 1
        traj[actor_id][counter] = State(val[1], val[2])
    end
end

# animation
# animate_scenario(ln, actors, traj, Δt, k_max; playback_speed=1, filename="reach_tjunction")

# plot reachable sets
using LaTeXStrings
using PGFPlotsX; pgfplotsx()
plot();
colors = tum_colors_alternating;
colors_cont = tum_colors_harmonic;
counter = 1
for i=1:8:49
    counter += 1
    @info i
    plot!(plot_data(actors.actors[1].states[i]); color=colors_cont[counter], fill=true, fillcolor=colors[1], fillalpha=0.3); 
    plot!(plot_data(actors.actors[2].states[i] + State(actors.offset[2, 1], 0)); color=colors_cont[counter], fill=true, fillcolor=colors[2], fillalpha=0.3); 
    plot!(plot_data(actors.actors[3].states[i] + State(actors.offset[3, 1], 0)); color=colors_cont[counter], fill=true, fillcolor=colors[3], fillalpha=0.3);
    plot!(plot_data(actors.actors[4].states[i] + State(actors.offset[4, 1], 0)); color=colors_cont[counter], fill=true, fillcolor=colors[4], fillalpha=0.3);
    plot!(plot_data(actors.actors[5].states[i] + State(actors.offset[5, 1], 0)); color=colors_cont[counter], fill=true, fillcolor=colors[5], fillalpha=0.3);
    plot!(plot_data(actors.actors[6].states[i] + State(actors.offset[6, 1], 0)); color=colors_cont[counter], fill=true, fillcolor=colors[6], fillalpha=0.3);
end
plot!(; xlabel = L"s [\textrm{m}]", ylabel = L"v [\frac{\textrm{m}}{\textrm{s}}]", legend=false, grid=false, framestyle=:box, size = 2 .*(276, 276*0.61))

# add trajectories reach
plot!(hcat(traj[1]...)[1,:], hcat(traj[1]...)[2,:]; color=colors[1]);
plot!(hcat(traj[2]...)[1,:], hcat(traj[2]...)[2,:]; color=colors[2]);
plot!(hcat(traj[3]...)[1,:], hcat(traj[3]...)[2,:]; color=colors[3]);
plot!(hcat(traj[4]...)[1,:], hcat(traj[4]...)[2,:]; color=colors[4]);
plot!(hcat(traj[5]...)[1,:], hcat(traj[5]...)[2,:]; color=colors[5]);
plot!(hcat(traj[6]...)[1,:], hcat(traj[6]...)[2,:]; color=colors[6]); @warn "not offset-corrected"
plot!()

# add trajectories miqp
# @isdefined traj_miqp || throw(error("run runscript_milp_zip.jl first"))
plot!(hcat(traj_miqp[1]...)[1,1:end], hcat(traj_miqp[1]...)[2,1:end]; color=colors[1]);
plot!(hcat(traj_miqp[2]...)[1,1:end], hcat(traj_miqp[2]...)[2,1:end]; color=colors[2]);
plot!(hcat(traj_miqp[3]...)[1,1:end], hcat(traj_miqp[3]...)[2,1:end]; color=colors[3]);
plot!(hcat(traj_miqp[4]...)[1,1:end], hcat(traj_miqp[4]...)[2,1:end]; color=colors[4]);
plot!(hcat(traj_miqp[5]...)[1,1:end], hcat(traj_miqp[5]...)[2,1:end]; color=colors[5]);
plot!(hcat(traj_miqp[6]...)[1,1:end], hcat(traj_miqp[6]...)[2,1:end]; color=colors[6]); @warn "not offset-corrected"
plot!()

savefig("output/tikz/tjunction_reachable_sets.tikz")

# plot lanelet network + routes
using LaTeXStrings
using PGFPlotsX
pgfplotsx()
traj_reach = traj
plot_lanelet_network(ln; draw_direction=false)
plot!(aspect_ratio=:equal, frame=:box, yticks=false, xticks=false)
plot!(aspect_ratio=:equal, frame=:box, xlims=(-80, 105), ylims=(-30, 100))

traj_x_cart = Dict{ActorID, Vector{Float64}}()
traj_y_cart = Dict{ActorID, Vector{Float64}}()

for (actor_id, traj) in traj_reach
    traj_x_cart[actor_id] = Vector{Float64}()
    traj_y_cart[actor_id] = Vector{Float64}()
    for st in traj
        try
            x, y = transform(Pos(FRoute, st[1], 0), actors.actors[actor_id].route.frame)
            push!(traj_x_cart[actor_id], x)
            push!(traj_y_cart[actor_id], y)
        catch e
        end
    end
end

for (actor_id, traj) in traj_reach
    actor_id in (2, 4, 6) && continue
    plot!(traj_x_cart[actor_id], traj_y_cart[actor_id])
end

plot!()

for (actor_id, traj) in traj_reach
    vertices = ScenarioSynthesis.state_to_vertices(traj_reach[actor_id][1], actors.actors[actor_id])
    plot!(vertices[:,1], vertices[:,2]; color=false, fill=true, fillcolor=tum_colors.tum_blue_brand)
end

plot!()

for (actor_id, traj) in traj_reach
    x, y = 0, 0
    offset = 8
    if actor_id in (1, 2)
        x = traj_x_cart[actor_id][1]
        y = traj_y_cart[actor_id][1] - offset
    elseif actor_id in (3, 4)
        x = traj_x_cart[actor_id][1]
        y = traj_y_cart[actor_id][1] + offset
    else
        x = traj_x_cart[actor_id][1] - offset
        y = traj_y_cart[actor_id][1]
    end
    annotate!(x, y, text(actor_id))
end

plot!()

savefig("output/tikz/tjunction_ln_traj.tikz")



# performance evaluation 
using BenchmarkTools
using Gurobi

grb_env = Gurobi.Env()
@profview benchmark(1000, specvec, 49, Δt, actors_input, grb_env, 0.5; synthesize_trajectories = false)
