import Plots.gr, Plots.plot!, Plots.plot, Plots.Plot, Plots.plotly, Plots.annotate!
import StaticArrays.SMatrix

# backend() = plotly() # TODO remove this? 

function plot_lanelet(lt::Lanelet, id::LaneletID, p::Plot=plot(); draw_direction::Bool=true, annotate_id::Bool=true, size::Tuple{<:Integer, <:Integer}=(800, 600))

    vertNorth = map(v -> v.c2, lt.boundRght.vertices)
    append!(vertNorth, map(v -> v.c2, reverse(lt.boundLeft.vertices)))
    vertEast = map(v -> v.c1, lt.boundRght.vertices)
    append!(vertEast, map(v -> v.c1, reverse(lt.boundLeft.vertices)))

    cntr = lt.frame.ref_pos[floor(Int64, length(lt.frame.ref_pos)/2)]

    # driving direction viz
    if draw_direction
        vector_start_to_end = lt.boundLeft.vertices[1] - lt.boundRght.vertices[1]
        arrow = lt.boundRght.vertices[1] + 0.5 * vector_start_to_end + 0.5 * SMatrix{2, 2, Float64, 4}(0, -1, 1, 0) * vector_start_to_end
        push!(vertNorth, arrow.c2)
        push!(vertEast, arrow.c1)
    end
    push!(vertNorth, vertNorth[1])
    push!(vertEast, vertEast[1])

    p = plot!(
        p,
        vertEast,
        vertNorth;
        label = id,
        legend = false,
        aspect_ratio = :equal,
        grid = false,
        color = :black,
        size = size
    )

    if annotate_id
        p = annotate!(cntr[1], cntr[2], id)
    end

    return p
end

function plot_lanelet_network(ln::LaneletNetwork; overwrite_backend::Bool=true, draw_direction::Bool=true, annotate_id::Bool=false, size::Tuple{<:Integer,<:Integer}=(800, 600))
    #overwrite_backend && backend()

    p = plot()

    for (id, lt) in ln.lanelets
        plot!(p, plot_lanelet(lt, id, p; draw_direction=draw_direction, annotate_id=annotate_id, size=size))
    end

    return p 
end

function plot_polygon(poly::Polygon{F}) where {F<:FCart}
    vertNorth = map(v -> v.c2, poly.vertices)
    vertEast = map(v -> v.c1, poly.vertices)
    p = plot([vertEast..., vertEast[1]], [vertNorth..., vertNorth[1]]; label=false, aspect_ratio=:equal)
    return p
end

function plot_route(route::Route)
    pos = hcat(route.frame.ref_pos...)'
    p = plot(pos[:,1], pos[:,2]; label=false, aspect_ratio=:equal)
end