local _, ns = ...

local function playReminder()
    PlaySoundFile(ns._soundKind == "self" and ns.SOUND_SELF or ns.SOUND_GROUP, "Master")
end

function ns.UpdateSoundReminder(selfSoundKind, groupNeedsAction)
    local d = ns.db
    if not d or not d.showSound then
        if ns._soundTicker then ns._soundTicker:Cancel(); ns._soundTicker = nil end
        ns._soundActive = false
        return
    end
    local kind = selfSoundKind or (groupNeedsAction and "group") or nil
    local wasActive, kindChanged = ns._soundActive, ns._soundKind ~= kind
    ns._soundActive, ns._soundKind = kind ~= nil, kind
    if kind then
        if not wasActive or kindChanged then
            playReminder()
            if ns._soundTicker then ns._soundTicker:Cancel() end
            ns._soundTicker = C_Timer.NewTicker(ns.SOUND_INTERVAL, playReminder)
        end
    elseif ns._soundTicker then
        ns._soundTicker:Cancel()
        ns._soundTicker = nil
    end
end
