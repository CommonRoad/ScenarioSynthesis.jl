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
struct Previously <: TimeOperator end # TODO necessary? or special case of e.g., Globally?
# TODO add Next ? No, Next is a special case of Once, Future, Globally

abstract type TimeReference end
struct Relative <: TimeReference end
struct Absolute <: TimeReference end

## MTLPredicate
const Interval = Union{UnitRange, Missing} # TODO do not allow missing (for MTL)?

abstract type Predicate end

abstract type BasicPredicate <: Predicate end

struct MTLPredicate{T, R, L, N} <: Predicate
    interval::Interval # are Intervals relative to super MTLPredicate / activation of own MTLPredicate or absolute? 
    predicates::Vector{N}

    function MTLPredicate(
        ::Type{T}, 
        ::Type{R},
        ::Type{L}, 
        interval::Interval, 
        predicates::AbstractVector{N}
    ) where {T<:TimeOperator, R<:TimeReference, L<:LogicOperator, N<:Predicate}
        if length(predicates) ≤ 1 && (L != And)
            @warn "MTL Formulas with one or less predicates should be logical And. Applying changes."
            return new{T, R, And, N}(interval, predicates)
        end
        return new{T, R, L, N}(interval, predicates)
    end
end

function Base.getindex(mtlpredicate::MTLPredicate, index::AbstractVector{<:Integer})
    result = mtlpredicate
    for ind in index
        result = result.predicates[ind]
    end
    return result
end

function simplify!(mtl::MTLPredicate)
    # TODO implement, mutate? flatten? also boolean simplifications? "a || ¬a = true" etc., remove basic predicate duplicates?
    @warn "Not implement yet. No changes applied."
    return nothing
end

function mtl2config(mtl::MTLPredicate, k_max::Integer)
    index = Vector{Int64}()
    number_of_basic_predicates = 0
    basic_predicate_dict = Dict{BasicPredicate, Int64}()
    while true
        jump_to_next_basic_predicate!(mtl, index)
        isempty(index) && break
        number_of_basic_predicates += 1
        basic_predicate_dict[mtl[index]] = number_of_basic_predicates
    end
    
    range_max = 0:k_max-1
    config = [(zeros(Int64, k_max, number_of_basic_predicates), range_max)]

    explore_mtl!(mtl, 1, config, basic_predicate_dict)

    return config
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

function explore_mtl!(
    mtl::MTLPredicate{T, R, L, N}, 
    index::Integer,
    config::AbstractVector{<:Tuple{<:AbstractMatrix{<:Integer}, <:UnitRange}},
    basic_predicate_dict::Dict{BasicPredicate, Int64}
) where {T<:TimeOperator, R<:TimeReference, L<:LogicOperator, N<:Predicate}
    throw(error("Handling for \nT: $T \nR: $R \nL: $L \nN: $N \nnot implemented yet."))
    
    return nothing
end

function explore_mtl!(
    pred::BasicPredicate,
    index::Integer,
    config::AbstractVector{<:Tuple{<:AbstractMatrix{<:Integer}, <:UnitRange}},
    basic_predicate_dict::Dict{BasicPredicate, Int64}
)
    config[index][1][config[index][2].+1, basic_predicate_dict[pred]] .= 1

    return nothing
end

function explore_mtl!(
    mtl::MTLPredicate{Globally, Absolute, And, N},
    index::Integer,
    config::AbstractVector{<:Tuple{<:AbstractMatrix{<:Integer}, <:UnitRange}},
    basic_predicate_dict::Dict{BasicPredicate, Int64}
) where {N<:Predicate}
    config[index] = (config[index][1], intersect(config[index][2], mtl.interval))
    if !isempty(config[index][2])
        for pred in mtl.predicates # first process basic predicates
            isa(pred, BasicPredicate) && explore_mtl!(pred, index, config, basic_predicate_dict)
        end
        for pred in mtl.predicates # second process higher level predicates
            !isa(pred, BasicPredicate) && explore_mtl!(pred, index, config, basic_predicate_dict)
        end
    end

    return nothing
end

function explore_mtl!(
    mtl::MTLPredicate{Globally, Absolute, Or, N},
    index::Integer,
    config::AbstractVector{<:Tuple{<:AbstractMatrix{<:Integer}, <:UnitRange}},
    basic_predicate_dict::Dict{BasicPredicate, Int64}
) where {N<:Predicate}
    config[index] = (config[index][1], intersect(config[index][2], mtl.interval))
    if !isempty(config[index][2])
        lenconfig = length(config)
        for i in length(mtl.predicates)-1 # original one can be used continuously
            push!(config, deepcopy(config[index]))
        end
        original_one_used = false
        counter = 0
        ind = 0
        for pred in mtl.predicates
            if isa(pred, BasicPredicate)
                if original_one_used
                    counter += 1
                    ind = lenconfig + counter
                else
                    original_one_used = true
                    ind = index
                end

                explore_mtl!(pred, ind, config, basic_predicate_dict)
            end
        end
        for pred in mtl.predicates
            if !isa(pred, BasicPredicate)
                if original_one_used
                    counter += 1
                    ind = lenconfig + counter
                else
                    original_one_used = true
                    ind = index
                end

                explore_mtl!(pred, ind, config, basic_predicate_dict)
            end
        end
    end # TODO how to handle else? just no additional constraints? 

    # TODO additional admissable combinations of pred1 ∨ pred2 are, when pred1 and pred2 alternte over time

    return nothing
end

function explore_mtl!(
    mtl::MTLPredicate{Globally, Relative, And, N},
    index::Integer,
    config::AbstractVector{<:Tuple{<:AbstractMatrix{<:Integer}, <:UnitRange}},
    basic_predicate_dict::Dict{BasicPredicate, Int64}
) where {N<:Predicate}
    lenupper = length(config[index][])

end

function Base.isless(mat1::Matrix, mat2::Matrix)
    @assert size(mat1) == size(mat2)
    n, m = size(mat1)
    for i = 1:n
        for j = 1:m
            mat1[i, j] < mat2[i, j] && return true
            mat1[i, j] > mat2[i, j] && return false
        end
    end
    return true # mat1 and mat2 are equal. ordering does not matter / can not be determined. 
end