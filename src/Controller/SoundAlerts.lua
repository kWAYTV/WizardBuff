local _, ns = ...

local SOUND_SELF     = ns.SOUND_SELF
local SOUND_GROUP    = ns.SOUND_GROUP
local SOUND_INTERVAL = ns.SOUND_INTERVAL

local function playBuffReminder()
    if ns._soundKind == "self" then
        PlaySoundFile(SOUND_SELF, "Master")
    else
        PlaySoundFile(SOUND_GROUP, "Master")
    end
end

function ns.UpdateSoundReminder(selfSoundKind, groupNeedsAction)
    local d = ns.db
    if not d or not d.showSound then
        if ns._soundTicker then
            ns._soundTicker:Cancel()
            ns._soundTicker = nil
        end
        ns._soundActive = false
        return
    end

    local kind = selfSoundKind or (groupNeedsAction and "group") or nil

    local wasActive   = ns._soundActive
    local kindChanged = (ns._soundKind ~= kind)
    ns._soundActive = (kind ~= nil)
    ns._soundKind   = kind

    if kind then
        if not wasActive or kindChanged then
            playBuffReminder()
            if ns._soundTicker then ns._soundTicker:Cancel() end
            ns._soundTicker = C_Timer.NewTicker(SOUND_INTERVAL, playBuffReminder)
        end
    else
        if ns._soundTicker then
            ns._soundTicker:Cancel()
            ns._soundTicker = nil
        end
    end
end
