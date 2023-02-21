import StaticArrays.FieldVector

struct Interval <: FieldVector{2, Float64}
    min::Float64
    max::Float64

    function Interval(min::Real, max::Real)
        min ≤ max || throw(error("empty interval."))
        return new(min, max)
    end
end