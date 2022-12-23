import DataStructures.OrderedSet

struct Lane
    lanelets::OrderedSet{LaneletID}
end

function Lane(lt::LaneletID, ln::LaneletNetwork)
    # prevent cycles!!
    lanelets = OrderedSet{LaneletID}()
    queue = Set(lt)
    while !isempty(queue)
        expand_lane!(lanelets, queue, ln)
    end
    return Lane(lanelets)
end

# TODO this definition only makes sense for interstate situations
function expand_lane!(lanelets::AbstractSet{LaneletID}, queue::AbstractSet{LaneletID}, ln::LaneletNetwork)
    lt = pop!(queue)
    new = setdiff(union(ln.lanelets[lt].pred, ln.lanelets[lt].succ), lanelets)
    union!(lanelets, new)
    union!(queue, new)
end

function lanes(actor::Actor, ln::LaneletNetwork, s) # s: lon pos of actor
    lanelets = lanelets(actor, s)
    lanes = [Lane(lt, ln) for lt in lanelets]
    return lanes
end