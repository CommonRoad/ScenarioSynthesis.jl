function type_ranking(pred1::Predicate, pred2::Predicate)
    typeof(pred1) == typeof(pred2) && return true # if both predicates have the same type, their ordering does not matter
    isa(pred1, StaticPredicate) && return true # among static predictates, the ordering does not matter
    isa(pred2, StaticPredicate) && return false

    # now, pred1 and pred2 are dynamic
    dyn_vel_predicates = (FasterActor, SlowerActor) # TODO enhance type system?
    if typeof(pred1) in dyn_vel_predicates
        typeof(pred2) in dyn_vel_predicates || return true
        # now, pred1 and pred2 are of type dyn_vel_predicate
        return typeof(pred1) == FasterActor
    else
        typeof(pred2) in dyn_vel_predicates && return false
        # now, pred1 and pred2 are of type dyn_pos_predicate
        return typeof(pred1) == InFrontOfActor
    end
end