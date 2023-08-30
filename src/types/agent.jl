import StaticArrays.SMatrix, StaticArrays.SVector

const AgentID = Int64

abstract type AgentType end # TODO replace with RoadUser type? @enum instead of sttucts? 
struct Vehicle <: AgentType end # TODO is this even useful? 

struct Agent # TODO add type as label or element? or skip? or bool VRU?  
    route::Route
    states::Vector{ConvexSet}
    lenwid::SVector{2, Float64} # m 
    v_lb::Float64 # m/s
    v_ub::Float64 # m/s
    a_lb::Float64 # m/s²
    a_ub::Float64 # m/s²

    function Agent(
        route::Route,
        initial_state::ConvexSet;
        len::Number=5.0,
        wid::Number=2.2,
        v_lb::Number=0.0,
        v_ub::Number=30.0,
        a_lb::Number=-6.0,
        a_ub::Number=3.0
    )
        @assert len > 0
        @assert wid > 0
        #@assert v_lb ≤ 0 # backward
        @assert v_ub > 0 # forward
        @assert a_lb < 0 # breaking 
        @assert a_ub > 0 # accelerating

        return new(route, [initial_state], SVector{2, Float64}(len, wid), v_lb, v_ub, a_lb, a_ub)
    end
end

struct AgentsDict
    agents::Dict{AgentID, Agent}
    offset::Dict{Tuple{AgentID, AgentID}, Float64}

    function AgentsDict(agents::AbstractVector{Agent}, ln::LaneletNetwork)
        offset = Dict{Tuple{AgentID, AgentID}, Float64}()

        for i in eachindex(agents)
            for j in i+1:length(agents)
                ref_pos_fcart_i, ref_pos_fcart_j, does_exist = reference_pos(agents[i].route, agents[j].route, ln)

                if does_exist
                    ref_pos_i = transform(FRoute, ref_pos_fcart_i, agents[i].route.frame)
                    ref_pos_j = transform(FRoute, ref_pos_fcart_j, agents[j].route.frame)

                    offset[(i,j)] = ref_pos_j.c1 - ref_pos_i.c1
                    offset[(j,i)] = ref_pos_i.c1 - ref_pos_j.c1
                end
            end
        end

        return new(Dict{AgentID, Agent}(zip(eachindex(agents), agents)), offset) # assign each agent a unique AgentID
    end
end