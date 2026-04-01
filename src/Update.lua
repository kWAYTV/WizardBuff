local _, ns = ...
ns = ns or _G.WizardBuffAddon
assert(ns, "WizardBuff: load WizardBuff.lua before Update.lua")

local GetSpellInfo = ns.Compat and ns.Compat.GetSpellInfo or _G.GetSpellInfo

local SpellIDs = ns.SpellIDs
local SpellNames = ns.SpellNames
local CLASS_ORDER = ns.CLASS_ORDER

-- Distinct textures per role (idle "OK" used same INT art as Brill — looked identical in-game).
local ICON = {
    armor = "Interface\\Icons\\Spell_Frost_FrostArmor02",
    int = "Interface\\Icons\\Spell_Holy_MagicalSentry",
    brill = "Interface\\Icons\\Spell_Holy_ArcaneIntellect",
    shield = "Interface\\Icons\\Spell_Ice_Lament",
    -- UX fallbacks when Blizzard gives identical spell icons (common for INT vs Brill in Classic data).
    autoIdle = "Interface\\Icons\\Spell_Frost_FrostArmor02",
    brillIdle = "Interface\\Icons\\Spell_Nature_Regeneration",
    -- Group slot when Brilliance is not trained yet (spellbook) — do not reuse INT art for this column.
    notLearned = "Interface\\Icons\\INV_Misc_QuestionMark",
}

local ARCANE_POWDER_ITEM = 17020

local COL = {
    armor = {0.18, 0.32, 0.48, 0.92},
    int = {0.22, 0.18, 0.35, 0.92},
    shield = {0.15, 0.22, 0.38, 0.92},
    ok = {0.12, 0.32, 0.12, 0.92},
    brill = {0.26, 0.16, 0.38, 0.92},
    intNoPowder = {0.28, 0.22, 0.14, 0.92},
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

local function getItemIconPath(itemId, fallbackPath)
    if GetItemIcon then
        local tex = GetItemIcon(itemId)
        if tex and tex ~= "" then
            return tex
        end
    end
    return fallbackPath
end

-- If both slots resolve to the same texture, distinguish the right (group/brill) slot first — never clobber both with idle art while casting Int on both.
local function ensureDistinctHudIcons(autoSpec, brillSpec)
    local a, b = autoSpec.icon, brillSpec.icon
    if a and b and a ~= b then
        return
    end
    brillSpec.icon = getItemIconPath(ARCANE_POWDER_ITEM, ICON.brill)
    if brillSpec.icon == autoSpec.icon then
        brillSpec.icon = ICON.brillIdle
    end
    if autoSpec.icon == brillSpec.icon then
        autoSpec.icon = ICON.autoIdle
    end
end

-- Right (group) slot always shows powder when we only cast Intellect there (no powder / no Brilliance yet) so it never mirrors the auto column.
local function brillGroupSlotIcon()
    return getItemIconPath(ARCANE_POWDER_ITEM, ICON.brillIdle)
end

local function applyButtonSpec(btn, spec)
    btn:SetAttribute("macrotext", spec.macro)
    btn.icon:SetTexture(spec.icon)
    local c = spec.bg
    btn.bg:SetColorTexture(c[1], c[2], c[3], c[4])
    btn.tooltipLine2 = spec.tooltipLine2
    ns.SetButtonTimer(btn, spec.timerSec)
    ns.SetButtonGlow(btn, spec.needsAction)
end

local function formatHudTimer(sec)
    if not sec or sec <= 0 then
        return ""
    end
    if sec >= 3600 then
        return string.format(" (%dh)", math.floor(sec / 3600))
    elseif sec >= 60 then
        return string.format(" (%dm)", math.floor(sec / 60))
    end
    return string.format(" (%ds)", math.floor(sec))
end

local function applyHudLabels()
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

local function resolveAutoBuffSpec(ctx)
    local armorSpell, bubbleSpell = ctx.armorSpell, ctx.bubbleSpell
    local intToUse = ctx.intToUse
    local nextIntUnit, nextIntName = ctx.nextIntUnit, ctx.nextIntName
    local nextIntPetUnit, nextIntPetName = ctx.nextIntPetUnit, ctx.nextIntPetName

    if ns.SelfNeedsArmor() and armorSpell then
        local _, sid = ns.GetArmorSpell()
        return {
            macro = "/cast [@player] " .. armorSpell,
            text = "|cff69ccf0Armor|r",
            labelShort = "Armor",
            icon = resolveSpellIcon(sid, ICON.armor),
            bg = COL.armor,
            tooltipLine2 = "Self-cast armor before buffing the group.",
            needsAction = true,
        }
    end

    if bubbleSpell and ns.NeedsBubble() and not ns.PlayerHasShieldBuff() then
        local _, sid = ns.GetBubbleSpell()
        return {
            macro = ns.MakeSelfCastMacro(bubbleSpell),
            text = "|cff99ccffShield|r",
            labelShort = "Shield",
            icon = resolveSpellIcon(sid, ICON.shield),
            bg = COL.shield,
            tooltipLine2 = "Emergency shield when your health is below the threshold.",
            needsAction = true,
        }
    end

    if nextIntUnit and intToUse then
        local _, iid = ns.GetHighestRankSpell(SpellIDs.ArcaneIntellect)
        return {
            macro = ns.MakeBuffMacro(nextIntUnit, intToUse),
            text = "|cffaaaaff" .. nextIntName .. "|r",
            labelShort = (nextIntName and #nextIntName > 8) and (nextIntName:sub(1, 7) .. "\226\128\166") or (nextIntName or "Int"),
            icon = resolveSpellIcon(iid, ICON.int),
            bg = COL.int,
            tooltipLine2 = "Casts on the next roster member that needs Intellect (or Brilliance if configured).",
            needsAction = true,
        }
    end

    if nextIntPetUnit and intToUse then
        local _, iid = ns.GetHighestRankSpell(SpellIDs.ArcaneIntellect)
        return {
            macro = ns.MakeBuffMacro(nextIntPetUnit, intToUse),
            text = "|cffaaaaffPet|r",
            labelShort = "Pet",
            icon = resolveSpellIcon(iid, ICON.int),
            bg = COL.int,
            tooltipLine2 = "Casts on the next pet that needs Intellect.",
            needsAction = true,
        }
    end

    local armorTimer = ns.GetSelfArmorRemaining and ns.GetSelfArmorRemaining()
    local intTimer = SpellNames.ArcaneIntellect and ns.GetBuffTimeRemaining("player", SpellNames.ArcaneIntellect)
    local selfTimer = nil
    if armorTimer and intTimer then
        selfTimer = math.min(armorTimer, intTimer)
    else
        selfTimer = armorTimer or intTimer
    end

    return {
        macro = nil,
        text = "|cff66dd66OK|r",
        labelShort = "Queue",
        icon = ICON.autoIdle,
        bg = COL.ok,
        tooltipLine2 = "Next target in queue: armor, shield (if low HP), then Int/Brilliance.",
        needsAction = false,
        timerSec = selfTimer,
    }
end

local function resolveBrillianceSpec(ctx)
    local brillTarget = ctx.brillTarget
    local brillSpell, intSpell = ctx.brillSpell, ctx.intSpell
    local hasPowder = ctx.hasPowder
    local learnedBrill, brillSid = ns.GetHighestRankSpell(SpellIDs.ArcaneBrilliance)
    local _, intSid = ns.GetHighestRankSpell(SpellIDs.ArcaneIntellect)

    if brillSpell then
        return brillTarget and {
            macro = ns.MakeBuffMacro(brillTarget, brillSpell),
            text = "|cffcc99ffBrilliance|r",
            labelShort = "Brill",
            icon = resolveSpellIcon(brillSid, ICON.brill),
            bg = COL.brill,
            timerSec = nil,
            tooltipLine2 = "Casts Arcane Brilliance on the same target as Auto when possible.",
            needsAction = true,
        } or {
            macro = nil,
            text = "|cff66dd66Done|r",
            labelShort = "Done",
            icon = resolveSpellIcon(brillSid, ICON.brillIdle),
            bg = COL.ok,
            timerSec = SpellNames.ArcaneBrilliance and ns.GetBuffTimeRemaining("player", SpellNames.ArcaneBrilliance) or nil,
            tooltipLine2 = "Group buff satisfied or no valid target.",
            needsAction = false,
        }
    end

    if learnedBrill and not hasPowder and intSpell then
        return brillTarget and {
            macro = ns.MakeBuffMacro(brillTarget, intSpell),
            text = "|cffffcc66Int|r",
            labelShort = "Int",
            icon = brillGroupSlotIcon(),
            bg = COL.intNoPowder,
            tooltipLine2 = "No Arcane Powder: this button still casts Intellect, but the icon is the group slot (powder = Arcane Brilliance when you have it).",
            needsAction = true,
        } or {
            macro = nil,
            text = "|cff66dd66OK|r",
            labelShort = "Group",
            icon = brillGroupSlotIcon(),
            bg = COL.ok,
            tooltipLine2 = "Buy Arcane Powder to cast Arcane Brilliance from this slot; until then it falls back to Int.",
            needsAction = false,
            timerSec = SpellNames.ArcaneIntellect and ns.GetBuffTimeRemaining("player", SpellNames.ArcaneIntellect) or nil,
        }
    end

    return {
        macro = nil,
        text = "|cff666666\226\128\148|r",
        labelShort = "Train",
        icon = ICON.notLearned,
        bg = COL.disabled,
        tooltipLine2 = "Arcane Brilliance is not in your spellbook yet. Train it to unlock the group buff on this slot.",
        needsAction = false,
    }
end

local function clearSecureSpell(btn)
    if not btn then return end
    btn:SetAttribute("type", nil)
    btn:SetAttribute("spell", nil)
    btn:SetAttribute("unit", nil)
end

local function hideUnusedGridCells(startIdx)
    local cells = ns.gridCells
    if not cells then return end
    for i = startIdx, #cells do
        clearSecureSpell(cells[i])
        cells[i]:Hide()
    end
end

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

local function updateSoundReminder(autoNeedsAction, brillNeedsAction, autoLabel)
    local d = ns.db
    if not d or not d.showSound then
        if ns._soundTicker then
            ns._soundTicker:Cancel()
            ns._soundTicker = nil
        end
        ns._soundActive = false
        return
    end

    local anyNeedsAction = autoNeedsAction or brillNeedsAction
    local kind
    if autoNeedsAction and (autoLabel == "Armor" or autoLabel == "Shield") then
        kind = "self"
    else
        kind = "group"
    end

    local wasActive = ns._soundActive
    local kindChanged = (ns._soundKind ~= kind)
    ns._soundActive = anyNeedsAction
    ns._soundKind = kind

    if anyNeedsAction then
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
    local intSpell = ns.GetHighestRankSpell(SpellIDs.ArcaneIntellect)
    local hasPowder = ns.HasArcanePowder()
    local brillSpell = hasPowder and ns.GetHighestRankSpell(SpellIDs.ArcaneBrilliance)
    local intToUse = (brillSpell and db.useArcaneBrilliance) and brillSpell or intSpell

    local nextIntUnit, nextIntName = ns.GetNextIntTarget(false)
    local nextIntPetUnit, nextIntPetName = ns.GetNextIntTarget(true)

    local autoSpec = resolveAutoBuffSpec({
        armorSpell = armorSpell,
        bubbleSpell = ns.GetBubbleSpell(),
        intToUse = intToUse,
        nextIntUnit = nextIntUnit,
        nextIntName = nextIntName,
        nextIntPetUnit = nextIntPetUnit,
        nextIntPetName = nextIntPetName,
    })
    local brillSpec = resolveBrillianceSpec({
        brillTarget = nextIntUnit or nextIntPetUnit,
        brillSpell = brillSpell,
        intSpell = intSpell,
        hasPowder = hasPowder,
    })
    ensureDistinctHudIcons(autoSpec, brillSpec)
    applyButtonSpec(autoBuffButton, autoSpec)
    if brillianceButton then
        applyButtonSpec(brillianceButton, brillSpec)
        brillianceButton:Show()
    end

    updateSoundReminder(autoSpec.needsAction, brillSpec.needsAction, autoSpec.labelShort)

    applyHudLabels()
    if ns.ApplySlotBadges then ns.ApplySlotBadges() end

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

        if intSpell and p.needsInt then
            cell:SetAttribute("type", "spell")
            cell:SetAttribute("spell", intSpell)
            cell:SetAttribute("unit", p.unit)
        else
            cell:SetAttribute("type", nil)
            cell:SetAttribute("spell", nil)
            cell:SetAttribute("unit", nil)
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
