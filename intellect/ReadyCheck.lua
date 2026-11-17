local _, ns = ...

local intellect = ns.intellect

-- On a ready check, call out anyone near you still missing Intellect.
function intellect.onReadyCheck()
    if not ns.db.readyCheck or intellect.testing() then return end
    local missing = intellect.found.missing
    if #missing == 0 then return end
    local list = {}
    for i, rec in ipairs(missing) do list[i] = rec.name end
    ns.say("No Intellect: " .. table.concat(list, ", "))
    PlaySound(SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959, "Master")
end
