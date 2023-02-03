### Julia implementationj of mip1_c.c Gurobi tutorial 
using Gurobi 

env = Ref{Ptr{Cvoid}}()
model = Ref{Ptr{Cvoid}}()
error = 0
sol = Vector{Float64}(undef, 3) 
ind = Vector{Int64}(undef, 3)
val = Vector{Float64}(undef, 3)
obj = Vector{Float64}(undef, 3)
vtype = Vector{Char}(undef, 3)
optimstatus = Ref{Cint}()
objval = Ref{Cdouble}() # objval = zeros() # works both

error = GRBemptyenv(env)
error = GRBsetstrparam(env.x, "LogFile", "mip1.log")
error = GRBstartenv(env.x)
error = GRBnewmodel(env.x, model, "mip1", 0, C_NULL, C_NULL, C_NULL, C_NULL, C_NULL)

obj = [1.0, 1.0, 2.0]
vtype = [GRB_BINARY, GRB_BINARY, GRB_BINARY]

# error = GRBaddvars(model.x, 3, 0, C_NULL, C_NULL, C_NULL, obj, C_NULL, C_NULL, vtype, C_NULL)
error = GRBaddvar(model.x, 0, C_NULL, C_NULL, 1.0, 0.0, GRB_INFINITY, GRB_BINARY, C_NULL)
error = GRBaddvar(model.x, 0, C_NULL, C_NULL, 1.0, 0.0, GRB_INFINITY, GRB_BINARY, C_NULL)
error = GRBaddvar(model.x, 0, C_NULL, C_NULL, 2.0, 0.0, GRB_INFINITY, GRB_BINARY, C_NULL)

error = GRBsetintattr(model.x, GRB_INT_ATTR_MODELSENSE, GRB_MAXIMIZE)

#ind = [0, 1, 2]
ind = [1, 2, 3]
val = [1.0, 2.0, 3.0]
error = GRBaddconstr(model.x, 3, ind, val, GRB_LESS_EQUAL, 4.0, "c0")

ind = [1, 2]
val = [1.0, 1.0]
error = GRBaddconstr(model.x, 2, ind, val, GRB_GREATER_EQUAL, 1.0, "c1")

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