@inline function safety_distance(state1::StateCurv, state2::StateCurv) # TODO maybe also consider individual accelerations? 
    return max(10.0, state1.lon.v, state2.lon.v) # m
end

@inline function velocity_tolerance(val::Number=1.0)
    return Float64(val) # m/s
end

@inline function position_tolerance(val::Number=2.0)
    return Float64(val) # m
end

function lanelet_thickness(lt::Lanelet, s::Float64)
    0 ≤ s < lt.frame.cum_dst[end] || throw(error("out of bounds."))

    # TODO linear interpolation of distances before and after actual position would be even more accurate
    trid_lt = findlast(x -> x ≤ s, lt.frame.cum_dst) # last center support point before longitudinal pos
    d_rght = -distance(lt.frame.ref_pos[trid_lt], lt.boundRght.vertices[trid_lt]) # distance to right boundary
    d_left = distance(lt.frame.ref_pos[trid_lt], lt.boundLeft.vertices[trid_lt])

    return d_rght, d_left
end