function upper_lim!(cs::ConvexSet, dir::Integer, lim::Real)
    input_set = cs.vertices
    lencon = length(input_set)
    counter = 1

    @inbounds for i = 1:lencon
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

function intersection(cs1::ConvexSet, cs2::ConvexSet)
    output_set = Vector{SVector{2, Float64}}()

    @inbounds for i = eachindex(c1.vertices)
        p1 = c1.vertices[i]
        p2 = cycle(c1.vertices, i+1)
        @inbounds for j = eachindex(c2.vertices)
            q1 = c2.vertices[j]
            q2 = cycle(c2.vertices, j+1)

            λ, μ = foo() # TODO implement function 
            if (0 ≤ λ ≤ 1) && (0 ≤ μ ≤ 1)
                # 
                break # TODO does this break both for loops? 
            end
        end
    end

    if length(output_set) == 0 
        # test whether c1 in c2 or vice versa; return smaller set
    end

    length(output_set) ≥ 2 || throw(error("not enough..."))
    return ConvexSet(output_set, false)
end

@inline function intersection_point()
    λ = 0.2
    μ = 0.3
    return λ, μ
end