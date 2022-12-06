struct Route
    route::Vector{LaneletID}
    frame::TransFrame
    transition_points::Vector{Float64} # transition points moving from one lanelet to the next one

    function Route(route::Vector{LaneletID}, ln::LaneletNetwork)
        length(route) ≥ 2 || throw(error("Route must travel at least two LaneSections."))
        for i=1:length(route)-1
            in(route[i+1], ln.lanelets[route[i]].succ) || throw(error("LaneSections of Route must be connected."))
        end

        merged_center_line = Vector{Pos{FCart}}(vcat([ln.lanelets[lsid].vertCntr for lsid in route]...))

        # TODO add algorithms for line smoothing! -> neccessary for lane changes
        frame = TransFrame(merged_center_line)

        transition_points = map(ltid -> transform(ln.lanelets[ltid].vertCntr[1], frame).c1, route)
        push!(transition_points, frame.cum_dst[end])

        return new(route, frame, transition_points)
    end
end

function LaneletID(route::Route, lon_pos::Number)
    lon_pos < route.frame.cum_dst[end] || throw(error("Out of bounds."))
    ind = findlast(x -> x ≤ lon_pos, route.transition_points)
    return route.route[ind]
end

"""
    ref_pos_of_conflicting_routes

Conflicting: merging or intersecting
"""
function ref_pos_of_conflicting_routes(route1::Route, route2::Route, ln::LaneletNetwork)
    # iterate over lanelets of route1
    for ltid in route1.route
        # check for same route, e.g. if second vehicle starts further down the road
        in(ltid, route2.route) && return ln.lanelets[ltid].vertCntr[end], true

        # check for merging
        for merg in ln.lanelets[ltid].merging_with
            in(merg, route2.route) && return ln.lanelets[ltid].vertCntr[end], true # return last center vertices pos of merging lanelets
        end

        # check for intersecting
        for intr in ln.lanelets[ltid].intersecting_with
            in(intr, route2.route) && return pos_intersect(LineStrech(ln.lanelets[ltid].vertCntr), LineStrech(ln.lanelets[intr].vertCntr))
        end
    end
    return Pos(FCart, Inf64, Inf64), false
end