include("visualize.jl")
export plot_lanelet, plot_lanelet_network, plot_polygon, plot_route # TODO simplify / reduce names

include("animation.jl")
export animate_scenario

include("tum_colors.jl")
export tum_colors, tum_colors_presentation, tum_colors_harmonic, tum_colors_harmonic_grad, tum_colors_alternating, tum_colors_alternating_grad