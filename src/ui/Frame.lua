local _, ns = ...
local UI = ns.UI

-- The HUD: header (drag, counts, shortcuts), action row (Buff, Shield,
-- status) and the grid. Shown, moved and resized only out of combat.

local PAD = 4
local HEADER_H = 18
local BUTTON = 34
local STATUS_W = 130

local frame, header, statusMain, statusSub, countText, lockButton
local feedbackUntil = 0

local LOCK_ON = "Interface\\Buttons\\LockButton-Locked-Up"
local LOCK_OFF = "Interface\\Buttons\\LockButton-Unlocked-Up"
local GEAR = "Interface\\Buttons\\UI-OptionsButton"

local function savePosition()
    local point, _, relPoint, x, y = frame:GetPoint(1)
    ns.db.pos = { point = point, relPoint = relPoint, x = x, y = y }
end

function ns.RestorePosition()
    if InCombatLockdown() then return end
    frame:ClearAllPoints()
    local p = ns.db.pos
    if p and p.point then
        frame:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 180)
    end
end

function ns.UpdateLockIcon()
    if lockButton then lockButton.icon:SetTexture(ns.db.locked and LOCK_ON or LOCK_OFF) end
end

function ns.ToggleLock()
    ns.db.locked = not ns.db.locked
    ns.UpdateLockIcon()
    ns.Print(ns.db.locked and "HUD locked." or "HUD unlocked. Drag the header to move it.")
end

local function headerTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine("Wizard Buff " .. ns.version, 1, 1, 1)
    local m = ns.COLORS.muted
    if not ns.db.locked then GameTooltip:AddLine("Drag to move", m[1], m[2], m[3]) end
    GameTooltip:AddLine("Right-click: settings", m[1], m[2], m[3])
    GameTooltip:Show()
end

local function simpleTooltip(owner, title, text)
    owner:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(title, 1, 1, 1)
        if text then
            local m = ns.COLORS.muted
            GameTooltip:AddLine(type(text) == "function" and text() or text, m[1], m[2], m[3], true)
        end
        GameTooltip:Show()
    end)
    owner:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function ns.CreateHUD()
    frame = CreateFrame("Frame", "WizardBuffFrame", UIParent)
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetSize(200, 80)
    UI.Skin(frame)
    ns.frame = frame

    header = CreateFrame("Button", nil, frame)
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -1, -1)
    header:SetHeight(HEADER_H)
    header:RegisterForClicks("AnyUp")
    local hbg = UI.Solid(header, "BACKGROUND", { 0.12, 0.14, 0.18, 0.9 }, 1)
    hbg:SetAllPoints()

    local title = UI.Text(header, 10)
    title:SetPoint("LEFT", 5, 0)
    title:SetText(ns.Colorize("Wizard Buff", ns.COLORS.accent))

    local gear = UI.HeaderButton(header, GEAR, nil, 14)
    gear:SetPoint("RIGHT", -3, 0)
    gear:SetScript("OnClick", function() ns.OpenSettings() end)
    simpleTooltip(gear, "Settings")

    local mages = UI.HeaderButton(header, nil, "Mages", 14)
    mages:SetPoint("RIGHT", gear, "LEFT", -3, 0)
    mages:SetScript("OnClick", function() ns.ToggleAssign() end)
    simpleTooltip(mages, "Mage assignments", "Choose which raid groups each mage covers.")
    ns.magesButton = mages

    lockButton = UI.HeaderButton(header, LOCK_OFF, nil, 14)
    lockButton:SetPoint("RIGHT", mages, "LEFT", -3, 0)
    lockButton:SetScript("OnClick", function() ns.ToggleLock() end)
    simpleTooltip(lockButton, "Lock position")
    ns.UpdateLockIcon()

    countText = UI.Text(header, 10)
    countText:SetPoint("RIGHT", lockButton, "LEFT", -6, 0)

    header:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and not ns.db.locked and not InCombatLockdown() then
            frame:StartMoving()
            frame.moving = true
        end
    end)
    header:SetScript("OnMouseUp", function(_, button)
        if frame.moving then
            frame:StopMovingOrSizing()
            frame.moving = false
            savePosition()
        elseif button == "RightButton" then
            ns.OpenSettings()
        end
    end)
    header:SetScript("OnEnter", headerTooltip)
    header:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local buff = ns.CreateBuffButton(frame)
    buff:SetPoint("TOPLEFT", PAD, -(HEADER_H + PAD))
    local shield = ns.CreateShieldButton(frame)
    shield:SetPoint("LEFT", buff, "RIGHT", PAD, 0)

    statusMain = UI.Text(frame, 11)
    statusMain:SetJustifyH("LEFT")
    statusMain:SetWidth(STATUS_W)
    statusSub = UI.Text(frame, 10)
    statusSub:SetJustifyH("LEFT")
    statusSub:SetWidth(STATUS_W)

    -- Opacity follows hover and combat.
    local elapsed = 0
    frame:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        if elapsed < 0.2 then return end
        elapsed = 0
        local a = ns.db.alpha
        if InCombatLockdown() then a = ns.db.combatAlpha end
        if self:IsMouseOver() then a = 1 end
        self:SetAlpha(a)
        if feedbackUntil > 0 and GetTime() > feedbackUntil then
            feedbackUntil = 0
            ns.RefreshStatus()
        end
    end)

    frame:SetScale(ns.db.scale)
    ns.RestorePosition()
    frame:Hide()
end

function ns.ShouldShow()
    return ns.isMage and ns.db.enabled and (IsInGroup() or ns.db.showSolo)
end

-- Small transient message under the action row.
function ns.Feedback(text, c)
    if not statusSub then return end
    c = c or ns.COLORS.warn
    statusSub:SetText(text)
    statusSub:SetTextColor(c[1], c[2], c[3])
    feedbackUntil = GetTime() + 4
end

local function coverageText()
    if not ns.owners then
        if IsInRaid() and #ns.ActivePeers() <= 1 then return "Covering the whole raid" end
        return nil
    end
    local mine = {}
    for g, guid in pairs(ns.owners) do
        if guid == UnitGUID("player") then mine[#mine + 1] = g end
    end
    table.sort(mine)
    if #mine == 0 then return "No groups assigned to you" end
    return "Your groups: " .. table.concat(mine, ", ")
end

function ns.RefreshStatus()
    if not statusMain then return end
    local plan = ns.plan
    local buff = plan.buff
    if buff then
        local c = buff.outOfRange and ns.COLORS.warn or ns.COLORS.accent
        statusMain:SetText(buff.label .. " > " .. buff.target)
        statusMain:SetTextColor(c[1], c[2], c[3])
    elseif (plan.needAll or 0) > 0 and (plan.needMine or 0) == 0 then
        statusMain:SetText("Your targets are buffed")
        statusMain:SetTextColor(ns.COLORS.good[1], ns.COLORS.good[2], ns.COLORS.good[3])
    else
        statusMain:SetText("All buffed")
        statusMain:SetTextColor(ns.COLORS.good[1], ns.COLORS.good[2], ns.COLORS.good[3])
    end

    if feedbackUntil == 0 then
        local text = coverageText() or (InCombatLockdown() and "In combat: buffs update after the fight") or ""
        statusSub:SetText(text)
        local m = ns.COLORS.muted
        statusSub:SetTextColor(m[1], m[2], m[3])
    end

    local need = plan.needMine or 0
    local powder = plan.powder or 0
    local needText = need > 0 and ns.Colorize(need .. " need", ns.COLORS.bad) or ns.Colorize("0 need", ns.COLORS.muted)
    local pc = powder == 0 and ns.COLORS.bad or (powder <= 5 and ns.COLORS.warn or ns.COLORS.muted)
    local powderText = ns.Knows("BRILLIANCE") and ("  " .. ns.Colorize(powder .. " powder", pc)) or ""
    countText:SetText(needText .. powderText)

    if ns.magesButton then
        local show = IsInRaid() and ns.db.coordinate
        ns.magesButton:SetShown(show)
    end
end

-- Full layout pass. Out of combat only.
function ns.LayoutHUD()
    if InCombatLockdown() or not frame then return end
    if not ns.ShouldShow() then frame:Hide(); return end

    frame:SetScale(ns.db.scale)
    local shieldShown = ns.shieldButton:IsShown()
    local buttonsW = BUTTON + (shieldShown and (PAD + BUTTON) or 0)
    statusMain:ClearAllPoints()
    statusMain:SetPoint("TOPLEFT", ns.buffButton, "TOPLEFT", buttonsW + PAD + 2, -4)
    statusSub:ClearAllPoints()
    statusSub:SetPoint("TOPLEFT", statusMain, "BOTTOMLEFT", 0, -3)

    local top = HEADER_H + PAD + BUTTON + PAD
    local gridW, gridH = ns.LayoutGrid(frame, PAD, top)
    local width = math.max(PAD + buttonsW + PAD + STATUS_W + PAD, gridW + PAD * 2, 170)
    local height = top + (gridH > 0 and (gridH + PAD) or 0)
    frame:SetSize(width, height)
    ns.RefreshStatus()
    frame:Show()
end

function ns.HideHUD()
    if frame and not InCombatLockdown() then frame:Hide() end
end
