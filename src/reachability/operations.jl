import LazySets._intersection_vrep_2d, LazySets.monotone_chain!

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

    length(input_set) ≥ 2 || throw(error("Less than two states."))
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

abstract type StateType end
struct Intersect <: StateType end
struct Vertice <: StateType end

#=
function intersection(cs1::ConvexSet, cs2::ConvexSet)
    output_set = Vector{State}()
    # sizehint!(output_set, length(cs1.vertices) + length(cs2.vertices))
    is_break = false
    cs = (cs1, cs2)
    max_iter = 100

    for i = eachindex(cs1.vertices)
        p1 = cs1.vertices[i]
        p2 = cycle(cs1.vertices, i+1)
        for j = eachindex(cs2.vertices)
            q1 = cs2.vertices[j]
            q2 = cycle(cs2.vertices, j+1)

            λ, μ = intersection_point(p1, p2, q1, q2)
            if (0 ≤ λ ≤ 1) && (0 ≤ μ ≤ 1) # first intersection point found
                next_state = p1 + λ * (p2 - p1) # === q1 + μ * (q2 - q1)
                state_type = Intersect # other possibility: Vertice
                active = 1
                cs_counter = [i, j]
                @info cs_counter
                push!(output_set, next_state) # add first intersection point to output set
                while true
                    next_state, state_type, active = get_next_state!(state_type, cs, next_state, active, cs_counter)
                    norm(next_state - output_set[1]) ≤ 1e-4 && break
                    norm(next_state - output_set[end]) ≤ 1e-4 && continue # increases numerical robustness
                    push!(output_set, next_state)
                    max_iter -= 1; max_iter > 0 || throw(error("reached max iter. $cs_counter"))
                end

                is_break = true; break
            end
        end
        is_break && break
    end

    if length(output_set) == 0 
        is_within(cs2, cs1.vertices[1]) && return cs1 # cs1 is within cs2
        is_within(cs1, cs2.vertices[1]) && return cs2 # cs2 is withon cs1
    end

    length(output_set) < 3 && return ConvexSet(output_set, true, false)  # both cs do not intersect. 
    return ConvexSet(output_set, false, true)
end
=#
@inline function intersection_point(p1::State, p2::State, q1::State, q2::State)
    λ = ((p1[2]-q1[2]) * (q2[1]-q1[1]) - (p1[1]-q1[1]) * (q2[2]-q1[2])) / ((p2[1]-p1[1]) * (q2[2]-q1[2]) - (p2[2]-p1[2]) * (q2[1]-q1[1]))
    μ = ((q1[2]-p1[2]) * (p2[1]-p1[1]) - (q1[1]-p1[1]) * (p2[2]-p1[2])) / ((q2[1]-q1[1]) * (p2[2]-p1[2]) - (q2[2]-q1[2]) * (p2[1]-p1[1]))
    return λ, μ
end
#=
@inline margin() = 2*eps()

function get_next_state!(
    ::Type{Intersect},
    cs::Tuple{ConvexSet, ConvexSet}, 
    prev_state::State, 
    active::Integer,
    cs_counter::Vector{<:Integer}
)
    inactive = (active == 1 ? 2 : 1)

    to_next_active = cycle(cs[active].vertices, cs_counter[active]+1) - prev_state
    to_next_inactive = cycle(cs[inactive].vertices, cs_counter[inactive]+1) - prev_state
    rotmat = SMatrix{2, 2, Float64, 4}(0, 1, -1, 0)

    dotprod = dot(to_next_inactive, rotmat*to_next_active)
    if dotprod > 0 # change active
        active, inactive = inactive, active
    end

    # check for intersections
    p1 = prev_state
    p2 = cycle(cs[active].vertices, cs_counter[active]+1)
    for k in eachindex(cs[inactive].vertices)
        k == cs_counter[inactive] && continue
        q1 = cs[inactive].vertices[k]
        q2 = cycle(cs[inactive].vertices, k+1)
        λ, μ = intersection_point(p1, p2, q1, q2)
        if (0 < λ < 1-margin()) && (0 < μ < 1-margin())
            next_state = p1 + λ * (p2 - p1)
            cs_counter[inactive] = k
            return next_state, Intersect, active
        
        elseif isapprox(λ, 1; atol=margin())
            # continue with next vertice in sequence of active set
            break
        
        elseif λ == 0 && (0 ≤ μ ≤ 1) # vertice of active set intersects with inactive set -- perform intersection handling
            add_step = (isapprox(μ, 1; atol=margin()) ? 1 : 0)
            q2 = cycle(cs[inactive].vertices, k+1+add_step)
            to_next_active = p2 - p1
            to_next_inactive = q2 - p1
            rotmat = SMatrix{2, 2, Float64, 4}(0, 1, -1, 0)
            dotprod = dot(to_next_inactive, rotmat*to_next_active)

            if dotprod < 0 || (dotprod == 0 && norm(to_next_active) ≤ norm(to_next_inactive)) 
                # return next vertice of active set
                break
            else dotprod > 0 
                # switch sets and return next vertice of new active set
                active, inactive = inactive, active
                next_state = cycle(cs[active].vertices, k+1+add_step)
                cs_counter[active] = k+1+add_step
                return next_state, Vertice, active
            end

        elseif (0 < λ < 1) && isapprox(μ, 1; atol=margin())
            active, inactive = inactive, active
            next_state = cycle(cs[active].vertices, k+1)
            cs_counter[active] = k+1
            return next_state, Vertice, active
        
        elseif μ == 0 
            throw(error("handling necessary?"))
        end
    end
    
    # no intersections, return next vertice
    next_state = cycle(cs[active].vertices, cs_counter[active]+1)
    cs_counter[active] += 1
    return next_state, Vertice, active
end

function get_next_state!(
    ::Type{Vertice},
    cs::Tuple{ConvexSet, ConvexSet}, 
    prev_state::State, 
    active::Integer,
    cs_counter::Vector{<:Integer}
)
    inactive = (active == 1 ? 2 : 1)
    cs_counter[active] = mod1(cs_counter[active], length(cs[active].vertices))
    cs_counter[inactive] = mod1(cs_counter[inactive], length(cs[inactive].vertices)) # TODO wozu das? 

    p1 = cs[active].vertices[cs_counter[active]]
    p2 = cycle(cs[active].vertices, cs_counter[active]+1)
    for k in eachindex(cs[inactive].vertices)
        # k == cs_counter[inactive] && continue
        q1 = cs[inactive].vertices[k]
        q2 = cycle(cs[inactive].vertices, k+1)
        λ, μ = intersection_point(p1, p2, q1, q2)
        if (0 < λ < 1-margin()) && (0 < μ < 1-margin())
            next_state = p1 + λ * (p2 - p1)
            cs_counter[inactive] = k
            return next_state, Intersect, active
        
        elseif isapprox(λ, 1; atol=margin())
            # continue with next vertice in sequence of active set
            break
        elseif λ == 0 && (0 ≤ μ ≤ 1) # vertice of active set intersects with inactive set -- perform intersection handling
            add_step = (isapprox(μ, 1; atol=margin()) ? 1 : 0)
            q2 = cycle(cs[inactive].vertices, k+1+add_step)
            to_next_active = p2 - p1
            to_next_inactive = q2 - p1
            rotmat = SMatrix{2, 2, Float64, 4}(0, 1, -1, 0)
            dotprod = dot(to_next_inactive, rotmat*to_next_active)

            if dotprod < 0 || (dotprod == 0 && norm(to_next_active) ≤ norm(to_next_inactive)) 
                # return next vertice of active set
                break
            else dotprod > 0 
                # switch sets and return next vertice of new active set
                active, inactive = inactive, active
                next_state = cycle(cs[active].vertices, k+1+add_step)
                cs_counter[active] = k+1+add_step
                return next_state, Vertice, active
            end

        elseif (0 < λ < 1) && isapprox(μ, 1; atol=margin())
            active, inactive = inactive, active
            next_state = cycle(cs[active].vertices, k+1)
            cs_counter[active] = k+1
            return next_state, Vertice, active
        
        elseif μ == 0 
            throw(error("handling necessary?"))
        end
    end

    # no intersections, return next vertice
    next_state = cycle(cs[active].vertices, cs_counter[active]+1)
    cs_counter[active] += 1
    return next_state, Vertice, active
end
=#
@inline function is_within(cs::ConvexSet, state::State)
    lencon = length(cs.vertices)
    rotmat = SMatrix{2, 2, Float64, 4}(0, 1, -1, 0)
    vec_to_next = cs.vertices[1] - cs.vertices[end]
    dotprod = dot(state - cs.vertices[end], rotmat * vec_to_next)
    dotprod < 0 && return false # < 0 allows state to be on edge; ≤ does not allow state on edge

    @inbounds for i in 1:lencon-1
        vec_to_next = cs.vertices[i+1] - cs.vertices[i]
        dotprod = dot(state - cs.vertices[i], rotmat * vec_to_next)
        dotprod < 0 && return false
    end
    return true
end

function intersection_new(cs1::ConvexSet, cs2::ConvexSet)
    output_set = _intersection_vrep_2d(cs1.vertices, cs2.vertices) # TODO if removed, also delete LazySets form dependencies
    return ConvexSet(monotone_chain!(output_set))
end

function intersection(cs1::ConvexSet, cs2::ConvexSet)
    output_set = Vector{State}()

    # add all states of cs1, which are inside cs2
    for st in cs1.vertices
        is_within(cs2, st) && push!(output_set, st) # on line? 
    end
    # add all states of cs2, which are inside cs1
    for st in cs2.vertices
        is_within(cs1, st) && push!(output_set, st) # on line? 
    end
    # add all intersection points
    for i in eachindex(cs1.vertices)
        p1 = cs1.vertices[i]
        p2 = cycle(cs1.vertices, i+1)
        for j in eachindex(cs2.vertices)
            q1 = cs2.vertices[j]
            q2 = cycle(cs2.vertices, j+1)
            λ, μ = intersection_point(p1, p2, q1, q2)
            if (0 < λ < 1) && (0 < μ < 1) 
                next_state = p1 + λ * (p2 - p1)
                push!(output_set, next_state)
            end
        end
    end

    # sort counter clockwise convex
    left_bottom = State(Inf, Inf)
    left_bottom_ind = 0
    for i in eachindex(output_set)
        st = output_set[i]
        if st[1] < left_bottom[1] || (st[1] ≤ left_bottom[1] && st[2] < left_bottom[2])
            left_bottom = st
            left_bottom_ind = i
        end
    end

    # switch left_bottom to beginning of output_set
    output_set[1], output_set[left_bottom_ind] = output_set[left_bottom_ind], output_set[1]

    partialsort!(output_set, 2:length(output_set), by = st -> (st[2]-left_bottom[2])/(st[1]-left_bottom[1]), rev=false)
    
    return ConvexSet(output_set) # TODO skip checks if works well
end