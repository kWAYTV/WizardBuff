local _, ns = ...
ns = ns or _G.WizardBuffAddon
assert(ns, "WizardBuff: load WizardBuff.lua before Update.lua")

local GetSpellInfo = ns.Compat and ns.Compat.GetSpellInfo or _G.GetSpellInfo

local SpellIDs = ns.SpellIDs
local SpellNames = ns.SpellNames
local CLASS_ORDER = ns.CLASS_ORDER

local ICON = {
    armor     = "Interface\\Icons\\Spell_Frost_FrostArmor02",
    int       = "Interface\\Icons\\Spell_Holy_MagicalSentry",
    brill     = "Interface\\Icons\\Spell_Holy_ArcaneIntellect",
    shield    = "Interface\\Icons\\Spell_Ice_Lament",
    selfIdle  = "Interface\\Icons\\Spell_Frost_FrostArmor02",
    grpIdle   = "Interface\\Icons\\Spell_Nature_Regeneration",
    notLearned = "Interface\\Icons\\INV_Misc_QuestionMark",
}

local COL = {
    armor    = {0.18, 0.32, 0.48, 0.92},
    int      = {0.22, 0.18, 0.35, 0.92},
    shield   = {0.15, 0.22, 0.38, 0.92},
    ok       = {0.12, 0.32, 0.12, 0.92},
    brill    = {0.26, 0.16, 0.38, 0.92},
    disabled = {0.14, 0.1, 0.18, 0.92},
}

local function resolveSpellIcon(spellId, fallbackPath)
    if not spellId then
        return fallbackPath
    end
    if GetSpellTexture then
        local tex = GetSpellTexture(spellId)
        if tex and tex ~= "" then
            return tex
        end
    end
    local _, _, tex = GetSpellInfo(spellId)
    if tex and tex ~= "" then
        return tex
    end
    return fallbackPath
end

local function applyButtonSpec(btn, spec)
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
    local c = spec.bg
    btn.bg:SetColorTexture(c[1], c[2], c[3], c[4])
    btn.tooltipLine2 = spec.tooltipLine2
    btn._isIntCast = spec.isIntCast or false
    ns.SetButtonTimer(btn, spec.timerSec)
    ns.SetButtonGlow(btn, spec.needsAction)
end

local function countNeedingInt(roster)
    local n = 0
    for _, class in ipairs(CLASS_ORDER) do
        local pl = roster[class]
        if pl then
            for _, p in ipairs(pl) do
                if p.needsInt then
                    n = n + 1
                end
            end
        end
    end
    return n
end

local function resolveAutoSpec(ctx)
    local armorSpell = ctx.armorSpell
    local bubbleSpell = ctx.bubbleSpell
    local intToUse = ctx.intToUse
    local intSid = ctx.intSid
    local brillSid = ctx.brillSid
    local brillSpell = ctx.brillSpell
    local nextIntUnit, nextIntName = ctx.nextIntUnit, ctx.nextIntName
    local nextIntPetUnit, nextIntPetName = ctx.nextIntPetUnit, ctx.nextIntPetName
    local armorTimer = ns.GetSelfArmorRemaining and ns.GetSelfArmorRemaining()

    if ns.SelfNeedsArmor() and armorSpell then
        local _, sid = ns.GetArmorSpell()
        return {
            spellName = armorSpell,
            unit = "player",
            icon = resolveSpellIcon(sid, ICON.armor),
            bg = COL.armor,
            tooltipLine2 = "Self-cast armor.",
            needsAction = true,
            soundKind = "self",
            timerSec = armorTimer,
            isIntCast = false,
        }
    end

    if intToUse and nextIntUnit then
        local isBrill = brillSpell and (intToUse == brillSpell)
        return {
            spellName = intToUse,
            unit = nextIntUnit,
            icon = isBrill and resolveSpellIcon(brillSid, ICON.brill) or resolveSpellIcon(intSid, ICON.int),
            bg = isBrill and COL.brill or COL.int,
            tooltipLine2 = nextIntName .. " needs buff.",
            needsAction = true,
            soundKind = "group",
            timerSec = armorTimer,
            isIntCast = true,
        }
    end

    if intToUse and nextIntPetUnit then
        return {
            spellName = intToUse,
            unit = nextIntPetUnit,
            icon = resolveSpellIcon(intSid, ICON.int),
            bg = COL.int,
            tooltipLine2 = (nextIntPetName or "Pet") .. " needs buff.",
            needsAction = true,
            soundKind = "group",
            timerSec = armorTimer,
            isIntCast = true,
        }
    end

    if bubbleSpell and ns.NeedsBubble() and not ns.PlayerHasShieldBuff() then
        local _, sid = ns.GetBubbleSpell()
        return {
            spellName = bubbleSpell,
            unit = "player",
            icon = resolveSpellIcon(sid, ICON.shield),
            bg = COL.shield,
            tooltipLine2 = "Emergency shield — HP below threshold.",
            needsAction = true,
            soundKind = nil,
            timerSec = armorTimer,
            isIntCast = false,
        }
    end

    return {
        icon = ICON.selfIdle,
        bg = COL.ok,
        tooltipLine2 = "All buffed!",
        needsAction = false,
        soundKind = nil,
        timerSec = armorTimer,
        isIntCast = false,
    }
end

local function resolveGroupSpec(ctx)
    local brillSpell = ctx.brillSpell
    local intToUse = ctx.intToUse
    local intSid = ctx.intSid
    local brillSid = ctx.brillSid
    local nextIntUnit, nextIntName = ctx.nextIntUnit, ctx.nextIntName
    local nextIntPetUnit, nextIntPetName = ctx.nextIntPetUnit, ctx.nextIntPetName

    local selfIntTimer
    if SpellNames.ArcaneBrilliance then
        selfIntTimer = ns.GetBuffTimeRemaining("player", SpellNames.ArcaneBrilliance)
    end
    if not selfIntTimer and SpellNames.ArcaneIntellect then
        selfIntTimer = ns.GetBuffTimeRemaining("player", SpellNames.ArcaneIntellect)
    end

    if not intToUse then
        return {
            icon = ICON.notLearned,
            bg = COL.disabled,
            tooltipLine2 = "Learn Arcane Intellect to use this slot.",
            needsAction = false,
            timerSec = nil,
        }
    end

    if nextIntUnit then
        local isBrill = brillSpell and (intToUse == brillSpell)
        return {
            spellName = intToUse,
            unit = nextIntUnit,
            icon = isBrill and resolveSpellIcon(brillSid, ICON.brill) or resolveSpellIcon(intSid, ICON.int),
            bg = isBrill and COL.brill or COL.int,
            tooltipLine2 = nextIntName .. " needs buff.",
            needsAction = true,
            timerSec = selfIntTimer,
        }
    end

    if nextIntPetUnit then
        return {
            spellName = intToUse,
            unit = nextIntPetUnit,
            icon = resolveSpellIcon(intSid, ICON.int),
            bg = COL.int,
            tooltipLine2 = (nextIntPetName or "Pet") .. " needs buff.",
            needsAction = true,
            timerSec = selfIntTimer,
        }
    end

    local idleIcon
    if brillSid then
        idleIcon = resolveSpellIcon(brillSid, ICON.grpIdle)
    else
        idleIcon = resolveSpellIcon(intSid, ICON.int)
    end

    if UnitExists("target") and UnitIsFriend("player", "target") and not UnitIsDeadOrGhost("target") then
        return {
            spellName = intToUse,
            unit = "target",
            icon = idleIcon,
            bg = COL.ok,
            tooltipLine2 = "Click to buff target.",
            needsAction = false,
            timerSec = selfIntTimer,
        }
    end

    return {
        icon = idleIcon,
        bg = COL.ok,
        tooltipLine2 = "Group buffed.",
        needsAction = false,
        timerSec = selfIntTimer,
    }
end

local function clearSecureSpell(btn)
    if not btn then return end
    btn:SetAttribute("type", nil)
    btn:SetAttribute("spell", nil)
    btn:SetAttribute("unit", nil)
    btn:SetAttribute("macrotext", nil)
end

local function hideUnusedGridCells(startIdx)
    local cells = ns.gridCells
    if not cells then return end
    for i = startIdx, #cells do
        clearSecureSpell(cells[i])
        cells[i]:Hide()
    end
end

--- Sound reminders ---------------------------------------------------------

local SOUND_SELF  = "Sound\\Interface\\AlarmClockWarning3.ogg"
local SOUND_GROUP = "Sound\\Interface\\iQuestUpdate.ogg"
local SOUND_INTERVAL = 15

local function playBuffReminder()
    if ns._soundKind == "self" then
        PlaySoundFile(SOUND_SELF, "Master")
    else
        PlaySoundFile(SOUND_GROUP, "Master")
    end
end

local function updateSoundReminder(selfSoundKind, groupNeedsAction)
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

    local wasActive = ns._soundActive
    local kindChanged = (ns._soundKind ~= kind)
    ns._soundActive = (kind ~= nil)
    ns._soundKind = kind

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

function ns.UpdateButtons()
    local db = ns.db
    local mainFrame = ns.mainFrame
    local roster = ns.roster
    local autoBuffButton = ns.autoBuffButton
    local brillianceButton = ns.brillianceButton

    if not mainFrame or not ns.isMage or not db.enabled then
        if mainFrame then mainFrame:Hide() end
        return
    end
    if InCombatLockdown() then
        if ns.ApplyHudFade then ns.ApplyHudFade() end
        return
    end

    ns.ScanRoster()

    local armorSpell = ns.GetArmorSpell()
    local intSpell, intSid = ns.GetHighestRankSpell(SpellIDs.ArcaneIntellect)
    local hasPowder = ns.HasArcanePowder()
    local brillSpell, brillSid
    if hasPowder then
        brillSpell, brillSid = ns.GetHighestRankSpell(SpellIDs.ArcaneBrilliance)
    end
    local intToUse = (brillSpell and db.useArcaneBrilliance) and brillSpell or intSpell

    local nextIntUnit, nextIntName = ns.GetNextIntTarget(false)
    local nextIntPetUnit, nextIntPetName = ns.GetNextIntTarget(true)

    local autoSpec = resolveAutoSpec({
        armorSpell = armorSpell,
        bubbleSpell = ns.GetBubbleSpell(),
        intToUse = intToUse,
        intSid = intSid,
        brillSid = brillSid,
        brillSpell = brillSpell,
        nextIntUnit = nextIntUnit,
        nextIntName = nextIntName,
        nextIntPetUnit = nextIntPetUnit,
        nextIntPetName = nextIntPetName,
    })
    local groupSpec = resolveGroupSpec({
        intSpell = intSpell,
        brillSpell = brillSpell,
        intSid = intSid,
        brillSid = brillSid,
        intToUse = intToUse,
        hasPowder = hasPowder,
        nextIntUnit = nextIntUnit,
        nextIntName = nextIntName,
        nextIntPetUnit = nextIntPetUnit,
        nextIntPetName = nextIntPetName,
    })

    applyButtonSpec(autoBuffButton, autoSpec)
    if brillianceButton then
        applyButtonSpec(brillianceButton, groupSpec)
        brillianceButton:Show()
    end

    updateSoundReminder(autoSpec.soundKind, groupSpec.needsAction)

    local needN = countNeedingInt(roster)
    local BAR_H = ns.UI_BAR_H or 38
    local BAR_W = ns.UI_FRAME_W or 72
    local showNeed = db.showHudNeedCount
    local needH = 0

    if not db.showClassRows then
        hideUnusedGridCells(1)
        if mainFrame.needLine then mainFrame.needLine:SetText("") end
        autoBuffButton:ClearAllPoints()
        autoBuffButton:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 3, -3)
        mainFrame:SetSize(BAR_W, BAR_H)
        mainFrame:Show()
        if ns.ApplyHudFade then ns.ApplyHudFade() end
        return
    end

    local CW = ns.GRID_CELL_W or 24
    local CH = ns.GRID_CELL_H or 12
    local CG = ns.GRID_GAP or 1
    local PER_ROW = ns.GRID_PER_ROW or 4

    local gridPlayers = {}
    for _, class in ipairs(CLASS_ORDER) do
        local players = roster[class]
        if players then
            for _, p in ipairs(players) do
                gridPlayers[#gridPlayers + 1] = {
                    name = p.name,
                    unit = p.unit,
                    class = class,
                    needsInt = p.needsInt,
                    ownerName = p.ownerName,
                }
            end
        end
    end

    if not ns.gridCells then ns.gridCells = {} end

    local cols = math.min(#gridPlayers, PER_ROW)
    local gridPxW = cols > 0 and (cols * CW + (cols - 1) * CG) or 0
    local iconPairW = 32 * 2 + 2
    local FRAME_W = math.max(iconPairW + 6, gridPxW + 6)

    local xPad = math.max(3, math.floor((FRAME_W - iconPairW) / 2))
    autoBuffButton:ClearAllPoints()
    autoBuffButton:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", xPad, -3)

    local yAfterIcons = -(3 + 32 + 2)

    if showNeed and mainFrame.needLine then
        needH = 11
        mainFrame.needLine:ClearAllPoints()
        mainFrame.needLine:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 3, yAfterIcons)
        mainFrame.needLine:SetPoint("RIGHT", mainFrame, "RIGHT", -3, 0)
        mainFrame.needLine:SetJustifyH("CENTER")
        mainFrame.needLine:SetText(
            needN > 0
                and ("|cffff7777" .. needN .. "|r |cff555555need|r")
                or  "|cff448844ok|r"
        )
        yAfterIcons = yAfterIcons - needH
    elseif mainFrame.needLine then
        mainFrame.needLine:SetText("")
    end

    local gridYStart = yAfterIcons - 2
    local gridXStart = math.max(3, math.floor((FRAME_W - gridPxW) / 2))
    local maxRow = 0

    for i, p in ipairs(gridPlayers) do
        if not ns.gridCells[i] then
            ns.gridCells[i] = ns.CreateGridCell(i)
        end
        local cell = ns.gridCells[i]
        local col = (i - 1) % PER_ROW
        local row = math.floor((i - 1) / PER_ROW)
        if row > maxRow then maxRow = row end

        cell:ClearAllPoints()
        cell:SetPoint("TOPLEFT", mainFrame, "TOPLEFT",
            gridXStart + col * (CW + CG),
            gridYStart - row * (CH + CG))

        local cc = ns.CLASS_COLORS[p.class] or {0.5, 0.5, 0.5}
        cell.classColor = cc
        cell.playerName = p.name
        cell.needsInt = p.needsInt
        cell.ownerName = p.ownerName
        cell.initial:SetText(p.name:sub(1, 1):upper())

        ns.ApplyGridCellColor(cell)

        if intToUse then
            cell:SetAttribute("type", "spell")
            cell:SetAttribute("spell", intToUse)
            cell:SetAttribute("unit", p.unit)
            cell:SetAttribute("macrotext", nil)
        else
            clearSecureSpell(cell)
        end

        cell:Show()
    end

    hideUnusedGridCells(#gridPlayers + 1)

    local rows = maxRow + 1
    local gridH = rows > 0 and (rows * CH + (rows - 1) * CG) or 0
    local totalH = -gridYStart + gridH + 2
    mainFrame:SetSize(FRAME_W, totalH)
    mainFrame:Show()
    if ns.ApplyHudFade then ns.ApplyHudFade() end
end
