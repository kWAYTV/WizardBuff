local _, ns = ...

function ns.ResolveShieldSpec()
    local shieldKey = ns.GetShieldModeKey()
    local name, sid, resolved
    if shieldKey ~= "auto" then
        local ids = shieldKey == "IceBarrier" and ns.SpellIDs.IceBarrier or ns.SpellIDs.ManaShield
        name, sid = ns.GetHighestRankSpell(ids)
        resolved = shieldKey
    else
        name, sid = ns.GetHighestRankSpell(ns.SpellIDs.IceBarrier)
        resolved = "IceBarrier"
        if not name then
            name, sid = ns.GetHighestRankSpell(ns.SpellIDs.ManaShield)
            resolved = "ManaShield"
        end
    end
    if not name then
        return {
            icon = ns.ICON_PATHS.notLearned, needsAction = false,
            tooltipStatus = "No shield spell known", tooltipColor = "neutral",
        }
    end
    local has = ns.HasAura("player", name) or ns.PlayerHasShieldBuff()
    local needs = not has and ns.NeedsBubble()
    return {
        spellName = name, unit = "player",
        icon = ns.SpellIcon(sid, ns.SPELL_FALLBACK[resolved] or ns.ICON_PATHS.iceBarrier),
        needsAction = needs,
        timerSec = ns.GetShieldRemaining(),
        tooltipSpell = name, tooltipTarget = "self",
        tooltipStatus = has and "Active" or (needs and "HP below threshold" or "Ready"),
        tooltipColor = has and "good" or (needs and "bad" or "neutral"),
        tooltipMode = shieldKey ~= "auto" and ((ns.SpellName(resolved) or resolved) .. " (locked)") or nil,
        modeTag = shieldKey == "ManaShield" and "MS" or (shieldKey == "IceBarrier" and "IB" or nil),
    }
end
