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

function intersection(cs1::ConvexSet, cs2::ConvexSet)
    output_set = Vector{State}()
    # sizehint!(output_set, length(cs1.vertices) + length(cs2.vertices))
    is_break = false
    cs = (cs1, cs2)

    @inbounds for i = eachindex(cs1.vertices)
        p1 = cs1.vertices[i]
        p2 = cycle(cs1.vertices, i+1)
        @inbounds for j = eachindex(cs2.vertices)
            q1 = cs2.vertices[j]
            q2 = cycle(cs2.vertices, j+1)

            λ, μ = intersection_point(p1, p2, q1, q2)
            if (0 ≤ λ ≤ 1) && (0 ≤ μ ≤ 1) # first intersection point found
                next_state = p1 + λ * (p2 - p1) # === q1 + μ * (q2 - q1)
                state_type = Intersect # other possibility: Vertice
                active = 1
                cs_counter = [i, j]
                push!(output_set, next_state) # add first intersection point to output set
                while true
                    next_state, state_type, active = get_next_state!(state_type, cs, next_state, active, cs_counter)
                    norm(next_state - output_set[1]) ≤ 1e-4 && break
                    push!(output_set, next_state)
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
    return ConvexSet(output_set, false, false)
end

@inline function intersection_point(p1::State, p2::State, q1::State, q2::State)
    λ = ((p1[2]-q1[2]) * (q2[1]-q1[1]) - (p1[1]-q1[1]) * (q2[2]-q1[2])) / ((p2[1]-p1[1]) * (q2[2]-q1[2]) - (p2[2]-p1[2]) * (q2[1]-q1[1]))
    μ = ((q1[2]-p1[2]) * (p2[1]-p1[1]) - (q1[1]-p1[1]) * (p2[2]-p1[2])) / ((q2[1]-q1[1]) * (p2[2]-p1[2]) - (q2[2]-q1[2]) * (p2[1]-p1[1]))
    return λ, μ
end

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
    rotmat = SMatrix{2, 2, Float64, 4}(0, 1, -1, 0) # TODO check direction

    dotprod = dot(to_next_inactive, rotmat*to_next_active)
    if dotprod > 0 # change active
        active, inactive = inactive, active
    end

    # check for intersections
    p1 = prev_state
    p2 = cycle(cs[active].vertices, cs_counter[active]+1)
    @inbounds for k in eachindex(cs[inactive].vertices)
        q1 = cs[inactive].vertices[k]
        q2 = cycle(cs[inactive].vertices, k+1)
        λ, μ = intersection_point(p1, p2, q1, q2)
        if (1e-6 < λ < 1-1e-6) && (1e-6 < μ < 1-1e-6) # 1e-3 enhances numerical robustness
            next_state = p1 + λ * (p2 - p1)
            cs_counter[inactive] = k
            return next_state, Intersect, active
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
    @inbounds for k in eachindex(cs[inactive].vertices)
        q1 = cs[inactive].vertices[k]
        q2 = cycle(cs[inactive].vertices, k+1)
        λ, μ = intersection_point(p1, p2, q1, q2)
        if (1e-6 < λ < 1-1e-6) && (1e-6 < μ < 1-1e-6) # 1e-3 enhances numerical robustness
            next_state = p1 + λ * (p2 - p1)
            cs_counter[inactive] = k
            return next_state, Intersect, active
        end
    end

    # no intersections, return next vertice
    next_state = cycle(cs[active].vertices, cs_counter[active]+1)
    cs_counter[active] += 1
    return next_state, Vertice, active
end

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