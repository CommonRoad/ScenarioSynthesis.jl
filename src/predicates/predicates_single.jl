abstract type PredicateSingle <: BasicPredicate end

function apply_predicate!(
    predicate::PredicateSingle, 
    agents::AgentsDict, 
    k::TimeStep,
    unnecessary...
)
    bounds = Bounds(predicate, agents)
    apply_bounds!(agents.agents[predicate.agent_ego].states[k], bounds)
    return nothing
end

struct OnLanelet <: PredicateSingle
    agent_ego::AgentID
    lanelet::Set{LaneletID} # Lanelet IDs must be sequential -- TODO add specific constructor? 
end

function Bounds( # TODO might be worth memoizing, suited for @generated?
    predicate::OnLanelet,
    agents::AgentsDict,
    unnecessary...
)
    s_lb = Inf
    s_ub = -Inf

    route = agents.agents[predicate.agent_ego].route

    for lt in predicate.lanelet
        s_lb_temp, s_ub_temp, _ = route.lanelet_interval[lt]
        s_lb = min(s_lb, s_lb_temp)
        s_ub = max(s_ub, s_ub_temp)
    end

    return Bounds(s_lb, s_ub, -Inf, Inf)
end

struct OnConflictSection <: PredicateSingle
    agent_ego::AgentID
    conflict_section::ConflictSectionID
end

function Bounds(
    predicate::OnConflictSection,
    agents::AgentsDict, 
    unnecessary...
)
    s_lb, s_ub = agents.agents[predicate.agent_ego].route.conflict_sections[predicate.conflict_section]
    s_lb -= agents.agents[predicate.agent_ego].lenwid[1] / 2
    s_ub += agents.agents[predicate.agent_ego].lenwid[1] / 2

    return Bounds(s_lb, s_ub, -Inf, Inf)
end

struct BeforeConflictSection <: PredicateSingle
    agent_ego::AgentID
    conflict_section::ConflictSectionID
end

function Bounds(
    predicate::BeforeConflictSection,
    agents::AgentsDict, 
    unnecessary...
)
    s_ub, _ = agents.agents[predicate.agent_ego].route.conflict_sections[predicate.conflict_section]
    s_ub -= agents.agents[predicate.agent_ego].lenwid[1] / 2
 
    return Bounds(-Inf, s_ub, -Inf, Inf)
end

struct BehindConflictSection <: PredicateSingle
    agent_ego::AgentID
    conflict_section::ConflictSectionID
end

function Bounds(
    predicate::BehindConflictSection,
    agents::AgentsDict,
    unnecessary...
)
    _, s_lb = agents.agents[predicate.agent_ego].route.conflict_sections[predicate.conflict_section]
    s_lb += agents.agents[predicate.agent_ego].lenwid[1] / 2
 
    return Bounds(s_lb, Inf, -Inf, Inf)
end

struct VelocityLimits <: PredicateSingle
    agent_ego::AgentID
end

function Bounds(
    predicate::VelocityLimits,
    agents::AgentsDict,
    unnecessary...
)
    return Bounds(-Inf, Inf, agents.agents[predicate.agent_ego].v_lb, agents.agents[predicate.agent_ego].v_ub)
end

struct PositionLimits <: PredicateSingle
    agent_ego::AgentID
end

function Bounds(
    predicate::PositionLimits,
    agents::AgentsDict,
    unnecessary...
)
    return Bounds(agents.agents[predicate.agent_ego].route.frame.cum_dst[1], agents.agents[predicate.agent_ego].route.frame.cum_dst[end], -Inf, Inf)
end

struct StateLimits <: PredicateSingle
    agent_ego::AgentID
end

function Bounds(
    predicate::StateLimits,
    agents::AgentsDict,
    unnecessary...
)
    return Bounds(
        agents.agents[predicate.agent_ego].route.frame.cum_dst[1], 
        agents.agents[predicate.agent_ego].route.frame.cum_dst[end],
        agents.agents[predicate.agent_ego].v_lb,
        agents.agents[predicate.agent_ego].v_ub
    )
end