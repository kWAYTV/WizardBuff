local _, ns = ...

-- Group members in display order, rebuilt out of combat.
-- Each record: unit, guid, name, class, group, level, isPet, isMe, owner,
-- dead, offline, inRange, int ("yes" | "no" | "unknown"), expires, duration.
ns.members = {}
ns.byGuid = {}

-- Last known Intellect reading per GUID. Survives combat (when auras are
-- unreadable) and roster rebuilds.
local lastSeen = {}

local INT_DURATION = 3600

local function flag(fn, unit)
    local v = ns.SafeCall(fn, unit)
    return v and true or false
end

local function readInt(rec)
    local state, expires, duration = ns.ReadIntellect(rec.unit)
    local prev = lastSeen[rec.guid]
    if state == "unknown" then
        if prev then state, expires, duration = prev.state, prev.expires, prev.duration end
    else
        lastSeen[rec.guid] = { state = state, expires = expires, duration = duration }
    end
    -- A predicted buff that hasn't shown up yet stays until it would expire.
    if state == "no" and prev and prev.predicted and (ns.Remaining(prev.expires) or 0) > 0
        and GetTime() - prev.predicted < 10 then
        state, expires, duration = "yes", prev.expires, prev.duration
        lastSeen[rec.guid] = prev
    end
    rec.int, rec.expires, rec.duration = state, expires or 0, duration or 0
end

local function add(unit, group, isPet, owner)
    if not UnitExists(unit) then return end
    local guid = ns.SafeCall(UnitGUID, unit)
    local name = ns.SafeCall(UnitName, unit)
    if not guid or not name then return end
    local class
    if isPet then
        class = "PET"
    else
        local _, token = ns.SafeCall(UnitClass, unit)
        class = token or "WARRIOR"
    end
    local rec = {
        unit = unit, guid = guid, name = name, class = class, group = group,
        level = ns.SafeCall(UnitLevel, unit) or 0,
        isPet = isPet, owner = owner,
        isMe = guid == UnitGUID("player"),
        dead = flag(UnitIsDeadOrGhost, unit),
        offline = not isPet and not flag(UnitIsConnected, unit),
    }
    readInt(rec)
    ns.members[#ns.members + 1] = rec
    ns.byGuid[guid] = rec
end

function ns.ScanRoster()
    if InCombatLockdown() then return end
    wipe(ns.members)
    wipe(ns.byGuid)
    local pets = ns.db.showPets
    local petList = {}

    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local unit = "raid" .. i
            local _, _, subgroup = GetRaidRosterInfo(i)
            add(unit, subgroup or 1, false)
            if pets and UnitExists("raidpet" .. i) then
                petList[#petList + 1] = { "raidpet" .. i, subgroup or 1, UnitGUID(unit) }
            end
        end
    elseif IsInGroup() or ns.db.showSolo then
        add("player", 1, false)
        if pets and UnitExists("pet") then petList[#petList + 1] = { "pet", 1, UnitGUID("player") } end
        for i = 1, GetNumSubgroupMembers() do
            add("party" .. i, 1, false)
            if pets and UnitExists("partypet" .. i) then
                petList[#petList + 1] = { "partypet" .. i, 1, UnitGUID("party" .. i) }
            end
        end
    end

    for _, p in ipairs(petList) do add(p[1], p[2], true, p[3]) end

    -- Members sort by group, then class, then name; pets after players.
    table.sort(ns.members, function(a, b)
        if a.isPet ~= b.isPet then return not a.isPet end
        if a.group ~= b.group then return a.group < b.group end
        if a.class ~= b.class then return a.class < b.class end
        return a.name < b.name
    end)

    for guid in pairs(lastSeen) do
        if not ns.byGuid[guid] then lastSeen[guid] = nil end
    end

    ns.UpdateRange()
end

local function inRange(rec)
    if rec.isMe then return true end
    if not ns.SafeCall(UnitIsVisible, rec.unit) then return false end
    local id = ns.Best("INTELLECT")
    if id then
        local r = ns.SafeCall(C_Spell.IsSpellInRange, id, rec.unit)
        if r ~= nil then return r and true or false end
    end
    local r, checked = ns.SafeCall(UnitInRange, rec.unit)
    if checked then return r and true or false end
    return true
end

function ns.UpdateRange()
    for _, rec in ipairs(ns.members) do
        rec.inRange = inRange(rec)
    end
end

-- Called after one of our casts lands, so the grid updates before
-- (or, in combat, instead of) the next aura read.
function ns.PredictIntellect(guid)
    local exp = GetTime() + INT_DURATION
    lastSeen[guid] = { state = "yes", expires = exp, duration = INT_DURATION, predicted = GetTime() }
    local rec = ns.byGuid[guid]
    if rec then rec.int, rec.expires, rec.duration = "yes", exp, INT_DURATION end
end

function ns.PredictIntellectAll()
    for _, rec in ipairs(ns.members) do
        if rec.inRange and not rec.dead and not rec.offline then ns.PredictIntellect(rec.guid) end
    end
end

function ns.IntRemaining(rec)
    if rec.int ~= "yes" then return nil end
    return ns.Remaining(rec.expires)
end

function ns.GroupCount()
    local seen, n = {}, 0
    for _, rec in ipairs(ns.members) do
        if not seen[rec.group] then seen[rec.group] = true; n = n + 1 end
    end
    return n
end
