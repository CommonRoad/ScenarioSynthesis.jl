const SectionID = Int64

struct LaneID
    lon::SectionID
    lat::Int64
end

struct CurvlinCosy # TODO place in correct file. 
    reference_path::Vector{Pos{FCart}}
    length::Float64
    segment_longitudinal_coord::Vector{Float64}
    #default_projection_domain_limit::Float64
    #curvature_radius_lims::Tuple{Float64,Float64}
    #curvature_lims::Tuple{Float64,Float64}

    function CurvlinCosy(
        reference_path::Vector{Pos{FCart}}
        #default_projection_domain_limit::Number,
        #eps::Number
    )
        length(reference_path) ≥ 2 || throw(error("Reference path must have at least 3 points."))
        length = 0.0 
        segment_longitudinal_coord = Vector{Float64}(undef, length(reference_path))
        segment_longitudinal_coord[1] = 0.0

        for i=2:length(reference_path)
            length += distance(reference_path[i-1], reference_path[i])
            segment_longitudinal_coord[i] = length
        end

        @assert issorted(segment_longitudinal_coord)

        new(reference_path, length, segment_longitudinal_coord)
    end
end

#=
function Pos{FCart}(
    p::PosCurv,
    cosy::CurvlinCosy
)
    base_ind = findlast(pos -> pos.s ≤ p.s, cosy.reference_path)
    # TODO tangent = SVector{2,Float64}()
end
=#

struct Lane
    lane_id::LaneID
    lanelet_ids::Vector{Int64}
    successors::Set{Int64}
    predecessors::Set{Inf64}
    is_main_lane::Bool
    merging_lane_ids::Set{LaneID}
    lanelet::Vector{Lanelet}
    center_line::Vector{Pos{FCart}}
    cosy::CurvlinCosy
    s_range::Tuple{Float64,Float64}
end

struct LaneSection

end

struct LaneSectionNetwork

end

struct Route
    # TODO content
end