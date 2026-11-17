local _, ns = ...

local intellect = ns.intellect

-- What the last look at the group found.
intellect.found = {
    members = {},    -- everyone, each with a state (see grid.STATE)
    missing = {},    -- those near you who need it, next target first
    soonest = nil,   -- seconds until the first one near you runs out
    soonestOn = nil, -- and who that is
    stale = false,   -- couldn't read buffs; this is the last reading
}

-- Out of sight, a unit reports no buffs at all, so only people in range are
-- judged. Returns false (and keeps the last reading) when buffs can't be read.
function intellect.scan()
    local found = intellect.found
    if not ns.auras.readable(intellect.family) then
        found.stale = true
        return false
    end

    local remind = ns.db.remind * 60
    local missing, soonest, soonestOn = {}, nil, nil
    local members, myGroup = intellect.members()
    for _, rec in ipairs(members) do
        if not rec.wants then
            rec.state = "none"
        elseif rec.gone then
            rec.state = "gone"
        elseif not rec.near then
            rec.state = "far"
        else
            local has, left, total = ns.auras.has(rec.unit, intellect.family)
            if has == nil then
                found.stale = true
                return false
            end
            rec.left, rec.total = left, total
            rec.state = (not has and "missing") or (left and left < remind and "soon") or "has"
            if left and (not soonest or left < soonest) then soonest, soonestOn = left, rec end
            if rec.state ~= "has" then missing[#missing + 1] = rec end
        end
    end

    -- You, then your group, then the rest.
    for i, rec in ipairs(missing) do
        rec.order = (rec.isMe and 0 or rec.group == myGroup and 100 or 200) + i
    end
    table.sort(missing, function(a, b) return a.order < b.order end)

    found.members, found.missing = members, missing
    found.soonest, found.soonestOn = soonest, soonestOn
    found.stale = false
    return true
end

function intellect.needed()
    return #intellect.found.missing > 0
end
