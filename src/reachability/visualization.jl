import Plots

function Plots.plot(cs::ConvexSet)
    pos, vel = plot_data(cs)
    return Plots.plot(
        pos, vel; 
        aspect_ratio=:equal, 
        label=false,
        fillalpha=0.2
    )
end

function Plots.plot!(cs::ConvexSet)
    pos, vel = plot_data(cs)

    return Plots.plot!(
        pos, vel; 
        aspect_ratio=:equal, 
        label=false,
        fillalpha=0.2
    )
end