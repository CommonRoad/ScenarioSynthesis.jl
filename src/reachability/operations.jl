function upper_lim!(cs::ConvexStates, lim::Real, dir::Integer)
    convex_states = cs.vertices
    lencon = length(convex_states)
    counter = 1

    @inbounds for i = 1:lencon
        if convex_states[counter][dir] < lim
            if cycle(convex_states, counter-1)[dir] > lim
                # construct additional state
                itp =  (lim - cycle(convex_states, counter-1)[dir]) / (convex_states[counter][dir] - cycle(convex_states, counter-1)[dir])
                # 0.0 < itp < 1.0 || throw(error("itp: $itp"))
                lin_interpol_state = cycle(convex_states, counter-1) + itp * (convex_states[counter] - cycle(convex_states, counter-1))
                insert!(convex_states, counter, lin_interpol_state)

                # remove state exceeding the lim
                delind = mod(counter-1, 1:length(convex_states))
                deleteat!(convex_states, delind)
            end
            counter += 1
        elseif convex_states[counter][dir] ≥ lim
            if cycle(convex_states, counter-1)[dir] < lim
                itp = (lim - cycle(convex_states, counter-1)[dir]) / (convex_states[counter][dir] - cycle(convex_states, counter-1)[dir])
                # 0.0 < itp < 1.0 || throw(error("itp: $itp"))
                lin_interpol_state = cycle(convex_states, counter-1) + itp * (convex_states[counter] - cycle(convex_states, counter-1))
                insert!(convex_states, counter, lin_interpol_state)
                counter += 1
            end
            if cycle(convex_states, counter+1)[dir] ≥ lim
                deleteat!(convex_states, counter)
            else
                counter += 1
            end
        end
    end

    length(convex_states) ≥ 2 || throw(error("Less than two states."))
    return nothing
end