import IntervalArithmetic.Interval

struct Route
    route::Vector{LaneletID}
    frame::TransFrame
    transition_points::Vector{Float64} # transition points moving from one lanelet to the next one
    conflicting_areas::Vector{Interval{Float64}} # TODO create own struct for this? 

    function Route(route::Vector{LaneletID}, ln::LaneletNetwork)
        ### validity checks
        length(route) ≥ 2 || throw(error("Route must travel at least two LaneSections."))
        for i=1:length(route)-1
            in(route[i+1], ln.lanelets[route[i]].succ) || throw(error("LaneSections of Route must be connected."))
        end

        merged_center_line = Vector{Pos{FCart}}(vcat([ln.lanelets[lsid].vertCntr for lsid in route]...))
        # TODO add algorithms for line smoothing! -> neccessary for lane changes

        ### creation of TransFrame 
        frame = TransFrame(merged_center_line)

        ### storing transition points form one lanelet to another - TODO has to be adapted if line smoothing is implemented
        transition_points = map(ltid -> transform(ln.lanelets[ltid].vertCntr[1], frame).c1, route)
        push!(transition_points, frame.cum_dst[end])

        ### calculating conflicting areas
        conflicting_areas = Vector{Interval}()
        for i in 1:length(route) # TODO move to LaneletNetwork construction? -- smoothed line could cause problems!
            rele = route[i]
            lanelet = ln.lanelets[rele]
            s_conflicting = Inf64
            e_conflicting = Inf64
            for merg in ln.lanelets[rele].merging_with
                poly_merg = Polygon(ln.lanelets[merg])

                is_intersect(Polygon_cut_from_start(lanelet, 0.01), poly_merg) && (s_conflicting = 0.0; break)
                # increase polygon size starting from front end of lanlet
                s_prev = 0.01
                s = 1.0
                while s_conflicting > 0.0 && s < lanelet.frame.cum_dst[end] && !is_intersect(Polygon_cut_from_start(lanelet, s), poly_merg)
                    s_prev = s
                    s += 1.0 # TODO maybe add more refinements or iterative procedure
                end
                s_conflicting = min(s_conflicting, s_prev)
                e_conflicting = 0.0
            end

            for dive in ln.lanelets[rele].diverging_with
                poly_dive = Polygon(ln.lanelets[dive])

                is_intersect(Polygon_cut_from_end(lanelet, 0.01), poly_dive) && (e_conflicting = 0.0; break)
                # increase polygon size starting from rear end of lanelet
                e_prev = 0.01
                e = 1.0
                while e_conflicting > 0.0 && e < lanelet.frame.cum_dst[end] && !is_intersect(Polygon_cut_from_end(lanelet, e), poly_dive)
                    e_prev = e
                    e += 1.0
                end
                s_conflicting = 0.0
                e_conflicting = min(e_conflicting, e_prev)
            end

            for intr in ln.lanelets[rele].intersecting_with 
                poly_intr = Polygon(ln.lanelets[intr])

                is_intersect(Polygon_cut_from_start(lanelet, 0.01), poly_intr) && (s_conflicting = 0.0; break)
                # increase polygon size starting from front end of lanlet
                s_prev = 0.01
                s = 1.0
                while s_conflicting > 0.0 && s < lanelet.frame.cum_dst[end] && !is_intersect(Polygon_cut_from_start(lanelet, s), poly_intr)
                    s_prev = s
                    s += 1.0
                end
                s_conflicting = min(s_conflicting, s_prev)

                is_intersect(Polygon_cut_from_end(lanelet, 0.01), poly_intr) && (e_conflicting = 0.0; break)
                # increase polygon size starting from rear end of lanelet
                e_prev = 0.01
                e = 1.0
                while e_conflicting > 0.0 && e < lanelet.frame.cum_dst[end] && !is_intersect(Polygon_cut_from_end(lanelet, e), poly_intr)
                    e_prev = e
                    e += 1.0
                end
                e_conflicting = min(e_conflicting, e_prev)
            end
            if s_conflicting < lanelet.frame.cum_dst[end] - e_conflicting
                push!(conflicting_areas, Interval(transition_points[i] + s_conflicting, transition_points[i+1] - e_conflicting))
            end
        end

        return new(route, frame, transition_points, conflicting_areas)
    end
end

function LaneletID(route::Route, state::StateCurv)
    # unsafe: does not check for lateral position yet
    state.lon.s < route.frame.cum_dst[end] || throw(error("Out of bounds."))
    ind = findlast(x -> x ≤ state.lon.s, route.transition_points)
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

function ref_pos_of_merging_routes(route1::Route, route2::Route, ln::LaneletNetwork)
    for ltid in route1.route
        # check for same route, e.g. if second vehicle starts further down the road
        in(ltid, route2.route) && return ln.lanelets[ltid].vertCntr[end], true

        # check for merging
        for merg in ln.lanelets[ltid].merging_with
            in(merg, route2.route) && return ln.lanelets[ltid].vertCntr[end], true # return last center vertices pos of merging lanelets
        end
    end
    return Pos(FCart, Inf64, Inf64), false
end

function ref_pos_of_intersecting_routes(route1::Route, route2::Route, ln::LaneletNetwork)
    for ltid in route1.route
        # check for intersecting
        for intr in ln.lanelets[ltid].intersecting_with
            in(intr, route2.route) && return pos_intersect(LineStrech(ln.lanelets[ltid].vertCntr), LineStrech(ln.lanelets[intr].vertCntr))
        end
    end
    return Pos(FCart, Inf64, Inf64), false 
end