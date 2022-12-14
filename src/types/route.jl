import IntervalArithmetic.Interval
import LinearAlgebra.norm

struct Route
    route::Vector{LaneletID}
    frame::TransFrame
    transition_points::Vector{Float64} # transition points moving from one lanelet to the next one
    conflicting_areas::Vector{Interval{Float64}} # TODO create own struct for this? 

    function Route(route::Vector{LaneletID}, ln::LaneletNetwork)
        ### validity checks
        length(route) ≥ 1 || throw(error("Route must travel at least one LaneSection."))
        for i=eachindex(route[1:end-1])
            in(route[i+1], ln.lanelets[route[i]].succ) || throw(error("LaneSections of Route must be connected."))
        end

        merged_center_line = Vector{Pos{FCart}}()
        for i in eachindex(route[1:end-1])
            if in(route[i+1], ln.lanelets[route[i]].succ)
                append!(merged_center_line, ln.lanelets[route[i]].frame.ref_pos)
            elseif route[i+1] == ln.lanelets[route[i]].adjRght.lanelet_id
                # handle lane change right
                lt1 = ln.lanelets[route[i]]

                # first quarter
                trid = findlast(x -> x ≤ 0.25 * lt1.frame.cum_dst[end], lt1.frame.cum_dst)
                append!(merged_center_line, lt1.frame.ref_pos[1:trid])

                # first quarter support point
                s_remain = 0.25 * lt1.frame.cum_dst[end] - lt1.frame.cum_dst[trid]
                vec_to_next = lt1.frame.ref_pos[trid+1] - lt1.frame.ref_pos[trid]
                support_point = lt1.frame.ref_pos[trid] + vec_to_next * (s_remain / norm(vec_to_next))
                push!(merged_center_line, support_point)

                # second quarter support point
                cum_dst_rght_bound = cumsum(norm.(diff(lt1.boundRght.vertices)))
                trid = findlast(x -> x ≤ 0.5 * cum_dst_rght_bound[end], lt1.cum_dst_rght_bound)
                s_remain = 0.5 * cum_dst_rght_bound[end] - cum_dst_rght_bound[trid]
                vec_to_next = lt1.boundRght.vertices[trid+1] - lt1.boundRght.vertices[trid]
                support_point = lt1.boundRght.vertices[trid] + vec_to_next * (s_remain / norm(vec_to_next))
                push!(merged_center_line, support_point)

                # third quarter support_point
                lt2 = ln.lanelets[route[i+1]]
                trid = findlast(x -> x ≤ 0.75 * lt2.frame.cum_dst[end], lt2.frame.cum_dst)
                s_remain = 0.75 * lt2.frame.cum_dst[end] - lt2.frame.cum_dst[trid]
                vec_to_next = lt2.frame.ref_pos[trid+1] - lt2.frame.ref_pos[trid]
                support_point = lt2.frame.ref_pos[trid] + vec_to_next * (s_remain / nomr(vec_to_next))
                push!(merged_center_line, support_point)

                # remainder
                append!(merged_center_line, lt2.frame.ref_pos[trid+1:end])

            elseif route[i+1] == ln.lanelets[route[i]].adjLeft.lanelet_id
                # handle lane change left
                lt1 = ln.lanelets[route[i]]

                # first quarter
                trid = findlast(x -> x ≤ 0.25 * lt1.frame.cum_dst[end], lt1.frame.cum_dst)
                append!(merged_center_line, lt1.frame.ref_pos[1:trid])

                # first quarter support point
                s_remain = 0.25 * lt1.frame.cum_dst[end] - lt1.frame.cum_dst[trid]
                vec_to_next = lt1.frame.ref_pos[trid+1] - lt1.frame.ref_pos[trid]
                support_point = lt1.frame.ref_pos[trid] + vec_to_next * (s_remain / norm(vec_to_next))
                push!(merged_center_line, support_point)

                # second quarter support point
                cum_dst_left_bound = cumsum(norm.(diff(lt1.boundLeft.vertices)))
                trid = findlast(x -> x ≤ 0.5 * cum_dst_left_bound[end], lt1.cum_dst_left_bound)
                s_remain = 0.5 * cum_dst_left_bound[end] - cum_dst_left_bound[trid]
                vec_to_next = lt1.boundLeft.vertices[trid+1] - lt1.boundLeft.vertices[trid]
                support_point = lt1.boundLeft.vertices[trid] + vec_to_next * (s_remain / norm(vec_to_next))
                push!(merged_center_line, support_point)

                # third quarter support_point
                lt2 = ln.lanelets[route[i+1]]
                trid = findlast(x -> x ≤ 0.75 * lt2.frame.cum_dst[end], lt2.frame.cum_dst)
                s_remain = 0.75 * lt2.frame.cum_dst[end] - lt2.frame.cum_dst[trid]
                vec_to_next = lt2.frame.ref_pos[trid+1] - lt2.frame.ref_pos[trid]
                support_point = lt2.frame.ref_pos[trid] + vec_to_next * (s_remain / nomr(vec_to_next))
                push!(merged_center_line, support_point)

                # remainder
                append!(merged_center_line, lt2.frame.ref_pos[trid+1:end])
            else
                throw(error("You should have never reached this part."))
            end
        end

        (length(route) == 1 || in(route[end], ln.lanelets[route[end-1]].succ)) && append!(merged_center_line, ln.lanelets[route[end]].frame.ref_pos)
        
        # TODO add algorithms for line smoothing! -> neccessary for lane changes

        ### creation of TransFrame 
        frame = TransFrame(merged_center_line)

        ### storing transition points form one lanelet to another - TODO has to be adapted if line smoothing is implemented?
        transition_points = map(ltid -> transform(ln.lanelets[ltid].frame.ref_pos[1], frame).c1, route)
        push!(transition_points, frame.cum_dst[end])

        ### calculating conflicting areas
        conflicting_areas = Vector{Interval}()
        n_iter = 20
        for i in eachindex(route) # TODO move to LaneletNetwork construction? -- smoothed line could cause problems!
            rele = route[i]
            lanelet = ln.lanelets[rele]
            s_conflicting = Inf64
            e_conflicting = Inf64
            for merg in ln.lanelets[rele].merging_with
                s_conflicting == 0.0 && break
                poly_merg = Polygon(ln.lanelets[merg])

                # handling edge cases
                !is_intersect(Polygon(lanelet), poly_merg) && continue
                is_intersect(Polygon_cut_from_start(lanelet, 0.01), poly_merg) && (s_conflicting = 0.0; break)
                
                # bisection
                s_low = 0.0
                s_upp = lanelet.frame.cum_dst[end]

                for iter in 1:n_iter
                    s = (s_low + s_upp)/2
                    
                    if is_intersect(Polygon_cut_from_start(lanelet, s), poly_merg)
                        s_upp = s
                    else
                        s_low = s
                    end
                end
                s_conflicting = min(s_conflicting, s_low)
                e_conflicting = 0.0
            end

            for dive in ln.lanelets[rele].diverging_with
                e_conflicting == 0.0 && break
                poly_dive = Polygon(ln.lanelets[dive])

                # handling edge cases
                !is_intersect(Polygon(lanelet), poly_dive) && continue
                is_intersect(Polygon_cut_from_end(lanelet, 0.01), poly_dive) && (e_conflicting = 0.0; break)

                # bisection
                e_low = 0.0
                e_upp = lanelet.frame.cum_dst[end]

                for iter in 1:n_iter
                    e = (e_low + e_upp)/2

                    if is_intersect(Polygon_cut_from_end(lanelet, e), poly_dive)
                        e_upp = e
                    else
                        e_low = e
                    end
                end
                s_conflicting = 0.0
                e_conflicting = min(e_conflicting, e_low)
            end

            for intr in ln.lanelets[rele].intersecting_with 
                s_conflicting == 0.0 && break
                poly_intr = Polygon(ln.lanelets[intr])

                # handling edge cases
                !is_intersect(Polygon(lanelet), poly_intr) && continue
                is_intersect(Polygon_cut_from_start(lanelet, 0.01), poly_intr) && (s_conflicting = 0.0; break)
                
                # bisection
                s_low = 0.0
                s_upp = lanelet.frame.cum_dst[end]

                for iter in 1:n_iter
                    s = (s_low + s_upp)/2
                    
                    if is_intersect(Polygon_cut_from_start(lanelet, s), poly_intr)
                        s_upp = s
                    else
                        s_low = s
                    end
                end
                s_conflicting = min(s_conflicting, s_low)
            end

            for intr in ln.lanelets[rele].intersecting_with
                e_conflicting == 0.0 && break
                poly_intr = Polygon(ln.lanelets[intr])

                # handling edge cases
                !is_intersect(Polygon(lanelet), poly_intr) && continue
                is_intersect(Polygon_cut_from_end(lanelet, 0.01), poly_intr) && (e_conflicting = 0.0; break)

                # bisection
                e_low = 0.0
                e_upp = lanelet.frame.cum_dst[end]

                for iter in 1:n_iter
                    e = (e_low + e_upp)/2

                    if is_intersect(Polygon_cut_from_end(lanelet, e), poly_intr)
                        e_upp = e
                    else
                        e_low = e
                    end
                end
                e_conflicting = min(e_conflicting, e_low)
            end

            if s_conflicting < lanelet.frame.cum_dst[end] - e_conflicting
                push!(conflicting_areas, Interval(transition_points[i] + s_conflicting, transition_points[i+1] - e_conflicting))
            end
        end

        return new(route, frame, transition_points, conflicting_areas)
    end
end

"""
    ref_pos_of_conflicting_routes

Conflicting: merging or intersecting
"""
function ref_pos_of_conflicting_routes(route1::Route, route2::Route, ln::LaneletNetwork)
    # iterate over lanelets of route1
    for ltid in route1.route
        # check for same route, e.g. if second vehicle starts further down the road
        in(ltid, route2.route) && return ln.lanelets[ltid].frame.ref_pos[end], true

        # check for merging
        for merg in ln.lanelets[ltid].merging_with
            in(merg, route2.route) && return ln.lanelets[ltid].frame.ref_pos[end], true # return last center vertices pos of merging lanelets
        end

        # check for intersecting
        for intr in ln.lanelets[ltid].intersecting_with
            in(intr, route2.route) && return pos_intersect(LineStrech(ln.lanelets[ltid].frame.ref_pos), LineStrech(ln.lanelets[intr].frame.ref_pos))
        end
    end
    return Pos(FCart, Inf64, Inf64), false
end

function ref_pos_of_merging_routes(route1::Route, route2::Route, ln::LaneletNetwork)
    for ltid in route1.route
        # check for same route, e.g. if second vehicle starts further down the road
        in(ltid, route2.route) && return ln.lanelets[ltid].frame.ref_pos[end], true

        # check for merging
        for merg in ln.lanelets[ltid].merging_with
            in(merg, route2.route) && return ln.lanelets[ltid].frame.ref_pos[end], true # return last center vertices pos of merging lanelets
        end
    end
    return Pos(FCart, Inf64, Inf64), false
end

function ref_pos_of_intersecting_routes(route1::Route, route2::Route, ln::LaneletNetwork)
    for ltid in route1.route
        # check for intersecting
        for intr in ln.lanelets[ltid].intersecting_with
            in(intr, route2.route) && return pos_intersect(LineStrech(ln.lanelets[ltid].frame.ref_pos), LineStrech(ln.lanelets[intr].frame.ref_pos))
        end
    end
    return Pos(FCart, Inf64, Inf64), false 
end

"""


Return ref_pos for route1 and route2.
"""
function ref_position_of_neighboring_routes(route1::Route, route2::Route, ln::LaneletNetwork)
    for ltid in route1.route
        in(ltid, route2.route) && return ln.lanelets[ltid].frame.ref_pos[end], true # identical to merge

        ltid_iter = ltid
        # iterate to right
        while ln.lanelets[ltid_iter].adjRght.is_exist
            ltid_iter = ln.lanelets[ltid_iter].adjRght.lanelet_id
            if in(ltid_iter, route2.route)
                route2_ltid = route2.route[findfirst(x -> x==ltid_iter, route2.route)]
                return ln.lanelets[ltid_iter].frame.ref_pos[end], ln.lanelets[route2_ltid].frame.ref_pos[end], true
            end
        end

        ltid_iter = ltid
        # iterate to left
        while ln.lanelets[ltid_iter].adjLeft.is_exist
            ltid_iter = ln.lanelets[ltid_iter].adjLeft.lanelet_id
            if in(ltid_iter, route2.route)
                route2_ltid = route2.route[findfirst(x -> x==ltid_iter, route2.route)]
                return ln.lanelets[ltid_iter].frame.ref_pos[end], ln.lanelets[route2_ltid].frame.ref_pos[end], true
            end
        end

        return Pos(FCart, Inf64, Inf64), Pos(FCart, Inf64, Inf64), false
    end
end

# TODO those routes that are neigboring and conflicting or that are conflicting multiple times can lead to errors! -> validity check based on StateCurv? 
function ref_pos_general(route1::Route, route2::Route, ln::LaneletNetwork)
    # check for neigboring routes
    pos1, pos2, does_exist = ref_position_of_neighboring_routes(route1, route2, ln)
    does_exist && return pos1, pos2, does_exist

    # check for conflicting routes
    pos1, does_exist = ref_pos_of_conflicting_routes(route1, rout2, ln)
    does_exist && return pos1, pos1, does_exist

    return Pos(FCart, Inf64, Inf64), Pos(FCart, Inf64, Inf64), false
end