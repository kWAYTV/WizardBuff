local _, ns = ...

-- /wb test: a made-up group, so the layout can be looked at while solo.
-- Clicking a made-up person casts nothing. Each call steps on: party, raid,
-- off.

local intellect = ns.intellect

local PEOPLE = {
    { "Anduin", "PRIEST", "missing" }, { "Hamuul", "DRUID", "has", 1400 }, { "Grom", "WARRIOR", "none" },
    { "Rexxar", "HUNTER", "far" }, { "Guldan", "WARLOCK", "has", 3300 }, { "Thrall", "SHAMAN", "missing" },
    { "Uther", "PALADIN", "has", 200 }, { "Valeera", "ROGUE", "none" }, { "Jaina", "MAGE", "has", 2900 },
    { "Tyrande", "PRIEST", "gone" }, { "Malfurion", "DRUID", "has", 900 }, { "Sylvanas", "HUNTER", "missing" },
    { "Velen", "PRIEST", "has", 3500 }, { "Garrosh", "WARRIOR", "none" },
}
local SIZES = { 4, 14 }  -- made-up people in the party and raid previews
local step = 0

function intellect.testing()
    return step > 0
end

function intellect.nextTest()
    step = (step + 1) % (#SIZES + 1)
    ns.say(step == 0 and "Test off." or ("Test: " .. (step == 1 and "party" or "raid") .. ". /wb test again to step on."))
    ns.lookAgain()
end

-- The made-up members, yourself first, already judged.
function intellect.testMembers()
    local raid = step == 2
    local first, full = ns.names("player")
    local _, class = UnitClass("player")
    local list = { {
        unit = raid and "raid1" or "player", group = 1, isMe = true, name = first, full = full,
        class = class, level = 60, wants = true, near = true, state = "has", left = 3000, total = 3600,
    } }
    for i = 1, SIZES[step] do
        local who = PEOPLE[i]
        list[#list + 1] = {
            unit = raid and ("raid" .. (i + 1)) or ("party" .. i), group = raid and math.floor(i / 5) + 1 or 1,
            name = who[1], full = who[1], class = who[2], level = 60, state = who[3],
            wants = who[3] ~= "none", near = who[3] ~= "far" and who[3] ~= "gone",
            left = who[4], total = who[4] and 3600 or nil,
        }
    end
    return list
end
