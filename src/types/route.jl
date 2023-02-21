import LinearAlgebra.norm
import StaticArrays.FieldVector

struct LaneletInterval <: FieldVector{3, Float64}
    lb::Float64 # longitudinal coordinate of route at first contact between actor and lanelet
    ub::Float64 # longitudinal coordinate of route at last contact between actor and lanelet
    offset::Float64 # longitudinal coordinate of lanelet at first contact between actor and lanelet
end

struct Route
    route::Vector{LaneletID}
    frame::TransFrame{FRoute}
    lanelet_interval::Dict{LaneletID, LaneletInterval}
    conflict_sections::Dict{ConflictSectionID, Tuple{Float64, Float64}} 

    function Route(route::Vector{LaneletID}, ln::LaneletNetwork, lenwid::SVector{2, Float64}, resampling_dst::Number=4.0)
        ### validity checks
        lenroute = length(route)
        lenroute ≥ 1 || throw(error("Route must travel at least one LaneSection."))
        transition_type = Vector{Symbol}()
        for i = 1:lenroute-1
            if in(route[i+1], ln.lanelets[route[i]].succ)
                push!(transition_type, :succeeding)
            elseif route[i+1] == ln.lanelets[route[i]].adjLeft.lanelet_id
                push!(transition_type, :lane_change_left)
            elseif route[i+1] == ln.lanelets[route[i]].adjRght.lanelet_id
                push!(transition_type, :lane_change_rght)
            else 
                throw(error("LaneSections of Route must be connected."))
            end
        end

        ### merged center line
        merged_center_line = Vector{Pos{FCart}}()
        lanelet_entry_pos = Vector{Pos{FCart}}()
        transition_angle = Vector{Float64}()
        for i = 1:lenroute-1
            if transition_type[i] == :succeeding
                append!(merged_center_line, ln.lanelets[route[i]].frame.ref_pos)
                push!(lanelet_entry_pos, ln.lanelets[route[i]].frame.ref_pos[1])
                push!(transition_angle, 0.0)
            elseif transition_type[i] == :lane_change_rght
                # handle lane change right
                lt1 = ln.lanelets[route[i]]
                push!(lanelet_entry_pos, lt1.frame.ref_pos[1])
                push!(transition_angle, 0.0)

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
                pushfirst!(cum_dst_rght_bound, 0.0)
                trid = findlast(x -> x ≤ 0.5 * cum_dst_rght_bound[end], lt1.cum_dst_rght_bound)
                s_remain = 0.5 * cum_dst_rght_bound[end] - cum_dst_rght_bound[trid]
                vec_to_next = lt1.boundRght.vertices[trid+1] - lt1.boundRght.vertices[trid]
                angle_bound = atan(vec_to_next...)
                support_point = lt1.boundRght.vertices[trid] + vec_to_next * (s_remain / norm(vec_to_next))
                push!(merged_center_line, support_point)
                push!(lanelet_entry_pos, support_point)

                # third quarter support_point
                lt2 = ln.lanelets[route[i+1]]
                trid = findlast(x -> x ≤ 0.75 * lt2.frame.cum_dst[end], lt2.frame.cum_dst)
                s_remain = 0.75 * lt2.frame.cum_dst[end] - lt2.frame.cum_dst[trid]
                vec_to_next = lt2.frame.ref_pos[trid+1] - lt2.frame.ref_pos[trid]
                support_point = lt2.frame.ref_pos[trid] + vec_to_next * (s_remain / nomr(vec_to_next))
                push!(merged_center_line, support_point)
                angle_cross = atan((merged_center_line[end]-merged_center_line[end-2])...)
                angle_transition = abs(rem2pi(angle_bound-angle_cross, RoundNearest))
                push!(transition_angle, angle_transition)

                # remainder
                append!(merged_center_line, lt2.frame.ref_pos[trid+1:end])

            elseif transition_type[i] == :lane_change_left
                # handle lane change left
                lt1 = ln.lanelets[route[i]]
                push!(lanelet_entry_pos, lt1.frame.ref_pos[1])
                push!(transition_angle, 0.0)

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
                pushfirst!(cum_dst_left_bound, 0.0)
                trid = findlast(x -> x ≤ 0.5 * cum_dst_left_bound[end], lt1.cum_dst_left_bound)
                s_remain = 0.5 * cum_dst_left_bound[end] - cum_dst_left_bound[trid]
                vec_to_next = lt1.boundLeft.vertices[trid+1] - lt1.boundLeft.vertices[trid]
                angle_bound = atan(vec_to_next...)
                support_point = lt1.boundLeft.vertices[trid] + vec_to_next * (s_remain / norm(vec_to_next))
                push!(merged_center_line, support_point)
                push!(lanelet_entry_pos, support_point)

                # third quarter support_point
                lt2 = ln.lanelets[route[i+1]]
                trid = findlast(x -> x ≤ 0.75 * lt2.frame.cum_dst[end], lt2.frame.cum_dst)
                s_remain = 0.75 * lt2.frame.cum_dst[end] - lt2.frame.cum_dst[trid]
                vec_to_next = lt2.frame.ref_pos[trid+1] - lt2.frame.ref_pos[trid]
                support_point = lt2.frame.ref_pos[trid] + vec_to_next * (s_remain / nomr(vec_to_next))
                push!(merged_center_line, support_point)
                angle_cross = atan((merged_center_line[end]-merged_center_line[end-2])...)
                angle_transition = abs(rem2pi(angle_bound-angle_cross, RoundNearest))
                push!(transition_angle, angle_transition)

                # remainder
                append!(merged_center_line, lt2.frame.ref_pos[trid+1:end])
            end
        end

        (length(route) == 1 || transition_type[end] == :succeeding) && (append!(merged_center_line, ln.lanelets[route[end]].frame.ref_pos); push!(lanelet_entry_pos, ln.lanelets[route[end]].frame.ref_pos[1]); push!(transition_angle, 0.0))
        
        ### resampling center line
        temp_frame = TransFrame(FRoute, merged_center_line)
        resampled_center_line = [merged_center_line[1]]

        for dst in resampling_dst:resampling_dst:temp_frame.cum_dst[end]
            ind = findlast(s -> s ≤ dst, temp_frame.cum_dst)
            remain = dst - temp_frame.cum_dst[ind]
            vec_to_next = temp_frame.ref_pos[ind+1] - temp_frame.ref_pos[ind]
            push!(resampled_center_line, temp_frame.ref_pos[ind] + remain / norm(vec_to_next) * vec_to_next)
        end
        push!(resampled_center_line, temp_frame.ref_pos[end])

        ### line smoothing
        smoothed_center_line = corner_cutting(resampled_center_line, 1)

        ### creation of TransFrame 
        frame = TransFrame(FRoute, smoothed_center_line)

        ### transition points at the crossing from one lanelet to another
        transition_point = map(x -> transform(FRoute, x, frame).c1, lanelet_entry_pos)
        push!(transition_point, frame.cum_dst[end])

        ### lanelet frame offset
        lanelet_frame_offset = map(x -> transform(FLanelet, x[1], ln.lanelets[x[2]].frame).c1, zip(lanelet_entry_pos, route))

        lanelet_interval = Dict{LaneletID, LaneletInterval}()
        #=
        if lenroute ≤ 1
            push!(lanelet_interval, LaneletInterval(0.0, ln.lanelets[route[1]].frame.cum_dst[end], 0.0))
        end
        =#

        pushfirst!(transition_type, :succeeding)
        push!(transition_type, :succeeding)
        pushfirst!(transition_angle, 0.0)
        push!(transition_angle, 0.0)

        for i = 1:lenroute
            lb = 0.0
            lb_lim = 0.0
            lb_edit = 0.0
            ub = 0.0
            ub_lim = 0.0
            ub_edit = 0.0
            
            if transition_type[i] == :succeeding 
                lb_edit = - lenwid[1] / 2
            else
                lb_edit = - lenwid[2] / 2 / tan(transition_angle[i])
            end

            if transition_type[i+1] == :succeeding
                ub_edit = + lenwid[1] / 2
            else
                ub_edit = + lenwid[2] / 2 / tan(transition_angle[i])
            end

            lb = transition_point[i] + lb_edit
            lb_lim = max(0.0, lb)

            ub = transition_point[i+1] + ub_edit
            ub_lim = min(frame.cum_dst[end], ub)

            lanelet_interval[route[i]] = LaneletInterval(lb_lim, ub_lim, lb_edit + (lb_lim - lb))
        end

        ### calculate conflict sections
        conflict_sections = Dict{ConflictSectionID, Tuple{Float64, Float64}}()
        for ltid in route
            for (csid, section) in ln.lanelets[ltid].conflict_sections
                step1 = transform(Pos(FLanelet, section[1], 0.0), ln.lanelets[ltid].frame) # pos FCart
                s_start = transform(FRoute, step1, frame).c1
                step2 = transform(Pos(FLanelet, section[2], 0.0), ln.lanelets[ltid].frame) # pos FCart
                s_end = transform(FRoute, step2, frame).c1
                conflict_sections[csid] = (s_start, s_end) # s in FRoute
            end
        end

        return new(route, frame, lanelet_interval, conflict_sections)
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

"""
    corner_cutting

Chaikin's corner cutting algorithm. 
"""
function corner_cutting(ls::Vector{Pos{FCart}}, n_iter::Integer)
    for i=1:n_iter
        ls = corner_cutting_core(ls)
    end
    return ls
end

function corner_cutting_core(ls::Vector{T}) where {T<:Pos{FCart}}
    lenls = length(ls)
    lenls ≥ 3 || return ls # throw(error("at least 3 points necessary for corner cutting."))
    smooth = Vector{T}(undef, (lenls-1)*2)
    smooth[1] = ls[1]
    vec_to_next = ls[2] - ls[1]
    smooth[2] = ls[1] + 0.75 * vec_to_next

    for i = 2:lenls-2
        vec_to_next = ls[i+1] - ls[i]
        smooth[2i-1] = ls[i] + 0.25 * vec_to_next
        smooth[2i] = ls[i] + 0.75 * vec_to_next
    end
    vec_to_next = ls[end] - ls[end-1]
    smooth[end-1] = ls[end-1] + 0.25 * vec_to_next
    smooth[end] = ls[end]
    return smooth
end