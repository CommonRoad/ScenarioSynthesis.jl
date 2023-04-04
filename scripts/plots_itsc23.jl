using ScenarioSynthesis
using Plots
using LaTeXStrings

const COLUMNWIDTH = 245.71811
const GOLDEN_RATIO = (1+sqrt(5))/2

plot_font = "Computer Modern"
default(
    fontfamily=plot_font,
    linewidth=2, 
    framestyle=:box, 
    label=nothing, 
    grid=false,
    color_palette = tum_colors_harmonic,
    c = tum_colors_harmonic_grad
)
mat = Matrix{Float64}(undef, 64, 64)
for i in 1:size(mat)[1]
    for j in 1:size(mat)[2]
        mat[i, j] = sin((i^2 + j^2)^0.5 / 16)
    end
end

heatmap(mat, colorbar = true)
#plot(sort(rand(10)),sort(rand(10), ),label="Legend")
plot!(xlabel=L"\textrm{Standard~text}(r) / \mathrm{cm^3}")
plot!(ylabel="Same font as everything")
annotate!(20,10,text("My note",plot_font,12))