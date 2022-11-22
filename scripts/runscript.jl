using ScenarioSynthesis

scene01 = Scene(1, 4.0, 8.0)
scene02 = Scene(2, 2.0, 6.0)

actor01 = Vehicle(1)
actor02 = Vehicle(2; a_min=-2.0)

scenario01 = Scenario([actor01, actor02], [scene01, scene02])

ln = ScenarioSynthesis.read_lanelet_network("/home/florian/git/ScenarioSynthesis.jl/example_files/USA_US101-10_5_T-1.xml");

rel1  = Relation(IsBehind, actor01, actor02)

ScenarioSynthesis.is_valid(rel1)

p1 = Pos(FCart, 4.0, 5.0)
p2 = Pos(FCart, 1.0, 1.0)
v = p1-p2
ScenarioSynthesis.distance(p1,p2)

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

∇ρ̃(x, ϕ)