abstract type Predicate end

abstract type LonRelation end
struct Behind <: LonRelation end
struct NextTo <: LonRelation end # for actors
struct On <: LonRelation end # for lanelets
struct InFront <: LonRelation end

abstract type VelRelation end
struct Stop <: VelRelation end
struct Faster <: VelRelation end
struct Slower <: VelRelation end
struct SameVel <: VelRelation end

struct ActorPredicate{T} <: Predicate
    ego::ActorID
    other::ActorID

    function ActorPredicate(::Type{T}, ego::ActorID, other::ActorID) where {T<:Union{LonRelation, VelRelation}}
        new{T}(ego, other)
    end

    #= function ActorPredicate(::Stop, ego::ActorID)
        new{Stop}(ego, -1)
    end =#
end

struct LNPredicate{T} <: Predicate
    ego::ActorID
    lt::LaneletID # lt id of first admissable lanelet
    n_succ::Int64 # number of succeeding admissable lanelets

    function LNPredicate(::Type{T}, ego::ActorID, lt::LaneletID, n_succ::Integer) where {T<:LonRelation}
        return new{T}(ego, lt, n_succ)
    end
end

function LNPredicate(type::Type{T}, ego_id::ActorID, ego::Actor, lts::Vector{LaneletID}) where {T<:LonRelation}
    length(lts) ≥ 1 || throw(error("at least one lanet id must be specified."))
    lt = lts[1]
    in(lt, ego.route.route) || throw(error("first lanelet id must be part of route."))
    n_succ = 1

    return LNPredicate(type, ego_id, lt, n_succ)
end

struct CSPredicate{T} <: Predicate
    ego::ActorID
    cs::ConflictSectionID

    function CSPredicate(::Type{T}, ego::ActorID, cs::ConflictSectionID) where {T<:LonRelation}
        return new{T}(ego, cs)        
    end
end