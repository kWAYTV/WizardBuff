local _, ns = ...

local GetSpellInfo = ns.Compat.GetSpellInfo
local SpellNames   = ns.SpellNames
local ICON         = ns.ICON_PATHS

---------------------------------------------------------------------------
-- Icon resolution (prefer runtime texture, fallback to path)
---------------------------------------------------------------------------
local function resolveSpellIcon(spellId, fallbackPath)
    if not spellId then return fallbackPath end
    if GetSpellTexture then
        local tex = GetSpellTexture(spellId)
        if tex and tex ~= "" then return tex end
    end
    local _, _, tex = GetSpellInfo(spellId)
    if tex and tex ~= "" then return tex end
    return fallbackPath
end

ns.ResolveSpellIcon = resolveSpellIcon

---------------------------------------------------------------------------
-- Apply a resolved spec to a secure button
---------------------------------------------------------------------------
function ns.ApplyButtonSpec(btn, spec)
    if spec.spellName then
        btn:SetAttribute("type", "spell")
        btn:SetAttribute("spell", spec.spellName)
        btn:SetAttribute("unit", spec.unit or "player")
        btn:SetAttribute("macrotext", nil)
    elseif spec.macro then
        btn:SetAttribute("type", "macro")
        btn:SetAttribute("macrotext", spec.macro)
        btn:SetAttribute("spell", nil)
        btn:SetAttribute("unit", nil)
    else
        btn:SetAttribute("type", nil)
        btn:SetAttribute("spell", nil)
        btn:SetAttribute("unit", nil)
        btn:SetAttribute("macrotext", nil)
    end
    btn.icon:SetTexture(spec.icon)
    btn.icon:SetDesaturated(false)
    btn.icon:SetAlpha(spec.needsAction and 1 or 0.85)
    btn.tooltipLine2 = spec.tooltipLine2
    btn._isIntCast = spec.isIntCast or false
    ns.SetButtonTimer(btn, spec.timerSec)
    ns.SetButtonGlow(btn, spec.needsAction)
end

---------------------------------------------------------------------------
-- Auto-buff spec (left button priority cascade)
---------------------------------------------------------------------------
function ns.ResolveAutoSpec(ctx)
    local armorSpell  = ctx.armorSpell
    local bubbleSpell = ctx.bubbleSpell
    local intToUse    = ctx.intToUse
    local intSid      = ctx.intSid
    local brillSid    = ctx.brillSid
    local brillSpell  = ctx.brillSpell
    local armorTimer  = ns.GetSelfArmorRemaining()

    if ns.SelfNeedsArmor() and armorSpell then
        local _, sid = ns.GetArmorSpell()
        return {
            spellName    = armorSpell,
            unit         = "player",
            icon         = resolveSpellIcon(sid, ICON.armor),
            tooltipLine2 = "Self-cast armor.",
            needsAction  = true,
            soundKind    = "self",
            timerSec     = armorTimer,
            isIntCast    = false,
        }
    end

    if intToUse and ctx.nextIntUnit then
        local isBrill = brillSpell and (intToUse == brillSpell)
        return {
            spellName    = intToUse,
            unit         = ctx.nextIntUnit,
            icon         = isBrill and resolveSpellIcon(brillSid, ICON.brill) or resolveSpellIcon(intSid, ICON.int),
            tooltipLine2 = ctx.nextIntName .. " needs buff.",
            needsAction  = true,
            soundKind    = "group",
            timerSec     = armorTimer,
            isIntCast    = true,
        }
    end

    if intToUse and ctx.nextIntPetUnit then
        return {
            spellName    = intToUse,
            unit         = ctx.nextIntPetUnit,
            icon         = resolveSpellIcon(intSid, ICON.int),
            tooltipLine2 = (ctx.nextIntPetName or "Pet") .. " needs buff.",
            needsAction  = true,
            soundKind    = "group",
            timerSec     = armorTimer,
            isIntCast    = true,
        }
    end

    if bubbleSpell and ns.NeedsBubble() and not ns.PlayerHasShieldBuff() then
        local _, sid = ns.GetBubbleSpell()
        return {
            spellName    = bubbleSpell,
            unit         = "player",
            icon         = resolveSpellIcon(sid, ICON.shield),
            tooltipLine2 = "Emergency shield — HP below threshold.",
            needsAction  = true,
            soundKind    = nil,
            timerSec     = armorTimer,
            isIntCast    = false,
        }
    end

    return {
        icon         = ICON.selfIdle,
        tooltipLine2 = "All buffed!",
        needsAction  = false,
        soundKind    = nil,
        timerSec     = armorTimer,
        isIntCast    = false,
    }
end

---------------------------------------------------------------------------
-- Group-buff spec (right button)
---------------------------------------------------------------------------
function ns.ResolveGroupSpec(ctx)
    local brillSpell = ctx.brillSpell
    local intToUse   = ctx.intToUse
    local intSid     = ctx.intSid
    local brillSid   = ctx.brillSid

    local selfIntTimer
    if SpellNames.ArcaneBrilliance then
        selfIntTimer = ns.GetBuffTimeRemaining("player", SpellNames.ArcaneBrilliance)
    end
    if not selfIntTimer and SpellNames.ArcaneIntellect then
        selfIntTimer = ns.GetBuffTimeRemaining("player", SpellNames.ArcaneIntellect)
    end

    if not intToUse then
        return {
            icon         = ICON.notLearned,
            tooltipLine2 = "Learn Arcane Intellect to use this slot.",
            needsAction  = false,
            timerSec     = nil,
        }
    end

    if ctx.nextIntUnit then
        local isBrill = brillSpell and (intToUse == brillSpell)
        return {
            spellName    = intToUse,
            unit         = ctx.nextIntUnit,
            icon         = isBrill and resolveSpellIcon(brillSid, ICON.brill) or resolveSpellIcon(intSid, ICON.int),
            tooltipLine2 = ctx.nextIntName .. " needs buff.",
            needsAction  = true,
            timerSec     = selfIntTimer,
        }
    end

    if ctx.nextIntPetUnit then
        return {
            spellName    = intToUse,
            unit         = ctx.nextIntPetUnit,
            icon         = resolveSpellIcon(intSid, ICON.int),
            tooltipLine2 = (ctx.nextIntPetName or "Pet") .. " needs buff.",
            needsAction  = true,
            timerSec     = selfIntTimer,
        }
    end

    local idleIcon = brillSid and resolveSpellIcon(brillSid, ICON.grpIdle)
                                or resolveSpellIcon(intSid, ICON.int)

    if UnitExists("target") and UnitIsFriend("player", "target") and not UnitIsDeadOrGhost("target") then
        return {
            spellName    = intToUse,
            unit         = "target",
            icon         = idleIcon,
            tooltipLine2 = "Click to buff target.",
            needsAction  = false,
            timerSec     = selfIntTimer,
        }
    end

    return {
        icon         = idleIcon,
        tooltipLine2 = "Group buffed.",
        needsAction  = false,
        timerSec     = selfIntTimer,
    }
end
