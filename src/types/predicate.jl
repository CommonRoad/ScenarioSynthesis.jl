# abstract type AbstractPredicate end

### Relations
# Time ??

# Longitudinal
abstract type LonRel end
struct Behind <: LonRel end
struct SameLon <: LonRel end
struct InFront <: LonRel end

# Velocity
abstract type VelRel end
struct Slower <: VelRel end
struct SameVel <: VelRel end
struct Faster <: VelRel end

abstract type VelAbs end
struct Stop <: VelAbs end

struct ActorRel{T}
    function ActorRel(::Type{T}) where {T<:Union{LonRel, VelRel}}
        return new{T}()
    end
end

struct LaneletRel{T}
    function LaneletRel(::Type{T}) where {T<:LonRel}
        return new{T}()
    end
end

struct ConflictSectionRel{T}
    function ConflictSectionRel(::Type{T}) where {T<:LonRel}
        return new{T}()
    end
end

### Predicates
struct Predicate{T} # <: AbstractPredicate
    ego::ActorID
    val1::Int64
    val2::Int64

    function Predicate(::T, ego::ActorID, other::ActorID) where {T<:ActorRel}
        return new{T}(ego, other, -1)
    end

    function Predicate(::T, ego::ActorID) where {T<:VelAbs}
        return new{T}(ego, -1, -1)
    end

    function Predicate(::T, ego::ActorID, lts::Vector{LaneletID}) where {T<:LaneletRel}
        @assert length(lts) ≥ 1
        return new{T}(ego, lts[1], length(lts))
    end

    function Predicate(::T, ego::ActorID, cs::ConflictSectionID) where {T<:ConflictSectionRel}
        return new{T}(ego, cs, -1)
    end
end