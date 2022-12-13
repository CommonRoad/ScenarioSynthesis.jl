const IncomingID = Int64
const IntersectionID = Int64

struct Incoming
    incomingLanelets::Set{LaneletID}
    succRight::Set{LaneletID}
    succStraight::Set{LaneletID}
    succLeft::Set{LaneletID}
    is_left_of::LaneletID
end
struct Intersection
    incomings::Dict{IncomingID, Incoming}
end