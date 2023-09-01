function type_ranking(pred1::Predicate, pred2::Predicate) 
    # true: apply pred1 prior to pred2
    
    # single agent predicates
    isa(pred1, PredicateSingle) && return true # among single agent predictates, the ordering does not matter
    isa(pred2, PredicateSingle) && return false

    # multi agent predicates
    
    # SlowerAgent
    typeof(pred1) == SlowerAgent && return true
    typeof(pred2) == SlowerAgent && return false
    
    # BehindAgent
    typeof(pred1) == BehindAgent && return true
    typeof(pred2) == BehindAgent && return false

    # SafeDistance
    typeof(pred1) == SafeDistance && return true
    tyepof(pred2) == SafeDistance && return false
end