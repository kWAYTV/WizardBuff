local _, ns = ...

-- A sound when someone newly needs Intellect. Not on the first look after
-- login, and at most once every few seconds (a wipe makes everyone need it
-- at once).

local intellect = ns.intellect
local GAP = 5
local needed, primed, last = {}, false, 0

function intellect.alert()
    local now, fresh = {}, false
    for _, rec in ipairs(intellect.found.missing) do
        local key = rec.guid or rec.unit
        now[key] = true
        if not needed[key] then fresh = true end
    end
    needed = now
    if not primed then
        primed = true
        return
    end
    if fresh and ns.db.sound and not intellect.testing() and GetTime() - last > GAP then
        last = GetTime()
        PlaySound(SOUNDKIT and SOUNDKIT.TELL_MESSAGE or 3081, "Master")
    end
end
