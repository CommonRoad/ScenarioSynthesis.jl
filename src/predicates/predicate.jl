abstract type Predicate end
abstract type AtomicPredicate <: Predicate end # atomic predicates are süecial types of predicates
abstract type TrafficRule <: Predicate end # traffic rules are special types of predicates
abstract type Specification <: Predicate end # specifications are special types of preduactes


## Atomic Predicates
struct IsBehind <: AtomicPredicate end
struct IsNextTo <: AtomicPredicate end
struct IsInFront <: AtomicPredicate end
struct IsOnLaneSection <: AtomicPredicate end

## Traffic Rule
struct SpeedLimit <: TrafficRule end
struct SafeDistance <: TrafficRule end

## Specification

## Relations
struct Relation{T}
    v1::Vehicle
    v2::Vehicle
    l::Lanelet

    """
        Relation

    Default constructor for relation between two vehicles.
    """
    function Relation(::Type{T}, v1::Vehicle, v2::Vehicle) where {T<:Union{IsBehind, IsNextTo, IsInFront, SafeDistance}}
        l = Lanelet()
        return new{T}(v1, v2, l)
    end

    """
        Relation 

    Default constructor for relation between a vehicle and a lanelet.
    """
    function Relation(::Type{T}, v1::Vehicle, l::Lanelet) where {T<:Union{IsOnLaneSection, SpeedLimit}}
        v2 = Vehicle(-1)
        return new{T}(v1, v2, l)
    end
end

function is_valid(rel::Relation{IsBehind})
    # TODO check whether on same lane / driving direction
    # TODO check whether predicate is fulfilled
    @warn "dummy: rand function"
    return rand(Bool)
end