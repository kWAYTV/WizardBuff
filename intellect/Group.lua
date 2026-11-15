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

-- Everyone who could use Intellect, each tagged near or not. Left out:
-- offline, dead, no mana, and anyone you can't cast on (mind control, duels).
-- Second result: your own raid group.
function intellect.members()
    local me, myGroup = UnitGUID("player"), 1
    local spell = intellect.rank()
    local list = {}
    for _, rec in ipairs(units()) do
        local unit = rec.unit
        local _, class = UnitClass(unit)
        rec.isMe = plain(UnitGUID(unit)) == me
        if rec.isMe then myGroup = rec.group end
        if yes(UnitExists(unit)) and yes(UnitIsConnected(unit)) and not yes(UnitIsDeadOrGhost(unit))
            and intellect.wants[plain(class) or ""] and (rec.isMe or yes(UnitCanAssist("player", unit))) then
            rec.name = plain(UnitName(unit)) or unit
            rec.level = plain(UnitLevel(unit)) or 0
            rec.near = rec.isMe or ns.inRange(unit, spell)
            list[#list + 1] = rec
        end
    end
    return list, myGroup
end
