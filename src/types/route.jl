import LinearAlgebra.norm

struct Route
    route::Vector{LaneletID}
    frame::TransFrame
    transition_points::Vector{Float64} # transition points at the crossing from one lanelet to the next one
    conflict_sections::Dict{ConflictSectionID, Tuple{Float64, Float64}} 

    function Route(route::Vector{LaneletID}, ln::LaneletNetwork, resampling_dst::Number=2.0)
        ### validity checks
        length(route) ≥ 1 || throw(error("Route must travel at least one LaneSection."))
        for i=eachindex(route[1:end-1])
            in(route[i+1], ln.lanelets[route[i]].succ) || throw(error("LaneSections of Route must be connected."))
        end

        ### merged center line
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
        
        ### resampling center line
        temp_frame = TransFrame(merged_center_line)
        resampled_center_line = [merged_center_line[1]]

        for dst in resampling_dst:resampling_dst:temp_frame.cum_dst[end]
            ind = findlast(s -> s ≤ dst, temp_frame.cum_dst)
            remain = dst - temp_frame.cum_dst[ind]
            vec_to_next = temp_frame.ref_pos[ind+1] - temp_frame.ref_pos[ind]
            push!(resampled_center_line, temp_frame.ref_pos[ind] + remain / norm(vec_to_next) * vec_to_next)
        end
        push!(resampled_center_line, temp_frame.ref_pos[end])

        ### line smoothing
        # TODO add algorithms for line smoothing! -> neccessary for lane changes

        ### creation of TransFrame 
        frame = TransFrame(resampled_center_line)

        ### transition points at the crossing from one lanelet to another -- TODO adapt to allow for lane changes!!
        transition_points = map(ltid -> transform(ln.lanelets[ltid].frame.ref_pos[1], frame).c1, route)
        push!(transition_points, frame.cum_dst[end])

        ### calculate conflict sections
        conflict_sections = Dict{ConflictSectionID, Tuple{Float64, Float64}}()
        for ltid in route
            for (csid, section) in ln.lanelets[ltid].conflict_sections
                s_start = transform(transform(Pos(FCurv, section[1], 0.0), ln.lanelets[ltid].frame), frame).c1
                step1 = transform(Pos(FCurv, section[2], 0.0), ln.lanelets[ltid].frame)
                s_end = transform(step1, frame).c1
                conflict_sections[csid] = (s_start, s_end)
            end
        end

        return new(route, frame, transition_points, conflict_sections)
    end
end

function reference_pos(r1::Route, r2::Route, ln::LaneletNetwork)

    # diverge at first segment? 
    for dive in ln.lanelets[r1.route[1]].diverging_with
        in(dive, r2.route) && return ln.lanelets[dive].frame.ref_pos[1], ln.lanelets[dive].frame.ref_pos[1], true
    end

    # iterate over route1
    for ltid in r1.route

        # lt is part of the route2?
        in(ltid, r2.route) && return ln.lanelets[ltid].frame.ref_pos[1], ln.lanelets[ltid].frame.ref_pos[1], true
    
        # lt is neighbor to route2?
        ltid_iter = ltid
        while ln.lanelets[ltid_iter].adjRght.is_exist && ln.lanelets[ltid_iter].adjRght.is_same_direction
            ltid_iter = ln.lanelets[ltid_iter].adjRght.lanelet_id
            in(ltid_iter, r2.route) && return ln.lanelets[ltid].frame.ref_pos[1], ln.lanelets[ltid_iter].ref_pos[1], true
        end

        ltid_iter = ltid
        while ln.lanelets[ltid_iter].adjLeft.is_exist && ln.lanelets[ltid_iter].adjLeft.is_same_direction
            ltid_iter = ln.lanelets[ltid_iter].adjLeft.lanelet_id
            in(ltid_iter, r2.route) && return ln.lanelets[ltid].frame.ref_pos[1], ln.lanelets[ltid_iter].ref_pos[1], true
        end

        # lt does collide with route2?
        for intr in ln.lanelets[ltid].intersecting_with
            if in(intr, r2.route)
                pos, does_intersect = pos_intersect(LineStrech(ln.lanelets[ltid].frame.ref_pos), LineStrech(ln.lanelets[intr].frame.ref_pos))
                does_intersect && return pos, pos, true 
            end
        end
    end

    for merg in ln.lanelets[r1.route[end]].merging_with
        in(merg, r2.route) && return ln.lanelets[merg].frame.ref_pos[end], ln.lanelets[merg].frame.ref_pos[end], true # TODO end position tricky when transforming coordinates
    end

    return Pos(FCart, Inf64, Inf64), Pos(FCart, Inf64, Inf64), false
end