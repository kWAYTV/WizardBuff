local _, ns = ...

function ns.ResolveGroupSpec(ctx)
    local needN = ns.CountNeedingInt()
    local selfIntTimer = ns.GetBuffTimeRemaining("player", ns.SpellName("ArcaneBrilliance"))
        or ns.GetBuffTimeRemaining("player", ns.SpellName("ArcaneIntellect"))
    local groupKey = ns.GetGroupModeKey()
    local preferBrill = (groupKey == "brill") or (groupKey == "auto" and ctx.preferBrill)
    if groupKey == "int" then preferBrill = false end

    local function hit(unit, name, oor)
        if not unit then return end
        local spell, sid, isBrill = ns.GetIntSpellForUnit(unit, preferBrill)
        if not spell then return end
        local mode
        if groupKey ~= "auto" then
            mode = groupKey == "brill" and "Brilliance (locked)" or "Intellect (locked)"
        end
        return {
            spellName = spell, unit = unit,
            icon = ns.SpellIcon(sid, isBrill and ns.ICON_PATHS.brill or ns.ICON_PATHS.int),
            needsAction = true, outOfRange = oor, timerSec = selfIntTimer,
            tooltipSpell = spell, tooltipTarget = name,
            tooltipStatus = oor and "Out of range" or "In range",
            tooltipColor = oor and "oor" or "good", tooltipMode = mode,
            modeTag = groupKey == "brill" and "AB" or (groupKey == "int" and "AI" or nil),
        }
    end

    if not ns.GetHighestRankSpell(ns.SpellIDs.ArcaneIntellect)
        and not ns.GetHighestRankSpell(ns.SpellIDs.ArcaneBrilliance) then
        return {
            icon = ns.ICON_PATHS.notLearned, needsAction = false,
            tooltipStatus = "Learn Arcane Intellect to use this slot",
            tooltipColor = "neutral",
        }
    end

    local spec = hit(ctx.nextIntUnit, ctx.nextIntName, ctx.nextIntOOR)
    if spec and not spec.outOfRange then return spec end
    local petSpec = hit(ctx.nextIntPetUnit, ctx.nextIntPetName or "Pet", ctx.nextIntPetOOR)
    if petSpec and not petSpec.outOfRange then return petSpec end
    if spec then return spec end
    if petSpec then return petSpec end

    local idleSid = preferBrill and ctx.brillSid or ctx.intSid
    local idleIcon = ns.SpellIcon(idleSid, preferBrill and ns.ICON_PATHS.brill or ns.ICON_PATHS.int)
    local modeTag = groupKey == "brill" and "AB" or (groupKey == "int" and "AI" or nil)
    local mode = groupKey ~= "auto" and (groupKey == "brill" and "Brilliance (locked)" or "Intellect (locked)") or nil

    if UnitExists("target") and UnitIsFriend("player", "target") and not UnitIsDeadOrGhost("target") then
        local spell = ns.GetIntSpellForUnit("target", preferBrill)
        return {
            spellName = spell, unit = "target", icon = idleIcon,
            needsAction = false, timerSec = selfIntTimer,
            tooltipSpell = spell, tooltipTarget = "target",
            tooltipStatus = "Click to buff target", tooltipColor = "neutral",
            tooltipMode = mode, modeTag = modeTag,
        }
    end

    return {
        icon = idleIcon, needsAction = false, timerSec = selfIntTimer,
        tooltipStatus = needN > 0 and (needN .. " need Intellect · move closer") or "Group buffed",
        tooltipColor = needN > 0 and "warning" or "good",
        tooltipMode = mode, modeTag = modeTag,
    }
end
