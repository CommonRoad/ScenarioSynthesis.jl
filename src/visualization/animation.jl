import Plots.gif

function animate_scenario(
    ln::LaneletNetwork, 
    agents::AgentsDict,
    trajectories::Dict{AgentID, Trajectory},
    Δt::Real,
    k_max::Integer; 
    fps::Real=20,
    playback_speed::Real=1.0,
    filename::String="animation"
) # TODO where to store Δt?
    Plots.gr()
    size = (600, 400)
    plt_ln = plot_lanelet_network(ln; size=size)

    total_duration = Δt * (k_max-1)
    t_range = range(0.0, total_duration, floor(Int64, total_duration * fps / playback_speed))
 
    
    animation = Plots.Animation()
    for t in t_range
        plt = deepcopy(plt_ln)
        ind = 1 + floor(Int64, t / Δt)
        ind = min(ind, k_max-1)
        itp = (t - (ind-1) * Δt) /  Δt

        for (agent_id, agent) in agents.agents
            state = trajectories[agent_id][ind+1] * itp + trajectories[agent_id][ind] * (1-itp)
            vertices = SMatrix{5, 2, Float64, 10}(zeros(10))
            try 
                vertices = state_to_vertices(state, agent)
            catch e
                @warn t, agent_id
                rethrow(e)
            end
            plot!(
                plt,
                vertices[:,1],
                vertices[:,2],
                agent_id;
                label=agent_id,
                size=size,
                color = false,
                fill = true,
                fillcolor = tum_colors.tum_blue_brand
                #fill_z = agent_id
            )
        end
        Plots.frame(animation)
    end
    
    gif(animation, joinpath(@__DIR__, "..", "..", "output", string(filename ,".gif")), fps=fps)
    return nothing
end

function state_to_vertices(state::State, agent::Agent)
    pos = transform(Pos(FRoute, state[1], 0), agent.route.frame)
    ind_route = searchsortedlast(agent.route.frame.cum_dst, state[1])
    ind_route = min(ind_route, length(agent.route.frame.cum_dst)-1)
    Θᵣ = atan(reverse(agent.route.frame.ref_pos[ind_route+1]-agent.route.frame.ref_pos[ind_route])...)
    si, co = sincos(Θᵣ)
    vertices = SMatrix{5, 2, Float64, 10}(1, -1, -1, 1, 1, 1, 1, -1, -1, 1) * SMatrix{2, 2, Float64, 4}(agent.lenwid[1]/2, 0, 0, agent.lenwid[2]/2) * SMatrix{2, 2, Float64, 4}(co, -si, si, co)
    return SMatrix{5, 2, Float64, 10}((vertices[:,1].+pos.c1)..., (vertices[:,2].+pos.c2)...)
end