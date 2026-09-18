local _, ns = ...

local ARMOR_KEY_MAP = {
    FrostArmor = true,
    IceArmor   = true,
    MageArmor  = true,
}

local function activeArmorIcon()
    for _, key in ipairs({ "IceArmor", "MageArmor", "FrostArmor" }) do
        local ids = ns.SpellIDs[key]
        for i = #ids, 1, -1 do
            local name = ns.GetSpellName(ids[i])
            if name and ns.HasAura("player", name) then
                return ns.SpellIcon(ids[i], ns.SPELL_FALLBACK[key])
            end
        end
    end
    return ns.ICON_PATHS.frostArmor
end

function ns.ResolveAutoSpec(ctx)
    local armorTimer = ns.GetSelfArmorRemaining()
    local needN = ns.CountNeedingInt()
    local selfKey = ns.GetSelfModeKey()

    if selfKey ~= "auto" then
        if selfKey == "SelfInt" then
            local name, sid = ns.GetHighestRankSpell(ns.SpellIDs.ArcaneIntellect)
            if name then
                local brill = ns.SpellName("ArcaneBrilliance")
                local has = ns.HasAura("player", name) or (brill and ns.HasAura("player", brill))
                return {
                    spellName = name, unit = "player",
                    icon = ns.SpellIcon(sid, ns.ICON_PATHS.int),
                    needsAction = not has, soundKind = (not has) and "self" or nil,
                    timerSec = ns.GetBuffTimeRemaining("player", name) or (brill and ns.GetBuffTimeRemaining("player", brill)),
                    isIntCast = true, tooltipSpell = name, tooltipTarget = "self",
                    tooltipStatus = has and "Active" or "Needs cast",
                    tooltipColor = has and "good" or "bad",
                    tooltipMode = "Self Intellect (locked)",
                    modeTag = "INT",
                }
            end
        elseif ARMOR_KEY_MAP[selfKey] then
            local name, sid = ns.GetHighestRankSpell(ns.SpellIDs[selfKey])
            if name then
                local rem = ns.GetBuffTimeRemaining("player", name)
                local has = ns.HasAura("player", name)
                local needs = (not has) or (rem and rem <= (ns.db.refreshFloorSec or 120))
                return {
                    spellName = name, unit = "player",
                    icon = ns.SpellIcon(sid, ns.SPELL_FALLBACK[selfKey] or ns.ICON_PATHS.frostArmor),
                    needsAction = needs, soundKind = needs and "self" or nil,
                    timerSec = rem,
                    tooltipSpell = name, tooltipTarget = "self",
                    tooltipStatus = needs and "Needs cast" or "Active",
                    tooltipColor = needs and "bad" or "good",
                    tooltipMode = (ns.SpellName(selfKey) or selfKey) .. " (locked)",
                    modeTag = selfKey == "MageArmor" and "MA" or (selfKey == "FrostArmor" and "FA" or "IA"),
                }
            end
        end
    end

    if ns.SelfNeedsArmor() and ctx.armorSpell then
        local _, sid = ns.GetArmorSpell()
        local key = ns.GetArmorSpellKey()
        return {
            spellName = ctx.armorSpell, unit = "player",
            icon = ns.SpellIcon(sid, (key and ns.SPELL_FALLBACK[key]) or ns.ICON_PATHS.frostArmor),
            needsAction = true, soundKind = "self", timerSec = armorTimer,
            tooltipSpell = ctx.armorSpell, tooltipTarget = "self",
            tooltipStatus = "Needs cast", tooltipColor = "bad",
        }
    end

    local function groupHit(unit, name, oor, pet)
        if not unit then return end
        local spell, sid, isBrill = ns.GetIntSpellForUnit(unit, ctx.preferBrill)
        if not spell then return end
        return {
            spellName = spell, unit = unit,
            icon = ns.SpellIcon(sid, isBrill and ns.ICON_PATHS.brill or ns.ICON_PATHS.int),
            needsAction = true, outOfRange = oor, soundKind = oor and nil or "group",
            timerSec = armorTimer, isIntCast = true,
            tooltipSpell = spell, tooltipTarget = name or (pet and "Pet"),
            tooltipStatus = oor and "Out of range" or "In range",
            tooltipColor = oor and "oor" or "good",
        }
    end

    local spec = groupHit(ctx.nextIntUnit, ctx.nextIntName, ctx.nextIntOOR, false)
    if spec and not spec.outOfRange then return spec end
    local petSpec = groupHit(ctx.nextIntPetUnit, ctx.nextIntPetName, ctx.nextIntPetOOR, true)
    if petSpec and not petSpec.outOfRange then return petSpec end
    if spec then return spec end
    if petSpec then return petSpec end

    return {
        icon = activeArmorIcon(), needsAction = false, timerSec = armorTimer,
        tooltipStatus = needN > 0 and (needN .. " need Intellect · move closer") or "All buffed",
        tooltipColor = needN > 0 and "warning" or "good",
    }
end
