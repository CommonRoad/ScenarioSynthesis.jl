abstract type Predicate end

abstract type AtomicPredicate <: Predicate end # atomic predicates are süecial types of predicates

abstract type TrafficRule <: Predicate end # traffic rules are special types of predicates

abstract type Specification <: Predicate end # specifications are special types of preduactes


## Atomic Predicates
struct IsBehind <: AtomicPredicate end
struct IsNextTo <: AtomicPredicate end
struct IsInFront <: AtomicPredicate end
struct IsOnLanelet <: AtomicPredicate end

function is_fulfilled(pred::IsOnLanelet, pos::Pos, lanelet::Lanelet)
    # TODO add geometric checks
    return false
end

## Traffic Rule
struct SpeedLimit <: TrafficRule end
struct SafeDistance <: TrafficRule end

## Specification
