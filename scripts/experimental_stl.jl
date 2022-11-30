using SignalTemporalLogic

## Example STL formula
# Signals (i.e., trace)
x = [-0.25, 0, 0.1, 0.6, 0.75, 1.0]

# STL formula: "eventually the signal will be greater than 0.5"
ϕ = @formula ◊(xₜ -> xₜ > 0.5)

# Check if formula is satisfied
ϕ(x)


## Examle robustness
# Signals
x = [1, 2, 3, 4, -9, -8]

# STL formula: "eventually the signal will be greater than 0.5"
ϕ = @formula ◊(xₜ -> xₜ > 0.5)

# Robustness
∇ρ(x, ϕ)
# Outputs: [0.0  0.0  0.0  1.0  0.0  0.0]

# Smooth approximate robustness ∇ρ̃(x, ϕ)
∇ρ̃(x, ϕ)
# Outputs: [-0.0478501  -0.0429261  0.120196  0.970638  -1.67269e-5  -4.15121e-5]

safe_dist = @formula □(x -> x > 20.0)

signal = [18.0 .+ rand() for i=1:20]

safe_dist.(signal)

ρ(signal, safe_dist)
ρ̃(signal, safe_dist)

∇ρ(signal, safe_dist)
∇ρ̃(signal, safe_dist)

sum(∇ρ̃(signal, safe_dist))