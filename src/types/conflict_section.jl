struct ConflictSectionManager
    csm::Dict{Tuple{LaneletID, LaneletID}, ConflictSectionID}

    function ConflictSectionManager()
        return new(Dict{Tuple{LaneletID, LaneletID}, ConflictSectionID}())
    end
end

next_conflict_section_id(csm::ConflictSectionManager) = isempty(csm.csm) ? 1 : maximum(values(csm.csm)) + 1

function get_conflict_section_id!(csm::ConflictSectionManager, ltid1::LaneletID, ltid2::LaneletID)
    tup = (min(ltid1, ltid2), max(ltid1, ltid2))
    
    haskey(csm.csm, tup) ? nothing : csm.csm[tup] = next_conflict_section_id(csm)
    return csm.csm[tup]
end