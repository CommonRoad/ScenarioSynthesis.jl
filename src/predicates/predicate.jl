abstract type Predicate end
abstract type AtomicPredicate <: Predicate end # atomic predicates are süecial types of predicates
abstract type TrafficRule <: Predicate end # traffic rules are special types of predicates
abstract type Specification <: Predicate end # specifications are special types of preduactes


## Atomic Predicates
struct IsBehind <: AtomicPredicate end
struct IsNextTo <: AtomicPredicate end
struct IsInFront <: AtomicPredicate end
struct IsOnLanelet <: AtomicPredicate end
struct IsRoutesTouch <: AtomicPredicate end # != intersect
struct IsRoutesIntersect <: AtomicPredicate end 


## Traffic Rule
struct SpeedLimit <: TrafficRule end
struct SafeDistance <: TrafficRule end

## Specification

## Relations
struct Relation{T}
    v1::ActorID
    v2::ActorID
    l::LaneletID

    """
        Relation

    Default constructor for relation between two vehicles.
    """
    function Relation(::Type{T}, v1::ActorID, v2::ActorID) where {T<:Union{IsBehind, IsNextTo, IsInFront, SafeDistance, IsRoutesTouch, IsRoutesIntersect}}
        return new{T}(v1, v2, -1)
    end

    """
        Relation 

    Default constructor for relation between a vehicle and a lanelet.
    """
    function Relation(::Type{T}, v1::ActorID, l::LaneletID) where {T<:Union{IsOnLanelet, SpeedLimit}}
        return new{T}(v1, -1, l)
    end
end