local _, ns = ...

-- Posts who is missing Intellect to the group. The game blocks chat from
-- addons during boss fights.

local intellect = ns.intellect
local GAP = 10
local last = 0

local function channel()
    if LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
    if IsInRaid() then return "RAID" end
    if IsInGroup() then return "PARTY" end
end

function intellect.report()
    local where = channel()
    if not where then return ns.say("Not in a group.") end
    if intellect.testing() then return ns.say("Test is on.") end
    local missing = intellect.found.missing
    if #missing == 0 then return ns.say("Nobody near you is missing Intellect.") end
    if C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then
        return ns.say("Chat is locked right now.")
    end
    if GetTime() - last < GAP then return ns.say("Just sent. Wait a few seconds.") end
    last = GetTime()

    local list = {}
    for i, rec in ipairs(missing) do list[i] = rec.name end
    local text = "No " .. (ns.spellbook.name(intellect.ranks[1]) or "Arcane Intellect") .. ": " .. table.concat(list, ", ")
    if #text > 250 then text = text:sub(1, 247) .. "..." end
    local send = C_ChatInfo.SendChatMessage or SendChatMessage
    send(text, where)
end
