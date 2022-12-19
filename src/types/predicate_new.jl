abstract type Prediacte end

abstract type ActorPredicate <: Prediacte end
abstract type TrafficSignPredicate <: Prediacte end
abstract type LaneletNetworkPredicate <: Prediacte end

abstract type LongitudinalRelation end
struct Behind <: LongitudinalRelation end
struct NextTo <: LongitudinalRelation end
struct InFront <: LongitudinalRelation end

abstract type VelocityRelation end
struct Faster <: VelocityRelation end
struct SameVelocity <: VelocityRelation end
struct Slower <: VelocityRelation end

struct ActorRelation{T} <: ActorPredicate
    ego::ActorID
    other::ActorID

    function ActorRelation(::Type{T}, ego::ActorID, other::ActorID) where {T<:Union{LongitudinalRelation, VelocityRelation}}
        new{T}(ego, other)
    end
end