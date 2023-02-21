import LightXML.parse_file, LightXML.root, LightXML.free, LightXML.XMLElement, LightXML.attribute, LightXML.name, LightXML.content

struct LaneletNetwork
    lanelets::Dict{LaneletID, Lanelet}
    trafficSigns::Dict{TrafficSignID, TrafficSign}
    trafficLights::Dict{TrafficLightID, TrafficLight}
    intersections::Dict{IntersectionID, Intersection}
    conflict_sections::Dict{ConflictSectionID, Tuple{LaneletID, LaneletID}}
end

function ln_from_xml(path::String) # path either asolute or relative
    xmlfile = parse_file(path)
    xmlroot = root(xmlfile)
    xml_tags = xmlroot["tags"]
    xml_location = xmlroot["location"]
    xml_lanelet = xmlroot["lanelet"]
    xml_trafficSign = xmlroot["trafficSign"]
    xml_trafficLight = xmlroot["trafficLight"]
    xml_intersection = xmlroot["intersection"]
    xml_staticObstacle = xmlroot["staticObstacle"]
    xml_dynamicObstacle = xmlroot["dynamicObstacle"]
    xml_environmentObstacle = xmlroot["environmentObstacle"]
    xml_planningProblem = xmlroot["planningProblem"]
    
    # not all information are processed atm
    lanelets = Dict{LaneletID, Lanelet}()
    trafficSigns = Dict{TrafficSignID, TrafficSign}()
    trafficLights = Dict{TrafficLightID, TrafficLight}()
    intersections = Dict{IntersectionID, Intersection}()
    conflict_sections = Dict{ConflictSectionID, Tuple{LaneletID, LaneletID}}()

    for lt in xml_lanelet
        lanelets[parse(LaneletID, attribute(lt, "id"))] = Lanelet(lt)
    end
    for ts in xml_trafficSign
        trafficSigns[parse(TrafficSignID, attribute(ts, "id"))] = TrafficSign(ts)
    end
    for tl in xml_trafficLight
        trafficLights[parse(TrafficLightID, attribute(tl, "id"))] = TrafficLight(tl)
    end
    for intersec in xml_intersection
        intersections[parse(IntersectionID, attribute(intersec, "id"))] = Intersection(intersec)
    end

    free(xmlfile)
    return LaneletNetwork(lanelets, trafficSigns, trafficLights, intersections, conflict_sections)
end

function Lanelet(lt::XMLElement)
    @assert name(lt) == "lanelet" 
    boundLeft = Bound(Left, lt["leftBound"][1])
    boundRght = Bound(Right, lt["rightBound"][1])
    @assert length(boundLeft.vertices) == length(boundRght.vertices)
    vertCntr = [(l+r)/2 for (l,r) in zip(boundLeft.vertices, boundRght.vertices)]
    pred = Set(map(x -> parse(LaneletID, attribute(x, "ref")), lt["predecessor"]))
    succ = Set(map(x -> parse(LaneletID, attribute(x, "ref")), lt["successor"]))
    adjLeft = Adjacent(Left, lt["adjacentLeft"])
    adjRght = Adjacent(Right, lt["adjacentRight"])
    stopLine = StopLine(lt["stopLine"])
    laneletType = LaneletTypes(lt["laneletType"])
    userOneWay = RoadUserTypes(lt["userOneWay"])
    userBidirectional = RoadUserTypes(lt["userBidirectional"])
    trafficSign = Set(map(x -> parse(TrafficSignID, x), lt["trafficSign"]))
    trafficLight = Set(map(x -> parse(TrafficSignID, x), lt["trafficLight"]))

    return Lanelet(
        boundLeft, boundRght, vertCntr, pred, succ, adjLeft, adjRght, stopLine, laneletType, userOneWay, userBidirectional, trafficSign, trafficLight
    )
end

function Bound(::Type{S}, bound::XMLElement) where {S<:Side}
    if typeof(S) == Right
        @assert name(bound) == "rightBound"
    elseif typeof(S) == Left
        @assert name(bound) == "leftBound"
    end

    if length(bound["lineMarking"]) == 1
        return Bound(S, [Pos(point) for point in bound["point"]], linemarking_typer(content(bound["lineMarking"][1])))
    else
        return Bound(S, [Pos(point) for point in bound["point"]])
    end
end

function Adjacent(::Type{S}, adj::Vector{XMLElement}) where {S<:Side}
    length(adj) == 1 || return Adjacent(S)
    if typeof(S) == Right
        @assert name(adj[1]) == "adjacentRight"
    elseif typeof(S) == Left
        @assert name(adj[1]) == "adjacentLeft"
    end
    return Adjacent(S, parse(LaneletID, attribute(adj[1], "ref")), attribute(adj[1], "drivingDir") == "same")
end

function StopLine(stopline::Vector{XMLElement})
    length(stopline) ≤ 0 && return StopLine()
    if length(stopline) == 1
        lm = linemarking_typer(content(stopline[1]["lineMarking"][1]))
        pos1 = try
            Pos(stopline[1]["point"][1])
        catch e
            @warn e
            Nothing
        end
        pos2 = try
            Pos(stopline[1]["point"][2])
        catch e
            @warn e
            Nothing
        end
        ref_to_traffic_sign = try
            parse(TrafficSignID, content(stopline[1]["trafficSignRef"][1]))
        catch e
            @warn e
            Nothing
        end
        ref_to_traffic_light = try
            parse(TrafficSignID, content(stopline[1]["trafficLightRef"][1]))
        catch e
            @warn e
            Nothing
        end
        return StopLine(lm, pos1, pos2, ref_to_traffic_sign, ref_to_traffic_light)
    end
    length(stopline > 1) && throw(error("failure in xml file."))
end

function LaneletTypes(vec::Vector{XMLElement})
    ltts = Set{LaneletType}()
    length(vec) ≥ 1 && @assert name(vec[1]) == "laneletType"
    for elem in vec
        push!(ltts, lanelet_typer(content(elem)))
    end
    return ltts
end

function RoadUserTypes(vec::Vector{XMLElement})
    ruts = Set{RoadUserType}()
    length(vec) ≥ 1 && @assert name(vec[1]) == "roadUserType"
    for elem in vec
        push!(ruts, roaduser_typer(content(elem)))
    end
    return ruts
end

function TrafficSign(ts::XMLElement)
    elements = map(tse -> TrafficSignElement(tse), ts["trafficSignElement"])
    if length(ts["position"]) == 1
        position, has_position = Pos(ts["position"][1]["point"][1]), true
    else
        position, has_position = Pos(FCart, Inf64, Inf64), false
    end
    is_virtual = false
    length(ts["virtual"]) == 1 ? is_virtual = parse(Bool, content(ts["virtual"][1])) : nothing
    return TrafficSign(elements, position, has_position, is_virtual)
end

function TrafficSignElement(tse::XMLElement)
    @assert name(tse) == "trafficSignElement"
    type_id = parse(TrafficSignTypeID, content(tse["trafficSignID"][1]))
    additional_values = parse.(Float64, content.(tse["additionalValue"]))
    return TrafficSignElement(type_id, additional_values)
end

function Pos(point::XMLElement)
    @assert name(point) == "point"
    return Pos(FCart, parse(Float64, content(point["x"][1])), parse(Float64, content(point["y"][1])))
end

function TrafficLight(tl::XMLElement)
    throw(error("functionality not implemented yet."))   
end

function Intersection(intersec::XMLElement)
    @assert length(intersec["incoming"]) ≥ 2 # from XML commonroad definition
    incomings = Dict{IncomingID, Incoming}()
    for incom in intersec["incoming"]
        incomings[parse(IncomingID, attribute(incom, "id"))] = Incoming(incom)
    end
    return Intersection(incomings)
end

function Incoming(incom::XMLElement)
    incomingLanelets = Set(parse.(LaneletID, attribute.(incom["incomingLanelet"], "ref")))
    succRight = Set(parse.(LaneletID, attribute.(incom["successorsRight"], "ref")))
    succStraight = Set(parse.(LaneletID, attribute.(incom["successorsStraight"], "ref")))
    succLeft = Set(parse.(LaneletID, attribute.(incom["successorsLeft"], "ref")))
    is_left_of = -1
    has_left_neighbor = false
    length(incom["isLeftOf"]) == 0 || length(incom["isLeftOf"]) == 1 || throw(error("wrong size. failure in imported xml file."))
    if length(incom["isLeftOf"]) == 1
        is_left_of = parse.(IncomingID, attribute.(incom["isLeftOf"], "ref"))[1]
        has_left_neighbor = true
    end
    
    return Incoming(incomingLanelets, succRight, succStraight, succLeft, is_left_of, has_left_neighbor)
end

function process!(ln::LaneletNetwork)
    # merging with
    for ltid in keys(ln.lanelets)
        for pred in ln.lanelets[ltid].pred
            for p in ln.lanelets[ltid].pred
                pred == p && continue
                push!(ln.lanelets[pred].merging_with, p)
            end
        end
    end

    # diverging with
    for ltid in keys(ln.lanelets)
        for succ in ln.lanelets[ltid].succ
            for s in ln.lanelets[ltid].succ
                succ == s && continue
                push!(ln.lanelets[succ].diverging_with, s)
            end
        end
    end

    # intersecting with -- logic based
    for (k, intersection) in ln.intersections
        for (k, incoming) in intersection.incomings
            if incoming.has_right_neighbor
                for in_str in incoming.succStraight
                    union!(ln.lanelets[in_str].intersecting_with, intersection.incomings[incoming.right_neighbor].succStraight)
                    union!(ln.lanelets[in_str].intersecting_with, intersection.incomings[incoming.right_neighbor].succLeft)
                end
                for in_left in incoming.succLeft
                    union!(ln.lanelets[in_left].intersecting_with, intersection.incomings[incoming.right_neighbor].succLeft)
                end
            end
            left_neighbor, has_left_neighbor = left_neighbor_func(k, intersection)
            if has_left_neighbor
                for in_str in incoming.succStraight
                    union!(ln.lanelets[in_str].intersecting_with, intersection.incomings[left_neighbor].succStraight)
                end
                for in_left in incoming.succLeft
                    union!(ln.lanelets[in_left].intersecting_with, intersection.incomings[left_neighbor].succStraight)
                    union!(ln.lanelets[in_left].intersecting_with, intersection.incomings[left_neighbor].succLeft)
                end
            end
            opposite_incoming, has_opposite_incoming = opposite_neighbor_func(k, intersection)
            if has_opposite_incoming
                for in_str in incoming.succStraight
                    union!(ln.lanelets[in_str].intersecting_with, intersection.incomings[opposite_incoming].succLeft)
                end
                for in_left in incoming.succLeft
                    union!(ln.lanelets[in_left].intersecting_with, intersection.incomings[opposite_incoming].succStraight)
                end
            end
        end
    end

    # conflict sections
    csm = ConflictSectionManager()
    for (own, own_lt) in ln.lanelets
        for obs in own_lt.merging_with
            conflict_section, does_conflict = conflict_section_merging(ln, own, obs)
            if does_conflict
                id = get_conflict_section_id!(csm, own, obs)
                own_lt.conflict_sections[id] = conflict_section
            end
        end
        for obs in own_lt.diverging_with
            conflict_section, does_conflict = conflict_section_diverging(ln, own, obs)
            if does_conflict
                id = get_conflict_section_id!(csm, own, obs)
                own_lt.conflict_sections[id] = conflict_section
            end
        end
        for obs in own_lt.intersecting_with
            conflict_section, does_conflict = conflict_section_intersecting(ln, own, obs)
            if does_conflict
                id = get_conflict_section_id!(csm, own, obs)
                own_lt.conflict_sections[id] = conflict_section
            end
        end
    end
    
    for (k, v) in csm.csm
        ln.conflict_sections[v] = k
    end
end

function conflict_section_merging(ln::LaneletNetwork, own::LaneletID, obs::LaneletID, n_iter::Integer=8)
    own_lt = ln.lanelets[own]
    obs_lt = ln.lanelets[obs]
    
    # handling edge cases
    is_intersect(Polygon(own_lt), Polygon(obs_lt)) || return (Inf64, -Inf64), false # no collision
   
    # bisection
    s_low = 0.0
    s_upp = own_lt.frame.cum_dst[end]
    for iter in 1:n_iter
        s = (s_low + s_upp) / 2
        if is_intersect(Polygon_cut_from_start(own_lt, s), Polygon(obs_lt))
            s_upp = s
        else
            s_low = s
        end
    end

    @assert s_low ≤ own_lt.frame.cum_dst[end]

    return (s_low, own_lt.frame.cum_dst[end] - 1e-3), true # s_low is safe side
end

function conflict_section_diverging(ln::LaneletNetwork, own::LaneletID, obs::LaneletID, n_iter::Integer=8)
    own_lt = ln.lanelets[own]
    obs_lt = ln.lanelets[obs]
    
    # handling edge cases
    is_intersect(Polygon(own_lt), Polygon(obs_lt)) || return (Inf64, -Inf64), false # no collision

    # bisection
    e_low = 0.0
    e_upp = own_lt.frame.cum_dst[end]
    for iter in 1:n_iter
        e = (e_low + e_upp) / 2
        if is_intersect(Polygon_cut_from_end(own_lt, e), Polygon(obs_lt))
            e_upp = e
        else
            e_low = e
        end
    end

    @assert 0.0 ≤ own_lt.frame.cum_dst[end] - e_low

    return (0.0, own_lt.frame.cum_dst[end] - e_low - 1e-3), true # e_low is safe side
end

function conflict_section_intersecting(ln::LaneletNetwork, own::LaneletID, obs::LaneletID, n_iter::Integer=8)
    own_lt = ln.lanelets[own]
    obs_lt = ln.lanelets[obs]
    
    # handling edge cases
    is_intersect(Polygon(own_lt), Polygon(obs_lt)) || return (Inf64, -Inf64), false # no collision

    # bisection
    s_low = 0.0
    s_upp = own_lt.frame.cum_dst[end]
    for iter in 1:n_iter
        s = (s_low + s_upp) / 2
        if is_intersect(Polygon_cut_from_start(own_lt, s), Polygon(obs_lt))
            s_upp = s
        else
            s_low = s
        end
    end

    e_low = 0.0
    e_upp = own_lt.frame.cum_dst[end]
    for iter in 1:n_iter
        e = (e_low + e_upp) / 2
        if is_intersect(Polygon_cut_from_end(own_lt, e), Polygon(obs_lt))
            e_upp = e
        else
            e_low = e
        end
    end

    @assert s_low ≤ own_lt.frame.cum_dst[end] - e_low 
    
    return (s_low, own_lt.frame.cum_dst[end] - e_low - 1e-3), true # both end are on safe side
end