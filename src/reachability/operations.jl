function upper_lim!(cs::ConvexSet, lim::Real, dir::Integer)
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

function lower_lim!(cs::ConvexSet, lim::Real, dir::Integer)
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