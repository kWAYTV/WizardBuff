local _, ns = ...

function ns.FindBuff(unit, buffName)
    if not unit or not buffName or not UnitExists(unit) then return nil end
    for i = 1, 40 do
        local name, duration, expirationTime, caster = ns.GetBuffAt(unit, i)
        if not name then break end
        if name == buffName then
            return name, duration, expirationTime, caster
        end
    end
    return nil
end

function ns.HasAura(unit, buffName)
    return ns.FindBuff(unit, buffName) ~= nil
end

function ns.GetBuffTimeRemaining(unit, buffName)
    local name, duration, expirationTime = ns.FindBuff(unit, buffName)
    if not name or not duration or duration == 0 or not expirationTime then return nil end
    return math.max(0, expirationTime - GetTime())
end

-- Refresh-aware: used for group intellect, not short self shields.
function ns.UnitHasBuff(unit, buffName)
    if not unit or not buffName or not UnitExists(unit) then return false, nil end
    local name, duration, expirationTime, caster = ns.FindBuff(unit, buffName)
    if not name then return false, nil end
    if not duration or duration == 0 then return true, caster end
    local remaining = expirationTime - GetTime()
    local floor = (ns.db and ns.db.refreshFloorSec) or 120
    if remaining > floor then return true, caster end
    if remaining > duration * ns.REFRESH_THRESHOLD then return true, caster end
    return false, nil
end
