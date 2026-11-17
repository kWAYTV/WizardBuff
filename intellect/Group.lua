local _, ns = ...

local plain, yes = ns.plain, ns.yes
local intellect = ns.intellect

local function units()
    local list = {}
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local _, _, subgroup = GetRaidRosterInfo(i)
            list[#list + 1] = { unit = "raid" .. i, group = plain(subgroup) or 1 }
        end
    else
        list[1] = { unit = "player", group = 1 }
        for i = 1, GetNumSubgroupMembers() do
            list[#list + 1] = { unit = "party" .. i, group = 1 }
        end
    end
    return list
end

intellect.units = units

-- Everyone in the group, with what's needed to judge them:
--   wants: has mana, so Intellect does something
--   gone:  dead or offline
--   near:  alive, castable on, in range
-- Second result: your own raid group.
function intellect.members()
    local me, myGroup = UnitGUID("player"), 1
    local spell = intellect.rank()
    local list = {}
    for _, rec in ipairs(units()) do
        local unit = rec.unit
        if yes(UnitExists(unit)) then
            local _, class = UnitClass(unit)
            rec.class = plain(class)
            rec.isMe = plain(UnitGUID(unit)) == me
            if rec.isMe then myGroup = rec.group end
            rec.name = plain(UnitName(unit)) or unit
            rec.level = plain(UnitLevel(unit)) or 0
            rec.wants = intellect.wants[rec.class or ""] or false
            rec.gone = not yes(UnitIsConnected(unit)) or yes(UnitIsDeadOrGhost(unit))
            -- Level below 1 means the game can't see them at all.
            rec.near = not rec.gone and (rec.isMe or (rec.level >= 1
                and yes(UnitCanAssist("player", unit)) and ns.inRange(unit, spell)))
            list[#list + 1] = rec
        end
    end
    return list, myGroup
end
