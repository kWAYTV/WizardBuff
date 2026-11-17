local _, ns = ...

local intellect = ns.intellect

-- What the last look at the group found.
intellect.found = {
    members = {},    -- everyone, each with a state (see grid.LOOK)
    missing = {},    -- those near you who need it, next target first
    have = 0,        -- how many of the people who can be judged have it
    total = 0,       -- and how many can be judged
    soonest = nil,   -- seconds until the first one near you runs out
    stale = false,   -- couldn't read buffs; this is the last reading
}

-- Sets rec.state. Out of sight, a unit reports no buffs at all, so only
-- people in range are judged. Returns false when buffs can't be read.
local function judge(rec, remind)
    if not rec.wants then
        rec.state = "none"
    elseif rec.gone then
        rec.state = "gone"
    elseif intellect.isIgnored(rec.guid) then
        rec.state = "skip"
    elseif not rec.near then
        rec.state = "far"
    else
        local has, left, total = ns.auras.has(rec.unit, intellect.family)
        if has == nil then return false end
        rec.left, rec.total = left, total
        rec.state = (not has and "missing") or (left and left < remind and "soon") or "has"
    end
    return true
end

-- Returns false (and keeps the last reading) when buffs can't be read.
function intellect.scan()
    local found = intellect.found
    local testing = intellect.testing()
    if not testing and not ns.auras.readable(intellect.family) then
        found.stale = true
        return false
    end

    local members, myGroup
    if testing then
        members, myGroup = intellect.testMembers(), 1
    else
        members, myGroup = intellect.members()
    end

    local remind = ns.db.remind * 60
    local missing, have, total, soonest = {}, 0, 0, nil
    for _, rec in ipairs(members) do
        if not testing and not judge(rec, remind) then
            found.stale = true
            return false
        end
        local state = rec.state
        if state == "has" or state == "soon" or state == "missing" then
            total = total + 1
            if state == "has" then have = have + 1 else missing[#missing + 1] = rec end
            if rec.left and (not soonest or rec.left < soonest) then soonest = rec.left end
        end
    end

    -- You, then your group, then the rest.
    for i, rec in ipairs(missing) do
        rec.order = (rec.isMe and 0 or rec.group == myGroup and 100 or 200) + i
    end
    table.sort(missing, function(a, b) return a.order < b.order end)

    found.members, found.missing = members, missing
    found.have, found.total, found.soonest = have, total, soonest
    found.stale = false
    return true
end

function intellect.needed()
    return #intellect.found.missing > 0
end
