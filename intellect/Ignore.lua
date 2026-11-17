local _, ns = ...

-- Middle-click a person to stop asking for their buff. Forgotten at the
-- next loading screen.

local intellect = ns.intellect
local ignored = {}  -- GUID -> true

function intellect.isIgnored(guid)
    return guid ~= nil and ignored[guid] == true
end

function intellect.toggleIgnore(rec)
    if not (rec and rec.guid) then return end
    ignored[rec.guid] = not ignored[rec.guid] or nil
    ns.lookAgain()
end

function intellect.forgetIgnored()
    wipe(ignored)
end
