using ReachabilityAnalysis
using MathematicalSystems

x0 = [40.0, 28.0, 0.0]

A = [0 1 0; 0 0 1; 0 0 0]
b = [0, 0, 1]
x_lims = [-Inf Inf; -10.0 40.0; -Inf Inf]
u_lims = [-Inf Inf; -Inf Inf; -7.0 3.0]

model = ConstrainedLinearControlContinuousSystem(A, b[:,:], x_lims, u_lims)
model = LinearControlContinuousSystem(A, b[:,:])

normalize(model)

prob = @ivp(model, x(0) ∈ x0, dim=3)

solve(prob, NSTEPS=20)

struct State
    vel::Float64
    pos::Float64
end

struct LinearModel
    a_max::Float64
    a_min::Float64
end

function propagate(state::State, model::LinearModel, Δt::Number)
    state_max = State(state.vel + model.a_max * Δt, state.pos + state.vel * Δt + model.a_max/2 * Δt)
    state_min = State(state.vel + model.a_min * Δt, state.pos + state.vel * Δt + model.a_min/2 * Δt)
    return state_max, state_min
end

st1 = State(15, 0)
st2 = State(15, 10)
st3 = State(20, 10)
st4 = State(20, 0)

x0 = [st1 st2; st3 st4]

function propagate(state_matrix::Matrix{State}, model::LinearModel, Δt::Number)
    n, m = size(state_matrix)
    n == 2 || throw(error("state matrix must have exactly 2 rows.")) # TODO maybe change as mat[:,i] allows faster access
    result = Matrix{State}(undef, n, m+1)
    
    return 
end


### Prototyping

using BenchmarkTools
using StaticArrays

A = [0.0 1.0; 0.0 0.0]
Δt = 0.2
fund = exp(A*Δt)

st1 = [0.0; 2.0]
st2 = [0.0; 4.0]
st3 = [10.0; 2.0]
st4 = [10.0; 4.0]

states = [st1 st2 st3 st4]

@benchmark $fund*$states

fund_stat = SMatrix{2,2,Float64,4}(fund...)
states_stat = SMatrix{2,4,Float64,8}(states...)

@benchmark $fund_stat*$states_stat