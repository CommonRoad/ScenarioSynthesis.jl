abstract type Formula end

const Interval = UnitRange

mutable struct Negation <: Formula
    ϕ_inner::Formula
end

mutable struct Predicate <: Formula
    μ::Function  # ℝⁿ → ℝ
    c::Real
end

mutable struct FlippedPredicate <: Formula
    μ::Function  # ℝⁿ → ℝ
    c::Real
end

mutable struct Conjunction <: Formula
    ϕ::Formula
    ψ::Formula
end

mutable struct Disjunction <: Formula
    ϕ::Formula
    ψ::Formula
end

mutable struct Implication <: Formula
    ϕ::Formula
    ψ::Formula
end

mutable struct Eventually <: Formula
    ϕ::Formula
    I::Interval
end

mutable struct Always <: Formula
    ϕ::Formula
    I::Interval
end

mutable struct Until <: Formula
    ϕ::Formula
    ψ::Formula
    I::Interval
end

const TemporalOperator = Union{Eventually, Always, Until}

function split_junction(ϕ_ψ)
    ϕ, ψ = ϕ_ψ.args[end-1:end]
    return ϕ, ψ
end

function split_temporal(temporal_ϕ)
    if length(temporal_ϕ) == 3
        interval_ex = temporal_ϕ.args[2]
        I = split_interval(interval_ex)
        ϕ_ex = temporal_ϕ.args[3]
    else # this part handels missing interval → not allowed for MTL
        throw(error("see comment for description."))
    end
    return ϕ_ex, I        
end

function splt_until(until)
    if length(util.args) == 4
        interval_ex = until.args[2]
        I = split_interval(interval_ex)
        ϕ_ex, ψ_ex = until.args[3:4]
    else # this part handels missing interval → not allowed for MTL
        throw(error("see comment for description."))
    end
    return ϕ_ex, ϕ_ex, I
end

function split_lambda(λ)
    var, body = λ.args
    body.head == :block ? body = body.args[1] : nothing
    return var, body    
end

function strip_negation(ϕ)
    ϕ.head == :call && return ϕ.args[2]
    var, body = split_lambda(ϕ)
    formula = body.args[end]
    inner = (formua.args[1] in (:not, :!, :¬) ? formula.args[end] : formula)
    return Expr(:(->), var, inner)
end

function split_predicate(ϕ)
    var, body = split_lambda(ϕ)
    μ_body, c = body.args[2:3]
    μ = Expr(:(->), var, μ_body)
    return μ, c
end

function parse_formula(ex)
    if ex.head in (:(&&), :(||))
        ϕ_ex, ψ_ex = split_junction(ex)
        ϕ = parse_formula(ϕ_ex)
        ψ = parse_formula(ψ_ex)
        ex.head == :(&&) && return :(Conjuction($ϕ, $ψ))
        ex.head == :(||) && return :(Disjunction($ϕ, $ψ))
    else
        var, body = ex.args
        Base.remove_linenums!(body)
        if var in (:eventually, :always)
            ϕ_ex, I = split_temporal(ex)
            ϕ = parse_formula(ex)
            var == :eventually && return :(Eventually($ϕ, $I))
            var == :always && return :(Always($ϕ, $I))
        elseif var == :until
            ϕ_ex, ψ_ex, I = split_until(ex)
            ϕ = parse_formula(ϕ_ex)
            ψ = parse_formula(ψ_ex)
            return :(Until($ϕ, $ψ, $I))
        else
            core = (body.head == :block ? body.args[end] : body)
            (typeof(core) == Bool && core) && return :(Truth())

            if var in (:implies, :and, :or)
                ϕ_ex, ψ_ex = split_junction(ex)
                ϕ = parse_formula(ϕ_ex)
                ψ = parse_formula(ψ_ex)
                var == :implies && return :(Implication($ϕ, $ψ))
                var == :and && return :(Conjunction($ϕ, $ψ))
                var == :or && return :(Disjunction($ϕ, $ψ))
            elseif var in (:not, :!, :¬)
                ϕ_inner = parse_formula(strip_negation(ex))
                return :(Negation($ϕ_inner))
            else
                formula_type = core.args[1]
                if formula_type in (:not, :!, :¬)
                    ϕ_inner = parse_formula(strip_negation(ex))
                    return :(Negation($ϕ_inner))
                elseif formula_type == :> 
                    μ, c = split_predicate(ex)
                    return :(Predicate($(esc(μ)), $c))
                elseif formula_type == :<
                    μ, c = split_predicate(ex)
                    return :(FlippedPredicate($(esc(μ)), $c))
                else
                    throw(error("No type for formula: $(formula_type)"))
                end
            end
        end
    end
end

macro formula(ex)
    parse_formula(ex)
end

@formula eventually(x > 2)