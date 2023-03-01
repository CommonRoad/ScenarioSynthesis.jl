# abstract type Formula end

## Logics
abstract type LogicOperator end
struct And  <: LogicOperator end
struct Or  <: LogicOperator end
struct Not <: LogicOperator end
struct Implies <: LogicOperator end

And(a, b) = a && b
Or(a, b) = a || b
Not(a) = !a
Implies(a, b) = Or(Not(a), b)

## Time Operators
abstract type TimeOperator end

struct Once <: TimeOperator end
struct Future <: TimeOperator end # = Eventually
struct Globally <: TimeOperator end
struct Previously <: TimeOperator end
# TODO add Next ? 

## MTLPredicate
const Interval = Union{UnitRange, Missing} # TODO do not allow missing (for MTL)?

abstract type Predicate end

abstract type BasicPredicate <: Predicate end

struct MTLPredicate{T, L, N} <: Predicate
    # time::T
    # logic::L
    interval::Interval # are Intervals relative to super MTLPredicate / activation of own MTLPredicate or absolute? 
    predicates::Vector{N}

    function MTLPredicate(
        ::Type{T}, 
        ::Type{L}, 
        interval::Interval, 
        predicates::AbstractVector{N}
    ) where {T<:TimeOperator, L<:LogicOperator, N<:Predicate}
        return new{T, L, N}(interval, predicates)
    end
end