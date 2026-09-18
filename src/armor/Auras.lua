local _, ns = ...

function ns.ArmorNames()
    return { ns.SpellName("FrostArmor"), ns.SpellName("IceArmor"), ns.SpellName("MageArmor") }
end

function ns.HasAnyArmorBuff()
    for _, name in ipairs(ns.ArmorNames()) do
        if name and ns.HasAura("player", name) then return true end
    end
    return false
end

function ns.GetSelfArmorRemaining()
    local best
    for _, name in ipairs(ns.ArmorNames()) do
        if name then
            local rem = ns.GetBuffTimeRemaining("player", name)
            if rem and (not best or rem < best) then best = rem end
        end
    end
    return best
end

function ns.SelfNeedsArmor()
    if not ns.db or not ns.db.buffArmor then return false end
    if not ns.HasAnyArmorBuff() then return true end
    local rem = ns.GetSelfArmorRemaining()
    if not rem then return false end
    return rem <= (ns.db.refreshFloorSec or 120)
end
