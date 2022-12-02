struct Route
    route::Vector{LaneletID}
    frame::TransFrame

    function Route(route::Vector{LaneletID}, ln::LaneletNetwork)
        length(route) ≥ 2 || throw(error("Route must travel at least two LaneSections."))
        for i=1:length(route)-1
            in(route[i+1], ln.lanelets[route[i]].succ) || throw(error("LaneSections of Route must be connected."))
        end

        merged_center_line = Vector{Pos{FCart}}(vcat([ln.lanelets[lsid].vertCntr for lsid in route]...))

        # TODO add algorithms for line smoothing!
        frame = TransFrame(merged_center_line)

        return new(route, frame)
    end
end