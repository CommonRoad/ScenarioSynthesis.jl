import LinearAlgebra.norm, LinearAlgebra.dot

#abstract type Position end
abstract type CoordFrame end
struct FCart <: CoordFrame end
struct FCurv <: CoordFrame end

"""
    Pos{F}

Generic position in coordinate frame `F`.
"""
struct Pos{F<:CoordFrame, T<:Number} <: FieldVector{2, T}
    c1::T # x in case of FCart; s in case of FCurv
    c2::T # y in case of Fcart; d in case of FCurv
end

Pos(::Type{F}, c1::T1, c2::T2) where {F<:CoordFrame, T1<:Number, T2<:Number} = Pos{F, promote_type(T1, T2)}(c1, c2)
Pos(::Type{F}, sv::SVector{2, T}) where {F<:CoordFrame, T<:Number} = Pos{F, T}(sv[1], sv[2])

function pos_matrix2vector(::Type{F}, matrix::Matrix{T}) where {F<:CoordFrame, T<:Number}
    @assert size(matrix)[2] == 2
    return [Pos(F, c1, c2) for (c1, c2) in eachrow(matrix)]
end

"""
    Vec{F}

Generic vector in coordinate frame `F`.
"""
struct Vec{F<:CoordFrame, T<:Number} <: FieldVector{2, T}
    Δc1::T # Δx in case of FCart; Δs in case of FCurv
    Δc2::T # Δy in case of Fcart; Δd in case of FCurv
end

Vec(::Type{F}, Δc1::T1, Δc2::T2) where {F<:CoordFrame, T1<:Number, T2<:Number} = Vec{F, promote_type(T1, T2)}(Δc1, Δc2)
Vec(::Type{F}, sv::SVector{2, T}) where {F<:CoordFrame, T<:Number} = Vec{F, T}(sv[1], sv[2])

function Base.:-(p1::Pos{F}, p2::Pos{F}) where {F<:CoordFrame}
    return Vec(F, p1.c1 - p2.c1, p1.c2 - p2.c2)
end

function distance(p1::Pos{F}, p2::Pos{F}) where {F<:CoordFrame} # TODO does this definiton make sense for FCurv? idea: convert to FCart first, then calculate distance
    vec = p2 - p1
    return norm(vec)
end

struct TransFrame
    ref_pos::Vector{Pos{FCart,Float64}} # reference points, which build the "skeleton" of the curvilinear CoordFrame
    cum_dst::Vector{Float64} # cumulative distance between reference points

    function TransFrame(ref_pos::Vector{Pos{FCart,T}}) where {T<:Number}
        @assert length(ref_pos) ≥ 2
        cum_dst = cumsum(norm.(diff(ref_pos)))
        pushfirst!(cum_dst, 0.0)
        return new(ref_pos, cum_dst)
    end

    function TransFrame()
        return new(Vector{Pos{FCart,Float64}}(), Vector{Float64}())
    end
end

function transform(pos::Pos{FCurv, T}, frame::TransFrame) where {T<:Number}
    0 ≤ pos.c1 < frame.cum_dst[end] || throw(eror("out of bounds"))
    ind = findlast(dst -> dst ≤ pos.c1, frame.cum_dst) # index of preceding reference point--
    p_pre = frame.ref_pos[ind]
    p_suc = frame.ref_pos[ind+1]
    t_normalized = (p_suc - p_pre) / distance(p_pre, p_suc) # tangetial
    n_normalized = SMatrix{2,2,Float64,4}(0, -1, 1, 0) * t_normalized # normal, 90° counter clock-wise
    return p_pre + (pos.c1-frame.cum_dst[ind])*t_normalized + (pos.c2)*n_normalized
end

function transform(pos::Pos{FCart, T}, frame::TransFrame) where {T<:Number}
    vec_to_pos = map(p -> pos-p, frame.ref_pos) # positions of reference points relative to pos
    
    # evaluate distances of reference points to pos
    dst_to_ref_pos = map(x -> norm(x), vec_to_pos)
    closest_ref_pos = findmin(dst_to_ref_pos)

    # evaluate strech in between reference points
    vec_ref_pos = diff(frame.ref_pos)
    vec_ref_length = map(v -> norm(v), vec_ref_pos)
    vec_ref_pos_normalized = vec_ref_pos ./ vec_ref_length
    
    scalar_prod = map(x -> dot(x[1], x[2])/x[3], zip(vec_ref_pos_normalized, vec_to_pos[1:end-1], vec_ref_length))
    
    candidates = findall(x -> 0 < x < 1, scalar_prod) # 0 and 1 are covered by reference points evaluation

    dst_to_streches = map(x -> distance(pos, frame.ref_pos[x] + scalar_prod[x]*vec_ref_pos[x]), candidates)
    closest_strech = findmin(dst_to_streches)


    # choose smallest distance and return Pos{FCurv}
    if closest_strech[1] ≤ closest_ref_pos[1]
        id = candidates[closest_strech[2]]
        s = frame.cum_dst[id] + scalar_prod[id] * vec_ref_length[id]
    else
        id = closest_ref_pos[2]
    end

    t_normalized = vec_ref_pos_normalized[id]
    n_normalized = SMatrix{2,2,Float64,4}(0, -1, 1, 0) * t_normalized
    d = dot(vec_to_pos[id], n_normalized)

    return Pos(FCurv, s, d)
end