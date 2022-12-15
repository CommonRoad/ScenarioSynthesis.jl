@inline function safety_distance(state1::StateCurv, state2::StateCurv) # TODO maybe also consider individual accelerations? 
    return max(10.0, state1.lon.v, state2.lon.v) # safety distance in meters
end