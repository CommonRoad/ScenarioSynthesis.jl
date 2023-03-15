const IncomingID = Int64
const IntersectionID = Int64

struct Incoming
    incomingLanelets::Set{LaneletID}
    succRight::Set{LaneletID}
    succStraight::Set{LaneletID}
    succLeft::Set{LaneletID}
    right_neighbor::IncomingID
    has_right_neighbor::Bool
end

# TODO replace by const Intersection = Dict{IncomingID, Incoming}
struct Intersection
    incomings::Dict{IncomingID, Incoming}
end

function left_neighbor_func(incoming_id::IncomingID, intersection::Intersection)
    for (k, v) in intersection.incomings
        v.right_neighbor == incoming_id && return k, true
    end
    return -1, false
end

"""
    opposite_neighbor_func

Return IncomingID of opposite incoming for four way, and T-intersections.
"""
function opposite_neighbor_func(incoming_id::IncomingID, intersection::Intersection)
    @assert length(intersection.incomings) ≤ 4 
    orig_incoming = intersection.incomings[incoming_id]
    if orig_incoming.has_right_neighbor
        right_incoming = intersection.incomings[orig_incoming.right_neighbor]
        right_incoming.has_right_neighbor && return right_incoming.right_neighbor, true
    end
    left_neighbor, has_left_neighbor = left_neighbor_func(incoming_id, intersection)
    if has_left_neighbor
        opposite_neighbor, has_opposite_neighbor = left_neighbor_func(left_neighbor, intersection)
        has_opposite_neighbor && return opposite_neighbor, true
    end
    return -1, false
end