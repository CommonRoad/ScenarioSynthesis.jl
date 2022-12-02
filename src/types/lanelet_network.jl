import PythonCall.@pyexec, PythonCall.Py, PythonCall.pyconvert

struct LaneletNetwork
    lanelets::Dict{LaneletID, Lanelet}
    trafficSigns::Dict{TrafficSignID, TrafficSign}
    trafficLights::Dict{TrafficLightID, TrafficLight}
end

function ln_from_path(path::String)
    @pyexec path => """
    # import 
    from commonroad.common.file_reader import CommonRoadFileReader
    from commonroad.scenario.lanelet import Lanelet

    # read data
    scenario, planning_problem = CommonRoadFileReader(path).open()
    lanelet_network = scenario._lanelet_network

    ##############################################################
    # TODO every python code below could be removed              #
    ##############################################################

    # additional inits
    section_ids = set()

    lanelet2section_id = {}
    # sort by lanelet id (important, since lane_ids will be named consistently)
    lanelet_ids, lanelets = zip(*lanelet_network._lanelets.items())
    lanelet_ids, lanelets = zip(*sorted(zip(lanelet_ids, lanelets)))

    # going from right to left lanelet
    for lanelet_id, lanelet in zip(lanelet_ids, lanelets):
        if lanelet_id in lanelet2section_id or lanelet.adj_right is not None:
            # ensures starting at right-most lanelet
            continue

        # create new section # was: sec_id = self.generate_lane_section_id()
        if len(section_ids) > 0:
            sec_id = max(section_ids) + 1
        else:
            sec_id = 1

        section_ids.add(sec_id)

        lanelets_tmp = [lanelet]
        next_lanelet: Lanelet = lanelet

        while next_lanelet.adj_left is not None and next_lanelet.adj_left_same_direction:
            next_lanelet = lanelet_network.find_lanelet_by_id(next_lanelet.adj_left)
            lanelets_tmp.append(next_lanelet)

        # self._sections[sec_id] = Lanelet(sec_id, lanelets_tmp)
        lane_id = 0
        for lanelet in lanelets_tmp:
            lane_id += 1
            lanelet2section_id[lanelet.lanelet_id] = (sec_id, lane_id)
    """ => (lanelet2section_id, lanelet_network)

    return py2jl_lanelet_network(lanelet_network)
end

function py2jl_lanelet_network(
    ln::Py
)
    lanelets = Dict{LaneletID, Lanelet}()
    for lt in ln.lanelets
        lanelets[pyconvert(LaneletID, lt.lanelet_id)] = py2jl_lanelet(lt, ln) # TODO interection checking will probably require additional argument ln.intersections
    end

    trafficSigns = Dict{TrafficSignID, TrafficSign}()
    for ts in ln.traffic_signs
        trafficSigns[pyconvert(TrafficSignID, ts.traffic_sign_id)] = py2jl_traffic_sign(ts)
    end

    trafficLights = Dict{TrafficLightID, TrafficLight}()
    for tl in ln.traffic_lights
        trafficLights[pyconvert(TrafficLightID, tl.id)] = py2jl_traffic_light(tl)
    end

    return LaneletNetwork(lanelets, trafficSigns, trafficLights)
end

function py2jl_traffic_sign(ts::Py)
    elements = Vector{TrafficSignElement}()

    for tse in ts.traffic_sign_elements
        try 
            push!(elements, py2jl_traffic_sign_element(tse))
        catch e
            @warn "traffic sign element could not be converted. skipping."
        end
    end
    
    position = Pos(FCart, pyconvert(Vector{Float64}, ts.position)...)
    is_virtual = pyconvert(Bool, ts.virtual)
    
    return TrafficSign(
        elements, 
        position,
        is_virtual
    )
end

function py2jl_traffic_sign_element(tse::Py)
    tseid = parse(Int64, pyconvert(String, tse.traffic_sign_element_id))
    add_val = pyconvert(Vector{Float64}, tse.additional_values)
    
    return TrafficSignElement(
        tseid, 
        add_val
    )
end

function py2jl_traffic_light(tl::Py)
    @warn "traffic light conversion not implemented yet. return dummy."
    return TrafficLight(
        TL_Cycle(
            [TL_CycleElement(
                20.0,
                TL_Green
            ),
            TL_CycleElement(
                20.0,
                TL_Red
            )],
            2.0
        ),
        Pos(FCurv, 0.0, 0.0),
        TL_All,
        true
    )
end

function py2jl_lanelet(lt::Py, ln::Py)
    ltid = pyconvert(LaneletID, lt.lanelet_id)
    boundLeft = Bound(Left, [Pos(FCart, x, y) for (x, y) in eachrow(pyconvert(Array, lt.left_vertices))], LM_Unknown) # TODO add conversion for LineMarking
    boundRght = Bound(Right, [Pos(FCart, x, y) for (x, y) in eachrow(pyconvert(Array, lt.right_vertices))], LM_Unknown)
    vertCntr = [Pos(FCart, x, y) for (x, y) in eachrow(pyconvert(Array, lt.center_vertices))]

    pred = Set(pyconvert(Vector{LaneletID}, lt.predecessor))
    succ = Set(pyconvert(Vector{LaneletID}, lt.successor))

    adjLeft = try
        Adjacent(Left, pyconvert(LaneletID, lt.adj_left_id), pyconvert(Bool, lt.adj_left_same_direction))
    catch e
        Adjacent(Left)
    end

    adjRght = try
        Adjacent(Right, pyconvert(LaneletID, lt.adj_right_id), pyconvert(Bool, lt.adj_right_same_direction)) 
    catch e
        Adjacent(Right)
    end

    stopLine = StopLine() # TODO add conversion!!
    laneletType = Set{LaneletType}([LT_Unknown]) # TODO add conversion
    userOneWay = Set{RoadUserType}()
    userBidirectional = Set{RoadUserType}()
    trafficSign = Set{TrafficSignID}()
    trafficLight = Set{TrafficLightID}()
    
    merging_with = Set{LaneletID}()
    for s in pyconvert(Array, lt.successor)
        union!(merging_with, Set(pyconvert(Array, ln.find_lanelet_by_id(s).predecessor)))
    end
    delete!(merging_with, ltid)

    diverging_with = Set{LaneletID}()
    for p in pyconvert(Array, lt.predecessor)
        union!(diverging_with, Set(pyconvert(Array, ln.find_lanelet_by_id(p).successor)))
    end
    delete!(diverging_with, ltid)

    intersecting_with = Set{LaneletID}()

    return Lanelet(
        boundLeft,
        boundRght,
        vertCntr,
        pred,
        succ,
        adjLeft,
        adjRght,
        stopLine,
        laneletType,
        userOneWay,
        userBidirectional,
        trafficSign,
        trafficLight,
        merging_with,
        diverging_with,
        intersecting_with
    )

end