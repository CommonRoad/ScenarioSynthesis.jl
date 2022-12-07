abstract type Predicate end
abstract type AtomicPredicate <: Predicate end # atomic predicates are süecial types of predicates
abstract type TrafficRule <: Predicate end # traffic rules are special types of predicates
abstract type Specification <: Predicate end # specifications are special types of preduactes


## Atomic Predicates
struct IsBehind <: AtomicPredicate end
struct IsNextTo <: AtomicPredicate end
struct IsInFront <: AtomicPredicate end
struct IsOnLanelet <: AtomicPredicate end
struct IsOnSameLaneSection <: AtomicPredicate end
struct IsRoutesMerge <: AtomicPredicate end # at least one laneletID of both routes is identical or last one does merge
struct IsRoutesIntersect <: AtomicPredicate end 
struct IsInConflictingArea <: AtomicPredicate end
struct IsBeforeConflictingArea <: AtomicPredicate end
struct IsBehindConflictingArea <: AtomicPredicate end
struct IsFaster <: AtomicPredicate end

## Traffic Rule
struct SpeedLimit <: TrafficRule end
struct SafeDistance <: TrafficRule end

## Specification

## Relations
struct Relation{T}
    actor1::ActorID
    actor2::ActorID
    lanelet::LaneletID

    """
        Relation

    Default constructor for relation between two vehicles.
    """
    function Relation(::Type{T}, actor1::ActorID, actor2::ActorID) where {T<:Union{IsBehind, IsNextTo, IsInFront, SafeDistance, IsRoutesMerge, IsRoutesIntersect, IsOnSameLaneSection, IsFaster}}
        return new{T}(actor1, actor2, -1)
    end

    """
        Relation 

    Default constructor for relation between a vehicle and a lanelet.
    """
    function Relation(::Type{T}, actor::ActorID, lanelet::LaneletID) where {T<:Union{IsOnLanelet, SpeedLimit}}
        return new{T}(actor, -1, lanelet)
    end
end
