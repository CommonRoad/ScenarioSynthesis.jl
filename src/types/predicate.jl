abstract type Predicate end
abstract type AtomicPredicate <: Predicate end # atomic predicates are special types of predicates
abstract type TrafficRule <: Predicate end # traffic rules are special types of predicates
abstract type Specification <: Predicate end # specifications are special types of preduactes


## Atomic Predicates
# Vehicle
struct IsBehind <: AtomicPredicate end
struct IsNextTo <: AtomicPredicate end
struct IsInFront <: AtomicPredicate end
struct IsFaster <: AtomicPredicate end
struct IsSlower <: AtomicPredicate end
struct IsSameSpeed <: AtomicPredicate end
struct IsStop <: AtomicPredicate end

# LaneletNetwork
struct IsOnLanelet <: AtomicPredicate end
struct IsOnSameLaneSection <: AtomicPredicate end
# struct IsRoutesMerge <: AtomicPredicate end # at least one laneletID of both routes is identical or last one does merge
# struct IsRoutesIntersect <: AtomicPredicate end 

# ConflictSection
struct IsOnConflictSection <: AtomicPredicate end
struct IsBeforeConflictSection <: AtomicPredicate end
struct IsBehindConflictSection <: AtomicPredicate end


## Traffic Rule
struct SpeedLimit <: TrafficRule end
struct SafeDistance <: TrafficRule end

## Specification

## Relations
struct Relation{T}
    actor1::ActorID
    actor2::ActorID
    lanelet::LaneletID
    conflict_section::ConflictSectionID

    """
        Relation

    Default constructor for relation between two vehicles.
    """
    function Relation(::Type{T}, actor1::ActorID, actor2::ActorID) where {T<:Union{IsBehind, IsNextTo, IsInFront, IsFaster, IsSlower, IsSameSpeed, SafeDistance, IsOnSameLaneSection}}
        return new{T}(actor1, actor2, -1, -1)
    end

    """
        Relation 

    Default constructor for relation between a vehicle and a lanelet.
    """
    function Relation(::Type{T}, actor::ActorID, lanelet::LaneletID) where {T<:Union{IsOnLanelet, SpeedLimit}}
        return new{T}(actor, -1, lanelet, -1)
    end

    """
        Relation

    Default constructor for conflict section predicates.
    """
    function Relation(::Type{T}, actor::ActorID, conflict_section::ConflictSectionID) where {T<:Union{IsBeforeConflictSection, IsBehindConflictSection, IsOnConflictSection}}
        return new{T}(actor, -1, -1, conflict_section)
    end

    """
        Relation

    Default constructor for single vehicle predicate.
    """
    function Relation(::Type{T}, actor::ActorID) where {T<:Union{IsStop}}
        return new{T}(actor, -1, -1, -1)
    end
end
