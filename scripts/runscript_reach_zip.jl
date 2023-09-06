using ScenarioSynthesis
using Polygons
using StaticArrays
using Plots; plotly()

# steps of synthesizing scenarios: 
# 1. load LaneletNetwork
# 2. define Agents (incl. their routes)
# 3. define formal specifications / sequence of predicates
# 4. synthesis

### load LaneletNetwork
#ln = ln_from_xml("example_files/DEU_Cologne-9_6_I-1.cr.xml");
ln = ln_from_xml("example_files/ZAM_Zip-1_64_T-1.xml");
#ln = ln_from_xml("example_files/ZAM_Tjunction-1_55_T-1.xml");
process!(ln)
plot_lanelet_network(ln; annotate_id=true);


lenwid = SVector{2, Float64}(5.0, 2.2)
### define Agents
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

agent1 = Agent(route1, cs1);
agent2 = Agent(route2, cs2);
agent3 = Agent(route3, cs3);
agent4 = Agent(route4, cs4);
 
#agents = AgentsDict([agent1, agent2, agent3, agent4], ln);
agents = AgentsDict([agent1, agent2, agent3, agent4], ln);

agents.offset # TODO why no offset for agents 1 & 3??

A = SMatrix{2, 2, Float64, 4}(0, 0, 1, 0) # add as default to propagate functions? 

### define formal specifications
Δt = 0.25
k_max = 41 # → scene duration: Δt * (k_max - 1) = 4 sec

empty_set = Set{Predicate}()

spec = Vector{Set{Predicate}}(undef, k_max)
for i=1:k_max
    spec[i] = copy(empty_set)
    push!(spec[i], VelocityLimits(1))
    push!(spec[i], VelocityLimits(2))
    push!(spec[i], VelocityLimits(3))
    push!(spec[i], VelocityLimits(4))
    push!(spec[i], BehindAgent([4, 3]))
end
push!(spec[1], BehindAgent([2, 1]));
for i=15:k_max-10
    push!(spec[i], BehindAgent([1, 2]))
end
for i=k_max-10:k_max
    push!(spec[i], BehindAgent([4, 1, 3, 2]))
end
push!(spec[k_max], OnLanelet(1, Set(24)));
push!(spec[k_max], SlowerAgent([2, 1]))

for i = 1:k_max
    @info i
    # restrict convex set to match specifications
    for pred in sort([spec[i]...], lt=type_ranking)
        @info pred
        apply_predicate!(pred, agents, i)
    end

    # propagate convex set to get next time step
    for (agent_id, agent) in agents.agents
        @assert length(agent.states) == i 
        push!(agent.states, propagate(agent.states[i], A, agent.a_ub, agent.a_lb, Δt))
    end
end

# backwards propagate reachable sets and intersect with forward propagated ones to tighten convex sets
for (agent_id, agent) in agents.agents
#agent_id, agent = 1, agents.agents[1]
    for i in reverse(1:k_max-1)
        @info agent_id, i
        backward = propagate_backward(agent.states[i+1], A, agent.a_ub, agent.a_lb, Δt)
        #intersection!(agent.states[i], backward)
        intersect = Polygons.intersection(agent.states[i], backward) 
        agent.states[i] = intersect
    end
end

# synthesize trajectories using QP
using JuMP, Gurobi

traj_reach = Dict{AgentID, Trajectory}()
grb_env = Gurobi.Env()
for (agent_id, agent) in agents.agents
    optim = synthesize_optimization_problem(agent, Δt, grb_env)
    optimize!(optim)
    @info agent_id, objective_value(optim)
    traj_reach[agent_id] = Trajectory(Vector{State}(undef, length(agent.states)))
    counter = 0 
    for val in eachrow(JuMP.value.(optim.obj_dict[:state][:,1:2]))
        counter += 1
        traj_reach[agent_id][counter] = State(val[1], val[2])
    end
end

# animation
animate_scenario(ln, agents, traj_reach, Δt, k_max; playback_speed=1, xlims=(-150, 50), ylims=(-5, 20), size=(1600, 300), filename="reach_zip")

# plot reachable sets
using LaTeXStrings
using PGFPlotsX; pgfplotsx()
plot();
colors_alt = palette(:tab10);# tum_colors_alternating;
colors_cont = palette(:viridis, 6);#tum_colors_harmonic;
counter = 1
for i=1:10:41
    counter+=1
    @info i
    plot!(Polygons.plot_data(agent1.states[i]); color=colors_cont[counter], linewidth=2, fill=true, fillcolor=colors_alt[1], fillalpha=0.2); 
    plot!(Polygons.plot_data(agent2.states[i] + State(agents.offset[2, 1], 0)); color=colors_cont[counter], linewidth=2, fill=true, fillcolor=colors_alt[2], fillalpha=0.2); 
    plot!(Polygons.plot_data(agent3.states[i] + State(agents.offset[3, 1], 0)); color=colors_cont[counter], linewidth=2, fill=true, fillcolor=colors_alt[3], fillalpha=0.2);
    plot!(Polygons.plot_data(agent4.states[i] + State(agents.offset[4, 1], 0)); color=colors_cont[counter], linewidth=2, fill=true, fillcolor=colors_alt[4], fillalpha=0.2);
end
plot!(; xlabel = L"s \ [\textrm{m}]", ylabel = L"\dot{s} \ [\frac{\textrm{m}}{\textrm{s}}]", grid=false, framestyle=:box, size = 2 .*(276, 276*0.61))

# add trajectories reach
plot!(hcat(traj_reach[1]...)[1,1:end-1], hcat(traj_reach[1]...)[2,1:end-1]; color=colors_alt[1] );
plot!(hcat(traj_reach[2]...)[1,1:end-1], hcat(traj_reach[2]...)[2,1:end-1]; color=colors_alt[2], linewidth=2);
plot!(hcat(traj_reach[3]...)[1,1:end-1], hcat(traj_reach[3]...)[2,1:end-1]; color=colors_alt[3], linewidth=2);
plot!(hcat(traj_reach[4]...)[1,1:end-1], hcat(traj_reach[4]...)[2,1:end-1]; color=colors_alt[4], linewidth=2); @warn "not offset-corrected"
plot!()

# add trajectories miqp
# @isdefined traj_miqp || throw(error("run runscript_milp_zip.jl first"))
plot!(hcat(traj_miqp[1]...)[1,1:end], hcat(traj_miqp[1]...)[2,1:end]; color=colors_alt[1], linestyle=:dash, linewidth=2);
plot!(hcat(traj_miqp[2]...)[1,1:end], hcat(traj_miqp[2]...)[2,1:end]; color=colors_alt[2], linestyle=:dash, linewidth=2);
plot!(hcat(traj_miqp[3]...)[1,1:end], hcat(traj_miqp[3]...)[2,1:end]; color=colors_alt[3], linestyle=:dash, linewidth=2);
plot!(hcat(traj_miqp[4]...)[1,1:end], hcat(traj_miqp[4]...)[2,1:end]; color=colors_alt[4], linestyle=:dash, linewidth=2); @warn "not offset-corrected"
plot!()

savefig("output/tikz/zip_reachable_sets.tikz")

# plot lanelet network + routes
plot_lanelet_network(ln; ylims=(-5, 20), xlims=(-150, 80), size=(1000, 400), draw_direction=true)
plot!(aspect_ratio=:equal, frame=:box, yticks=false, xticks=false)

traj_x_cart = Dict{AgentID, Vector{Float64}}()
traj_y_cart = Dict{AgentID, Vector{Float64}}()

for (agent_id, traj) in traj_reach
    traj_x_cart[agent_id] = Vector{Float64}()
    traj_y_cart[agent_id] = Vector{Float64}()
    for st in traj
        x, y = transform(Pos(FRoute, st[1], 0), agents.agents[agent_id].route.frame)
        push!(traj_x_cart[agent_id], x)
        push!(traj_y_cart[agent_id], y)
    end
end

for (agent_id, traj) in traj_reach
    plot!(traj_x_cart[agent_id], traj_y_cart[agent_id], color=colors_alt[agent_id])
end

plot!()

for (agent_id, traj) in traj_reach
    vertices = ScenarioSynthesis.state_to_vertices(traj_reach[agent_id][1], agents.agents[agent_id])
    plot!(vertices[:,1], vertices[:,2]; color=false, fill=true, fillcolor=colors_alt[agent_id])
end

plot!()

for (agent_id, traj) in traj_reach
    y = (traj_y_cart[agent_id][1] > 7 ? 15.0 : -1.0)
    annotate!(traj_x_cart[agent_id][1], y, text(agent_id))
end

plot!()

savefig("output/tikz/zip_ln_traj.tikz")