struct Lane
    lanelets::Set{LaneletID}
end

function Lane(lt::LaneletID, ln::LaneletNetwork, max_iter::Number=Inf)
    # prevent cycles!!
    lanelets = Set{LaneletID}()
    queue = Set(lt)
    iter = 0
    while !isempty(queue) && iter ≤ max_iter
        expand_lane!(lanelets, queue, ln)
        iter += 1
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

function lanes(actor::Actor, ln::LaneletNetwork, s, v, d, ḋ) # s: lon pos of actor
    lanelets = lanelets(actor, ln, s, v, d, ḋ)
    lanes = [Lane(lt, ln) for lt in lanelets]
    return lanes
end