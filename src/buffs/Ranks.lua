local _, ns = ...

function ns.GetHighestRankSpell(list)
    if not list then return nil, nil end
    for i = #list, 1, -1 do
        local id = list[i]
        if ns.IsSpellKnown(id) then
            local name = ns.GetSpellName(id)
            if name then return name, id end
        end
    end
    return nil, nil
end

local function rankedName(id, rankIndex)
    local name = ns.GetSpellName(id)
    if not name then return nil end
    local sub = ns.GetSpellSubtext(id)
    if sub and sub ~= "" then return name .. "(" .. sub .. ")" end
    if rankIndex then return name .. "(Rank " .. rankIndex .. ")" end
    return name
end

function ns.GetBestRankForUnit(unit, list)
    if not list then return nil, nil end
    local targetLevel = unit and UnitExists(unit) and UnitLevel(unit)
    if not targetLevel or targetLevel < 1 then
        return ns.GetHighestRankSpell(list)
    end
    for i = #list, 1, -1 do
        local id = list[i]
        if ns.IsSpellKnown(id) then
            if targetLevel >= (ns.SPELL_MIN_TARGET_LEVEL[id] or 1) then
                local name = ns.GetSpellName(id)
                if name then return rankedName(id, i), id end
            end
        end
    end
    return nil, nil
end

function ns.AnyRankKnown(key)
    local ids = ns.SpellIDs[key]
    if not ids then return false end
    for i = #ids, 1, -1 do
        if ns.IsSpellKnown(ids[i]) then return true end
    end
    return false
end
