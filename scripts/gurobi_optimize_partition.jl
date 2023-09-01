### Julia implementationj of mip1_c.c Gurobi tutorial 
using Gurobi

lb = [1.0, 1.0, 1.0]
ub = [9.0, 9.0, 9.0]
@assert length(lb) == length(ub)
N = length(lb)

env = Ref{Ptr{Cvoid}}()
model = Ref{Ptr{Cvoid}}()
error = 0
sol = Vector{Cdouble}(undef, 3) 
ind = Vector{Cint}(undef, 3)
val = Vector{Cdouble}(undef, 3)
obj = Vector{Cdouble}(undef, 3)
vtype = Vector{Char}(undef, 3)
optimstatus = Ref{Cint}()
objval = Ref{Cdouble}() # objval = zeros() # works both

error = GRBemptyenv(env)
error = GRBsetstrparam(env.x, "LogFile", "part_opti.log")
error = GRBstartenv(env.x)
error = GRBnewmodel(env.x, model, "part_opti", 0, C_NULL, C_NULL, C_NULL, C_NULL, C_NULL)

for i=1:3*N
    # lower
    # upper
    # dist
    error = GRBaddvar(model.x, 0, C_NULL, C_NULL, 0.0, -Inf64, Inf64, GRB_CONTINUOUS, C_NULL)
end

for i=3*N+1:4*N
    # root
    error = GRBaddvar(model.x, 0, C_NULL, C_NULL, 1.0, -Inf64, Inf64, GRB_CONTINUOUS, C_NULL)
end

error = GRBsetintattr(model.x, GRB_INT_ATTR_MODELSENSE, GRB_MAXIMIZE)

# lower
for i=1:N
    error = GRBaddconstr(model.x, 1, Int32(i), 1.0, GRB_LESS_EQUAL, lb[i], C_NULL) # use pointer to variable instead of Int32(i) 
end

# upper
for i=N+1:2*N

end

# dist
for i=2*N+1:3*N
    error = GRBaddconstr(model.x, )
end

# root
for i=3*N+1:4*N

end

error = GRBaddconstr(model.x, 2, ind, val, GRB_GREATER_EQUAL, 1.0, "c1")

error = GRBaddgenconstrExpA(model.x, "f", C_NULL, C_NULL, 0.5, C_NULL)

error = GRBoptimize(model.x)

error = GRBwrite(model.x, "mip1.lp")

error = GRBgetintattr(model.x, GRB_INT_ATTR_STATUS, optimstatus)

error = GRBgetdblattr(model.x, GRB_DBL_ATTR_OBJVAL, objval)

error = GRBgetdblattrarray(model.x, GRB_DBL_ATTR_X, 0, 3, sol)

print("\nOptimization complete\n")
if optimstatus.x == GRB_OPTIMAL
    print("Optimal objective: ", objval.x)
else
    print("Error; please debug!")
end

GRBfreemodel(model.x)

GRBfreeenv(env.x)