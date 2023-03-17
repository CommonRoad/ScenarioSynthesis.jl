function upper_lim!(cs::ConvexSet, dir::Integer, lim::Real)
    input_set = cs.vertices
    lencon = length(input_set)
    counter = 1

    @inbounds for i = 1:lencon # TODO get rid of cycle function to improve performance
        if input_set[counter][dir] < lim
            if cycle(input_set, counter-1)[dir] > lim
                # construct additional state
                itp =  (lim - cycle(input_set, counter-1)[dir]) / (input_set[counter][dir] - cycle(input_set, counter-1)[dir])
                lin_interpol_state = cycle(input_set, counter-1) + itp * (input_set[counter] - cycle(input_set, counter-1))
                insert!(input_set, counter, lin_interpol_state)

                # remove state exceeding the lim
                delind = mod1(counter-1, length(input_set))
                deleteat!(input_set, delind)
            end
            counter += 1
        elseif input_set[counter][dir] ≥ lim
            if cycle(input_set, counter-1)[dir] < lim
                itp = (lim - cycle(input_set, counter-1)[dir]) / (input_set[counter][dir] - cycle(input_set, counter-1)[dir])
                lin_interpol_state = cycle(input_set, counter-1) + itp * (input_set[counter] - cycle(input_set, counter-1))
                insert!(input_set, counter, lin_interpol_state)
                counter += 1
            end
            if cycle(input_set, counter+1)[dir] ≥ lim
                deleteat!(input_set, counter)
            else
                counter += 1
            end
        end
    end
    
    fix_convex_polygon!(input_set)
    
    is_counterclockwise_convex(input_set) || throw(error("input set not counterclockwise convex: $input_set"))

    length(input_set) ≥ 2 || throw(error("Less than two states."))
    
    return nothing
end

function lower_lim!(cs::ConvexSet, dir::Integer, lim::Real)
    input_set = cs.vertices
    lencon = length(input_set)
    counter = 1

    @inbounds for i = 1:lencon
        if input_set[counter][dir] > lim
            if cycle(input_set, counter-1)[dir] < lim
                # construct additional state
                itp =  (lim - cycle(input_set, counter-1)[dir]) / (input_set[counter][dir] - cycle(input_set, counter-1)[dir])
                lin_interpol_state = cycle(input_set, counter-1) + itp * (input_set[counter] - cycle(input_set, counter-1))
                insert!(input_set, counter, lin_interpol_state)

                # remove state exceeding the lim
                delind = mod1(counter-1, length(input_set))
                deleteat!(input_set, delind)
            end
            counter += 1
        elseif input_set[counter][dir] ≤ lim
            if cycle(input_set, counter-1)[dir] > lim
                itp = (lim - cycle(input_set, counter-1)[dir]) / (input_set[counter][dir] - cycle(input_set, counter-1)[dir])
                lin_interpol_state = cycle(input_set, counter-1) + itp * (input_set[counter] - cycle(input_set, counter-1))
                insert!(input_set, counter, lin_interpol_state)
                counter += 1
            end
            if cycle(input_set, counter+1)[dir] ≤ lim
                deleteat!(input_set, counter)
            else
                counter += 1
            end
        end
    end

    # fix_convex_polygon!(input_set)
    
    # is_counterclockwise_convex(input_set) || throw(error("input set not counterclockwise convex: $input_set"))

    # length(input_set) ≥ 2 || throw(error("Less than two states."))
    
    return nothing
end

function get_upper_lim(cs::ConvexSet, dir::Integer, ψ::Real)
    lb = min(cs, dir)
    ub = max(cs, dir)
    return lb + (1-ψ) * (ub-lb)
end

function get_lower_lim(cs::ConvexSet, dir::Integer, ψ::Real)
    lb = min(cs, dir)
    ub = max(cs, dir)
    return lb + ψ * (ub-lb)
end

@inline function intersection_point(p1::State, p2::State, q1::State, q2::State)
    λ = ((p1[2]-q1[2]) * (q2[1]-q1[1]) - (p1[1]-q1[1]) * (q2[2]-q1[2])) / ((p2[1]-p1[1]) * (q2[2]-q1[2]) - (p2[2]-p1[2]) * (q2[1]-q1[1]))
    μ = ((q1[2]-p1[2]) * (p2[1]-p1[1]) - (q1[1]-p1[1]) * (p2[2]-p1[2])) / ((q2[1]-q1[1]) * (p2[2]-p1[2]) - (q2[2]-q1[2]) * (p2[1]-p1[1]))
    return λ, μ
end

@inline function is_within(state::State, cs::ConvexSet)
    cs.is_empty && return false
    lencon = length(cs.vertices)
    rotmat = SMatrix{2, 2, Float64, 4}(0, 1, -1, 0)
    vec_to_next = cs.vertices[1] - cs.vertices[end]
    dotprod = dot(state - cs.vertices[end], rotmat * vec_to_next)
    dotprod ≤ 0 && return false # < 0 allows state to be on edge; ≤ does not allow state on edge

    @inbounds for i in 1:lencon-1
        vec_to_next = cs.vertices[i+1] - cs.vertices[i]
        dotprod = dot(state - cs.vertices[i], rotmat * vec_to_next)
        dotprod ≤ 0 && return false
    end
    return true
end

function intersection(cs1::ConvexSet, cs2::ConvexSet)
    output_set = Vector{State}()

    # add all states of cs1, which are inside cs2
    for st in cs1.vertices
        is_within(st, cs2) && push!(output_set, st) # on line? 
    end
    # add all states of cs2, which are inside cs1
    for st in cs2.vertices
        is_within(st, cs1) && !in(st, output_set) && push!(output_set, st) # on line? 
    end
    # add all intersection points
    for i in eachindex(cs1.vertices)
        p1 = cs1.vertices[i]
        p2 = cycle(cs1.vertices, i+1)
        for j in eachindex(cs2.vertices)
            q1 = cs2.vertices[j]
            q2 = cycle(cs2.vertices, j+1)
            λ, μ = intersection_point(p1, p2, q1, q2)
            if (0 < λ ≤ 1) && (0 < μ ≤ 1) 
                next_state = p1 + λ * (p2 - p1)
                !in(next_state, output_set) && push!(output_set, next_state)
            end
        end
    end

    length(output_set) < 3 && return ConvexSet(output_set)

    # find left-bottom-state
    left = Inf
    bottom = Inf
    left_bottom_ind = 0
    for i in eachindex(output_set)
        state = output_set[i]
        if (state.pos < left) || (state.pos ≤ left && state.vel ≤ bottom)
            left, bottom = state
            left_bottom_ind = i
        end
    end 
    left_bottom = output_set[left_bottom_ind] # deepcopy necessary? 
    
    # switch left_bottom to beginning of output_set
    output_set[1], output_set[left_bottom_ind] = output_set[left_bottom_ind], output_set[1]

    i=2
    while i ≤ length(output_set) # remove duplicate points (which are almost identical to the left bottom point)
        if norm(output_set[i] - left_bottom) ≤ 1e-6 
            deleteat!(output_set, i)
        else
            i += 1 
        end
    end

    partialsort!(output_set, 2:length(output_set), by = st -> (st[2]-left_bottom[2])/(st[1]-left_bottom[1]), rev=false)

    fix_convex_polygon!(output_set)

    return ConvexSet(output_set)
end