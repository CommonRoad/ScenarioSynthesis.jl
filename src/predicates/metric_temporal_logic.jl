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
struct Globally <: TimeOperator end # = Always
struct Previously <: TimeOperator end
# TODO add Next ? No, Next is a special case of Once, Future, Globally

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

function Base.getindex(mtlpredicate::MTLPredicate, index::AbstractVector{<:Integer})
    result = mtlpredicate
    for ind in index
        result = result.predicates[ind]
    end
    return result
end

function flatten!(mtl::MTLPredicate) # TODO implement, mutate? 
    @warn "Not implement yet. No changes applied."
    return nothing
end

function mtl2graph(mtl::MTLPredicate, k_max::Integer)
    graph = Dict{TimeStep, Dict{Int64, Tuple{Int64, Vector{BasicPredicate}}}}()

    index = []
    while true
        jump_to_next_basic_predicate!(mtl, index)
        isempty(index) && break
        

    end
    
    return graph
end

function jump_to_next_basic_predicate!(mtl::MTLPredicate, index::AbstractVector{<:Integer})

    # if not a basic predicate, e.g., at the beginning: increase depth
    if !isa(mtl[index], BasicPredicate)
        while !isa(mtl[index], BasicPredicate)
            push!(index, 1)
        end

    # else increase breadth
    else
        # reduce depth as long as necessary before increasing breadth
        while length(mtl[index[1:end-1]].predicates) ≤ index[end]
            pop!(index)
            isempty(index) && break
        end

        if !isempty(index)
            index[end] += 1 # increase breadth
            while !isa(mtl[index], BasicPredicate)
                push!(index, 1) # increase depth
            end
        end
    end
end