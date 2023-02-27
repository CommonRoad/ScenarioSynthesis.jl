abstract type TimeOperator end
abstract type LogicOperator end

struct Gloabally <: TimeOperator end
struct Eventually <: TimeOperator end
struct Once <: TimeOperator end
struct Next <: TimeOperator end

struct And <: LogicOperator end
struct Or <: LogicOperator end

struct MTLPredicate{P,T} <: Predicate
    predicate::P # P <: Predciate
    time_operator::T # T <: TimeOperator
    interval::UnitRange{TimeStep}
end