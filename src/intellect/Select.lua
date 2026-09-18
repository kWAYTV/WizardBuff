local _, ns = ...

function ns.GetIntSpellForUnit(unit, preferBrill)
    if preferBrill and ns.HasArcanePowder() then
        local name, id = ns.GetBestRankForUnit(unit, ns.SpellIDs.ArcaneBrilliance)
        if name then return name, id, true end
    end
    local name, id = ns.GetBestRankForUnit(unit, ns.SpellIDs.ArcaneIntellect)
    return name, id, false
end

function ns.HasStrongerBrilliance(unit)
    local brillName = ns.SpellName("ArcaneBrilliance")
    if not unit or not brillName or not UnitExists(unit) then return false end
    local name, duration, expirationTime, caster = ns.FindBuff(unit, brillName)
    if not name or not caster or UnitIsUnit(caster, "player") then return false end
    if not duration or duration == 0 then return true end
    return (expirationTime - GetTime()) > duration * ns.REFRESH_THRESHOLD
end
