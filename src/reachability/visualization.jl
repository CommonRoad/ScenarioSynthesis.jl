function plot_data(cs::ConvexStates)
    convex_states = cs.vertices
    lencon = length(convex_states)
    pos = Vector{Float64}(undef, lencon+1)
    vel = Vector{Float64}(undef, lencon+1)

    @inbounds for i = 1:lencon
        pos[i], vel[i] = convex_states[i]
    end
    pos[end] = pos[1]
    vel[end] = vel[1]
    return pos, vel
end

function Plots.plot(cs::ConvexStates)
    pos, vel = plot_data(cs)
    return Plots.plot(
        pos, vel; 
        aspect_ratio=:equal, 
        label=false
    )
end

function Plots.plot!(cs::ConvexStates)
    pos, vel = plot_data(cs)

    return Plots.plot!(
        pos, vel; 
        aspect_ratio=:equal, 
        label=false
    )
end