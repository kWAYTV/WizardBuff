local _, ns = ...

local GetSpellInfo = ns.Compat.GetSpellInfo
local SpellNames   = ns.SpellNames
local SpellIDs     = ns.SpellIDs
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

---------------------------------------------------------------------------
-- Per-spell fallback icon (used when resolveSpellIcon has a valid ID
-- but also as the "I know what spell this is" fallback)
---------------------------------------------------------------------------
local SPELL_FALLBACK_ICON = {
    FrostArmor       = ICON.frostArmor,
    IceArmor         = ICON.iceArmor,
    MageArmor        = ICON.mageArmor,
    ArcaneIntellect  = ICON.int,
    ArcaneBrilliance = ICON.brill,
    IceBarrier       = ICON.iceBarrier,
    ManaShield       = ICON.manaShield,
}

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
    if spec.outOfRange then
        btn.icon:SetDesaturated(true)
        btn.icon:SetAlpha(0.5)
    else
        btn.icon:SetDesaturated(false)
        btn.icon:SetAlpha(spec.needsAction and 1 or 0.85)
    end
    btn.tooltipSpell  = spec.tooltipSpell
    btn.tooltipTarget = spec.tooltipTarget
    btn.tooltipStatus = spec.tooltipStatus
    btn.tooltipMode   = spec.tooltipMode
    btn.tooltipColor  = spec.tooltipColor
    btn._isIntCast = spec.isIntCast or false
    ns.SetButtonTimer(btn, spec.timerSec)
    ns.SetButtonGlow(btn, spec.needsAction and not spec.outOfRange)
end

---------------------------------------------------------------------------
-- Resolve a specific armor spell by key
---------------------------------------------------------------------------
local ARMOR_KEY_MAP = {
    FrostArmor = SpellIDs.FrostArmor,
    IceArmor   = SpellIDs.IceArmor,
    MageArmor  = SpellIDs.MageArmor,
}

local function resolveLockedArmor(key)
    local ids = ARMOR_KEY_MAP[key]
    if not ids then return nil, nil end
    return ns.GetHighestRankSpell(ids)
end

---------------------------------------------------------------------------
-- Determine the icon for the player's currently active armor buff
---------------------------------------------------------------------------
local function getActiveArmorIcon()
    local armorChecks = {
        { ids = SpellIDs.IceArmor,   fallback = ICON.iceArmor },
        { ids = SpellIDs.MageArmor,  fallback = ICON.mageArmor },
        { ids = SpellIDs.FrostArmor, fallback = ICON.frostArmor },
    }
    for _, entry in ipairs(armorChecks) do
        for i = #entry.ids, 1, -1 do
            local name = GetSpellInfo(entry.ids[i])
            if name and ns.UnitHasBuff("player", name) then
                return resolveSpellIcon(entry.ids[i], entry.fallback)
            end
        end
    end
    return ICON.frostArmor
end

---------------------------------------------------------------------------
-- Auto-buff spec (left button priority cascade)
---------------------------------------------------------------------------
function ns.ResolveAutoSpec(ctx)
    local intToUse    = ctx.intToUse
    local intSid      = ctx.intSid
    local brillSid    = ctx.brillSid
    local brillSpell  = ctx.brillSpell
    local armorTimer  = ns.GetSelfArmorRemaining()
    local needN       = ns.CountNeedingInt()

    local selfKey = ns.GetSelfModeKey()

    if selfKey ~= "auto" then
        if selfKey == "SelfInt" then
            local intSpell, intSid2 = ns.GetHighestRankSpell(SpellIDs.ArcaneIntellect)
            if intSpell then
                local hasBuff = ns.UnitHasBuff("player", intSpell)
                    or (SpellNames.ArcaneBrilliance and ns.UnitHasBuff("player", SpellNames.ArcaneBrilliance))
                local timer = ns.GetBuffTimeRemaining("player", intSpell)
                        or ns.GetBuffTimeRemaining("player", SpellNames.ArcaneBrilliance)
                return {
                    spellName     = intSpell,
                    unit          = "player",
                    icon          = resolveSpellIcon(intSid2, ICON.int),
                    needsAction   = not hasBuff,
                    soundKind     = (not hasBuff) and "self" or nil,
                    timerSec      = timer,
                    isIntCast     = true,
                    tooltipSpell  = intSpell,
                    tooltipTarget = "self",
                    tooltipStatus = hasBuff and "Active" or "Needs cast",
                    tooltipColor  = hasBuff and "good" or "bad",
                    tooltipMode   = "Self Intellect (locked)",
                }
            end
        else
            local name, sid = resolveLockedArmor(selfKey)
            if name then
                local fallback = SPELL_FALLBACK_ICON[selfKey] or ICON.frostArmor
                local needsCast = not ns.UnitHasBuff("player", name)
                return {
                    spellName     = name,
                    unit          = "player",
                    icon          = resolveSpellIcon(sid, fallback),
                    needsAction   = needsCast,
                    soundKind     = needsCast and "self" or nil,
                    timerSec      = ns.GetBuffTimeRemaining("player", name),
                    isIntCast     = false,
                    tooltipSpell  = name,
                    tooltipTarget = "self",
                    tooltipStatus = needsCast and "Needs cast" or "Active",
                    tooltipColor  = needsCast and "bad" or "good",
                    tooltipMode   = (SpellNames[selfKey] or selfKey) .. " (locked)",
                }
            end
        end
    end

    local armorSpell = ctx.armorSpell
    if ns.SelfNeedsArmor() and armorSpell then
        local _, sid = ns.GetArmorSpell()
        local armorKey = ns.GetArmorSpellKey and ns.GetArmorSpellKey() or nil
        local fallback = (armorKey and SPELL_FALLBACK_ICON[armorKey]) or ICON.frostArmor
        return {
            spellName     = armorSpell,
            unit          = "player",
            icon          = resolveSpellIcon(sid, fallback),
            needsAction   = true,
            soundKind     = "self",
            timerSec      = armorTimer,
            isIntCast     = false,
            tooltipSpell  = armorSpell,
            tooltipTarget = "self",
            tooltipStatus = "Needs cast",
            tooltipColor  = "bad",
        }
    end

    -- In-range player first
    if intToUse and ctx.nextIntUnit and not ctx.nextIntOOR then
        local isBrill = brillSpell and (intToUse == brillSpell)
        return {
            spellName     = intToUse,
            unit          = ctx.nextIntUnit,
            icon          = isBrill and resolveSpellIcon(brillSid, ICON.brill) or resolveSpellIcon(intSid, ICON.int),
            needsAction   = true,
            soundKind     = "group",
            timerSec      = armorTimer,
            isIntCast     = true,
            tooltipSpell  = intToUse,
            tooltipTarget = ctx.nextIntName,
            tooltipStatus = "In range",
            tooltipColor  = "good",
        }
    end

    -- In-range pet before OOR player
    if intToUse and ctx.nextIntPetUnit and not ctx.nextIntPetOOR then
        return {
            spellName     = intToUse,
            unit          = ctx.nextIntPetUnit,
            icon          = resolveSpellIcon(intSid, ICON.int),
            needsAction   = true,
            soundKind     = "group",
            timerSec      = armorTimer,
            isIntCast     = true,
            tooltipSpell  = intToUse,
            tooltipTarget = ctx.nextIntPetName or "Pet",
            tooltipStatus = "In range",
            tooltipColor  = "good",
        }
    end

    -- OOR player fallback
    if intToUse and ctx.nextIntUnit and ctx.nextIntOOR then
        local isBrill = brillSpell and (intToUse == brillSpell)
        return {
            spellName     = intToUse,
            unit          = ctx.nextIntUnit,
            icon          = isBrill and resolveSpellIcon(brillSid, ICON.brill) or resolveSpellIcon(intSid, ICON.int),
            needsAction   = true,
            outOfRange    = true,
            timerSec      = armorTimer,
            isIntCast     = true,
            tooltipSpell  = intToUse,
            tooltipTarget = ctx.nextIntName,
            tooltipStatus = "Out of range",
            tooltipColor  = "oor",
        }
    end

    -- OOR pet fallback
    if intToUse and ctx.nextIntPetUnit and ctx.nextIntPetOOR then
        return {
            spellName     = intToUse,
            unit          = ctx.nextIntPetUnit,
            icon          = resolveSpellIcon(intSid, ICON.int),
            needsAction   = true,
            outOfRange    = true,
            timerSec      = armorTimer,
            isIntCast     = true,
            tooltipSpell  = intToUse,
            tooltipTarget = ctx.nextIntPetName or "Pet",
            tooltipStatus = "Out of range",
            tooltipColor  = "oor",
        }
    end

    local idleStatus = needN > 0
        and (needN .. " need Intellect \194\183 move closer")
        or "All buffed"

    return {
        icon          = getActiveArmorIcon(),
        needsAction   = false,
        soundKind     = nil,
        timerSec      = armorTimer,
        isIntCast     = false,
        tooltipSpell  = nil,
        tooltipTarget = nil,
        tooltipStatus = idleStatus,
        tooltipColor  = needN > 0 and "warning" or "good",
    }
end

---------------------------------------------------------------------------
-- Group-buff spec (middle button)
---------------------------------------------------------------------------
function ns.ResolveGroupSpec(ctx)
    local brillSpell = ctx.brillSpell
    local intSid     = ctx.intSid
    local brillSid   = ctx.brillSid
    local needN      = ns.CountNeedingInt()

    local selfIntTimer
    if SpellNames.ArcaneBrilliance then
        selfIntTimer = ns.GetBuffTimeRemaining("player", SpellNames.ArcaneBrilliance)
    end
    if not selfIntTimer and SpellNames.ArcaneIntellect then
        selfIntTimer = ns.GetBuffTimeRemaining("player", SpellNames.ArcaneIntellect)
    end

    local groupKey = ns.GetGroupModeKey()

    local intSpell, _ = ns.GetHighestRankSpell(SpellIDs.ArcaneIntellect)
    local intToUse
    if groupKey == "brill" and brillSpell and ns.HasArcanePowder() then
        intToUse = brillSpell
    elseif groupKey == "int" and intSpell then
        intToUse = intSpell
    else
        intToUse = ctx.intToUse
    end

    if not intToUse then
        return {
            icon          = ICON.notLearned,
            needsAction   = false,
            timerSec      = nil,
            tooltipSpell  = nil,
            tooltipTarget = nil,
            tooltipStatus = "Learn Arcane Intellect to use this slot",
            tooltipColor  = "neutral",
        }
    end

    -- In-range player first
    if ctx.nextIntUnit and not ctx.nextIntOOR then
        local isBrill = brillSpell and (intToUse == brillSpell)
        return {
            spellName     = intToUse,
            unit          = ctx.nextIntUnit,
            icon          = isBrill and resolveSpellIcon(brillSid, ICON.brill) or resolveSpellIcon(intSid, ICON.int),
            needsAction   = true,
            timerSec      = selfIntTimer,
            tooltipSpell  = intToUse,
            tooltipTarget = ctx.nextIntName,
            tooltipStatus = "In range",
            tooltipColor  = "good",
            tooltipMode   = groupKey ~= "auto" and (groupKey == "brill" and "Brilliance (locked)" or "Intellect (locked)") or nil,
        }
    end

    -- In-range pet before OOR player
    if ctx.nextIntPetUnit and not ctx.nextIntPetOOR then
        return {
            spellName     = intToUse,
            unit          = ctx.nextIntPetUnit,
            icon          = resolveSpellIcon(intSid, ICON.int),
            needsAction   = true,
            timerSec      = selfIntTimer,
            tooltipSpell  = intToUse,
            tooltipTarget = ctx.nextIntPetName or "Pet",
            tooltipStatus = "In range",
            tooltipColor  = "good",
        }
    end

    -- OOR player fallback
    if ctx.nextIntUnit and ctx.nextIntOOR then
        local isBrill = brillSpell and (intToUse == brillSpell)
        return {
            spellName     = intToUse,
            unit          = ctx.nextIntUnit,
            icon          = isBrill and resolveSpellIcon(brillSid, ICON.brill) or resolveSpellIcon(intSid, ICON.int),
            needsAction   = true,
            outOfRange    = true,
            timerSec      = selfIntTimer,
            tooltipSpell  = intToUse,
            tooltipTarget = ctx.nextIntName,
            tooltipStatus = "Out of range",
            tooltipColor  = "oor",
            tooltipMode   = groupKey ~= "auto" and (groupKey == "brill" and "Brilliance (locked)" or "Intellect (locked)") or nil,
        }
    end

    -- OOR pet fallback
    if ctx.nextIntPetUnit and ctx.nextIntPetOOR then
        return {
            spellName     = intToUse,
            unit          = ctx.nextIntPetUnit,
            icon          = resolveSpellIcon(intSid, ICON.int),
            needsAction   = true,
            outOfRange    = true,
            timerSec      = selfIntTimer,
            tooltipSpell  = intToUse,
            tooltipTarget = ctx.nextIntPetName or "Pet",
            tooltipStatus = "Out of range",
            tooltipColor  = "oor",
        }
    end

    local idleIcon = brillSid and resolveSpellIcon(brillSid, ICON.brill)
                                or resolveSpellIcon(intSid, ICON.int)

    if UnitExists("target") and UnitIsFriend("player", "target") and not UnitIsDeadOrGhost("target") then
        return {
            spellName     = intToUse,
            unit          = "target",
            icon          = idleIcon,
            needsAction   = false,
            timerSec      = selfIntTimer,
            tooltipSpell  = intToUse,
            tooltipTarget = "target",
            tooltipStatus = "Click to buff target",
            tooltipColor  = "neutral",
        }
    end

    local idleStatus = needN > 0
        and (needN .. " need Intellect \194\183 move closer")
        or "Group buffed"

    return {
        icon          = idleIcon,
        needsAction   = false,
        timerSec      = selfIntTimer,
        tooltipSpell  = nil,
        tooltipTarget = nil,
        tooltipStatus = idleStatus,
        tooltipColor  = needN > 0 and "warning" or "good",
    }
end

---------------------------------------------------------------------------
-- Shield spec (right button)
---------------------------------------------------------------------------
local SHIELD_KEY_MAP = {
    IceBarrier = SpellIDs.IceBarrier,
    ManaShield = SpellIDs.ManaShield,
}

function ns.ResolveShieldSpec()
    local shieldKey = ns.GetShieldModeKey()

    local spellName, sid, resolvedKey
    if shieldKey ~= "auto" then
        local ids = SHIELD_KEY_MAP[shieldKey]
        if ids then
            spellName, sid = ns.GetHighestRankSpell(ids)
            resolvedKey = shieldKey
        end
    else
        spellName, sid = ns.GetHighestRankSpell(SpellIDs.IceBarrier)
        resolvedKey = "IceBarrier"
        if not spellName then
            spellName, sid = ns.GetHighestRankSpell(SpellIDs.ManaShield)
            resolvedKey = "ManaShield"
        end
    end

    if not spellName then
        return {
            icon          = ICON.notLearned,
            needsAction   = false,
            timerSec      = nil,
            tooltipSpell  = nil,
            tooltipTarget = nil,
            tooltipStatus = "No shield spell known",
            tooltipColor  = "neutral",
        }
    end

    local fallback = SPELL_FALLBACK_ICON[resolvedKey] or ICON.iceBarrier
    local hasBuff = ns.PlayerHasShieldBuff()
    local needsCast = not hasBuff and ns.NeedsBubble()

    return {
        spellName     = spellName,
        unit          = "player",
        icon          = resolveSpellIcon(sid, fallback),
        needsAction   = needsCast,
        timerSec      = nil,
        tooltipSpell  = spellName,
        tooltipTarget = "self",
        tooltipStatus = hasBuff and "Active" or (needsCast and "HP below threshold" or "Ready"),
        tooltipColor  = hasBuff and "good" or (needsCast and "bad" or "neutral"),
        tooltipMode   = shieldKey ~= "auto" and ((SpellNames[resolvedKey] or resolvedKey) .. " (locked)") or nil,
    }
end
