local _, ns = ...
ns = ns or _G.WizardBuffAddon
assert(ns, "WizardBuff: load WizardBuff.lua before UI.lua")

local ICON = 24
local PAD  = 2
local GAP  = 2

ns.UI_FRAME_W = PAD + ICON + GAP + ICON + PAD
ns.UI_BAR_H   = PAD + ICON + PAD

local CELL       = 20
local CELL_BORDER = 2
local CELL_GAP   = 2
ns.GRID_CELL_W  = CELL
ns.GRID_CELL_H  = CELL
ns.GRID_GAP      = CELL_GAP
ns.GRID_PER_ROW  = 5

function ns.ApplyHudScale()
    local mf = ns.mainFrame
    if not mf then return end
    mf:SetScale((ns.db and ns.db.hudScale) or 1)
end

function ns.ApplyHudFade()
    local d = ns.db
    local mf = ns.mainFrame
    if not mf or not d or not mf:IsShown() then return end
    local a = d.hudAlphaHover or 0.95
    if not ns._hudMouseOver then
        a = d.hudAlphaIdle or 0.42
        if d.hideHudInCombat and InCombatLockdown() then
            a = math.min(a, 0.07)
        end
    end
    mf:SetAlpha(a)
end

local function scheduleHudLeaveCheck(mf)
    C_Timer.After(0.08, function()
        if mf and mf:IsMouseOver() then return end
        ns._hudMouseOver = false
        ns.ApplyHudFade()
    end)
end

---------------------------------------------------------------------------
-- Glow (pulsing border highlight for action-needed buttons)
---------------------------------------------------------------------------
local GLOW_R, GLOW_G, GLOW_B = 1, 0.82, 0.3
local GLOW_THICK = 2

local function createGlow(btn)
    local edges = {}
    for i = 1, 4 do
        local e = btn:CreateTexture(nil, "OVERLAY", nil, 2)
        e:SetColorTexture(GLOW_R, GLOW_G, GLOW_B, 1)
        e:SetBlendMode("ADD")
        e:SetAlpha(0)
        e:Hide()
        edges[i] = e
    end
    local top, bot, left, right = edges[1], edges[2], edges[3], edges[4]
    top:SetPoint("TOPLEFT", btn, -GLOW_THICK, GLOW_THICK)
    top:SetPoint("TOPRIGHT", btn, GLOW_THICK, GLOW_THICK)
    top:SetHeight(GLOW_THICK)
    bot:SetPoint("BOTTOMLEFT", btn, -GLOW_THICK, -GLOW_THICK)
    bot:SetPoint("BOTTOMRIGHT", btn, GLOW_THICK, -GLOW_THICK)
    bot:SetHeight(GLOW_THICK)
    left:SetPoint("TOPLEFT", top, "BOTTOMLEFT")
    left:SetPoint("BOTTOMLEFT", bot, "TOPLEFT")
    left:SetWidth(GLOW_THICK)
    right:SetPoint("TOPRIGHT", top, "BOTTOMRIGHT")
    right:SetPoint("BOTTOMRIGHT", bot, "TOPRIGHT")
    right:SetWidth(GLOW_THICK)
    btn.glowEdges = edges
    btn._glowPhase = 0
    btn._glowing = false
end

local function updateGlows(self, elapsed)
    for _, btn in ipairs(self._glowButtons) do
        if btn._glowing and btn.glowEdges then
            btn._glowPhase = (btn._glowPhase or 0) + elapsed * 2.5
            local a = 0.5 + 0.5 * (0.5 + 0.5 * math.sin(btn._glowPhase))
            for _, e in ipairs(btn.glowEdges) do e:SetAlpha(a) end
        end
    end
end

function ns.InitGlowTicker()
    if ns._glowFrame then return end
    local f = CreateFrame("Frame")
    f._glowButtons = {}
    f:SetScript("OnUpdate", updateGlows)
    f:Hide()
    ns._glowFrame = f
end

function ns.RegisterGlowButton(btn)
    ns.InitGlowTicker()
    table.insert(ns._glowFrame._glowButtons, btn)
end

function ns.SetButtonGlow(btn, on)
    if not btn or not btn.glowEdges then return end
    local d = ns.db
    if not d or not d.showGlow then on = false end
    btn._glowing = on
    if on then
        for _, e in ipairs(btn.glowEdges) do e:Show() end
        btn._glowPhase = btn._glowPhase or 0
        if ns._glowFrame then ns._glowFrame:Show() end
    else
        for _, e in ipairs(btn.glowEdges) do e:SetAlpha(0); e:Hide() end
        btn._glowPhase = 0
    end
end

---------------------------------------------------------------------------
-- Timer overlay (shows remaining buff duration on icons)
---------------------------------------------------------------------------
local function createTimer(btn)
    local t = btn:CreateFontString(nil, "OVERLAY")
    t:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    t:SetPoint("BOTTOM", btn, "BOTTOM", 0, 1)
    t:SetTextColor(1, 1, 1, 0.95)
    t:SetShadowOffset(1, -1)
    t:SetText("")
    btn.timerText = t
end

local function formatTimer(sec)
    if sec >= 3600 then
        return string.format("%dh", math.floor(sec / 3600)), true
    elseif sec >= 60 then
        return string.format("%dm", math.ceil(sec / 60)), true
    else
        return string.format("%ds", math.floor(sec)), false
    end
end

local function refreshTimerText(btn)
    if not btn or not btn.timerText then return end
    local d = ns.db
    if not d or not d.showTimers then btn.timerText:SetText(""); return end
    local exp = btn._expiresAt
    if not exp then btn.timerText:SetText(""); return end
    local sec = exp - GetTime()
    if sec <= 0 then btn.timerText:SetText(""); return end
    local text, isLong = formatTimer(sec)
    btn.timerText:SetText(text)
    btn.timerText:SetTextColor(isLong and 1 or 1, isLong and 1 or 0.6, isLong and 1 or 0.3)
end

function ns.SetButtonTimer(btn, sec)
    if not btn then return end
    btn._expiresAt = (sec and sec > 0) and (GetTime() + sec) or nil
    refreshTimerText(btn)
end

---------------------------------------------------------------------------
-- Main frame — transparent container, no backdrop
---------------------------------------------------------------------------
function ns.CreateMainFrame()
    local mf = CreateFrame("Frame", "WizardBuffFrame", UIParent)
    ns.mainFrame = mf
    mf:SetSize(ns.UI_FRAME_W, ns.UI_BAR_H)

    local pos = ns.db and ns.db.hudPos
    if pos and pos.point and pos.relPoint and pos.x and pos.y then
        mf:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else
        mf:SetPoint("CENTER", 0, 200)
    end

    mf:SetMovable(true)
    mf:EnableMouse(true)
    mf:SetClampedToScreen(true)
    mf:SetFrameStrata("MEDIUM")
    mf:SetFrameLevel(8)

    mf:SetScript("OnEnter", function()
        ns._hudMouseOver = true
        ns.ApplyHudFade()
    end)
    mf:SetScript("OnLeave", function() scheduleHudLeaveCheck(mf) end)

    local timerElapsed = 0
    mf:SetScript("OnUpdate", function(_, dt)
        timerElapsed = timerElapsed + dt
        if timerElapsed < 1 then return end
        timerElapsed = 0
        if ns.autoBuffButton then refreshTimerText(ns.autoBuffButton) end
        if ns.brillianceButton then refreshTimerText(ns.brillianceButton) end
    end)

    local needLine = mf:CreateFontString(nil, "OVERLAY")
    needLine:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE")
    needLine:SetShadowOffset(1, -1)
    needLine:SetText("")
    mf.needLine = needLine

    ns.ApplyHudScale()
end

---------------------------------------------------------------------------
-- Handle — invisible; ADD highlight only on hover (Decursive style)
---------------------------------------------------------------------------
local HANDLE_H = 6
local autoLockTimer

local function cancelAutoLock()
    if autoLockTimer then autoLockTimer:Cancel(); autoLockTimer = nil end
end

local function scheduleAutoLock()
    cancelAutoLock()
    autoLockTimer = C_Timer.NewTimer(30, function()
        autoLockTimer = nil
        if ns.db and not ns.db.locked then
            ns.db.locked = true
            ns.Print("Auto-locked after 30s")
        end
    end)
end

ns.CancelAutoLock = cancelAutoLock
ns.ScheduleAutoLock = scheduleAutoLock

function ns.CreateHandle()
    local mf = ns.mainFrame
    local h = CreateFrame("Button", "WizardBuffHandle", mf)
    ns.handle = h

    h:SetHeight(HANDLE_H)
    h:SetPoint("BOTTOMLEFT", mf, "TOPLEFT", 0, 0)
    h:SetPoint("BOTTOMRIGHT", mf, "TOPRIGHT", 0, 0)
    h:SetFrameStrata("MEDIUM")
    h:SetFrameLevel(mf:GetFrameLevel() + 5)
    h:EnableMouse(true)
    h:RegisterForDrag("LeftButton")
    h:RegisterForClicks("AnyUp")

    local hl = h:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.12)
    hl:SetBlendMode("ADD")

    h:SetScript("OnEnter", function(self)
        ns._hudMouseOver = true
        ns.ApplyHudFade()
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Wizard Buff", 0.6, 0.8, 1)
        local locked = ns.db and ns.db.locked
        if locked then
            GameTooltip:AddLine("Right-click \194\183 config", 0.55, 0.55, 0.55)
            GameTooltip:AddLine("Shift+click \194\183 unlock", 0.55, 0.55, 0.55)
        else
            GameTooltip:AddLine("Drag to move", 0.55, 0.55, 0.55)
            GameTooltip:AddLine("Right-click \194\183 config", 0.55, 0.55, 0.55)
            GameTooltip:AddLine("Shift+click \194\183 lock", 0.55, 0.55, 0.55)
        end
        GameTooltip:Show()
    end)
    h:SetScript("OnLeave", function()
        GameTooltip:Hide()
        scheduleHudLeaveCheck(mf)
    end)

    h:SetScript("OnDragStart", function()
        if not InCombatLockdown() and not (ns.db and ns.db.locked) then
            cancelAutoLock()
            mf:StartMoving()
        end
    end)
    h:SetScript("OnDragStop", function()
        mf:StopMovingOrSizing()
        if ns.db then
            local point, _, relPoint, x, y = mf:GetPoint(1)
            ns.db.hudPos = { point = point, relPoint = relPoint, x = x, y = y }
        end
        if ns.db and not ns.db.locked then scheduleAutoLock() end
    end)

    h:SetScript("OnClick", function(_, button)
        if IsShiftKeyDown() then
            if ns.db then
                ns.db.locked = not ns.db.locked
                if ns.db.locked then
                    cancelAutoLock()
                    ns.Print("Locked")
                else
                    scheduleAutoLock()
                    ns.Print("Unlocked (auto-locks in 30s)")
                end
            end
        elseif button == "RightButton" then
            if ns.OpenConfig then ns.OpenConfig() end
        end
    end)
end

function ns.UpdateHandleVisibility()
    if not ns.handle then return end
    if ns.db and ns.db.showDragHandle == false then
        ns.handle:Hide()
    else
        ns.handle:Show()
    end
end

---------------------------------------------------------------------------
-- Secure icon buttons — clean floating icons, thin dark surround
---------------------------------------------------------------------------
local function stripSecureActionChrome(b)
    local nt = b:GetNormalTexture()
    if nt then nt:SetTexture(nil); nt:SetAlpha(0) end
    local pt = b:GetPushedTexture()
    if pt then pt:SetTexture(nil) end
    local ht = b:GetHighlightTexture()
    if ht then ht:SetTexture(nil) end
end

local function hookSecureHover(btn, mf)
    if not btn then return end
    btn:HookScript("OnEnter", function()
        ns._hudMouseOver = true
        ns.ApplyHudFade()
    end)
    btn:HookScript("OnLeave", function() scheduleHudLeaveCheck(mf) end)
end

local function makeIconButton(name, parent)
    local b = CreateFrame("Button", name, parent, "SecureActionButtonTemplate")
    b:SetSize(ICON, ICON)
    b:RegisterForClicks("AnyUp", "AnyDown")
    b:SetAttribute("type", "macro")
    stripSecureActionChrome(b)

    local shadow = b:CreateTexture(nil, "BACKGROUND")
    shadow:SetPoint("TOPLEFT", -1, 1)
    shadow:SetPoint("BOTTOMRIGHT", 1, -1)
    shadow:SetColorTexture(0, 0, 0, 0.6)
    b.shadow = shadow

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    b.icon = icon

    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.15)
    hl:SetBlendMode("ADD")

    createGlow(b)
    createTimer(b)
    return b
end

function ns.CreateAutoBuffButton()
    local mf = ns.mainFrame
    local b = makeIconButton("WizardBuffAutoBuffButton", mf)
    ns.autoBuffButton = b
    b:SetPoint("TOPLEFT", mf, "TOPLEFT", PAD, -PAD)
    b.icon:SetTexture("Interface\\Icons\\Spell_Holy_MagicalSentry")

    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Auto Buff", 0.85, 0.92, 1)
        if self.tooltipLine2 and self.tooltipLine2 ~= "" then
            GameTooltip:AddLine(self.tooltipLine2, 0.6, 0.6, 0.6, true)
        end
        GameTooltip:AddLine("/click WizardBuffAutoBuffButton", 0.35, 0.35, 0.35)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    hookSecureHover(b, mf)
    ns.RegisterGlowButton(b)

    b:SetScript("PostClick", function(self)
        if not InCombatLockdown() then
            if self._isIntCast then
                local unit = self:GetAttribute("unit")
                if unit then ns._recentlyBuffed[unit] = GetTime() end
            end
            ns.ScheduleUpdate(true)
        end
    end)
end

function ns.CreateBrillianceButton()
    local mf = ns.mainFrame
    local b = makeIconButton("WizardBuffBrillianceButton", mf)
    ns.brillianceButton = b
    b:SetPoint("LEFT", ns.autoBuffButton, "RIGHT", GAP, 0)
    b.icon:SetTexture("Interface\\Icons\\Spell_Nature_Regeneration")

    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Group", 0.9, 0.85, 1)
        if self.tooltipLine2 and self.tooltipLine2 ~= "" then
            GameTooltip:AddLine(self.tooltipLine2, 0.6, 0.6, 0.6, true)
        end
        GameTooltip:AddLine("/click WizardBuffBrillianceButton", 0.35, 0.35, 0.35)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    hookSecureHover(b, mf)
    ns.RegisterGlowButton(b)

    b:SetScript("PostClick", function(self)
        local unit = self:GetAttribute("unit")
        if unit and not InCombatLockdown() then
            ns._recentlyBuffed[unit] = GetTime()
            ns.ScheduleUpdate(true)
        end
    end)
end

---------------------------------------------------------------------------
-- Grid cells — Decursive-style micro-unit frames
-- Four thin border strips (class-colored) + center fill
---------------------------------------------------------------------------
function ns.CreateGridCell(index)
    local mf = ns.mainFrame
    local btn = CreateFrame("Button", "WizardBuffCell" .. index, mf, "SecureActionButtonTemplate")
    btn:SetSize(CELL, CELL)
    btn:RegisterForClicks("AnyUp", "AnyDown")
    btn:SetAttribute("type", "spell")
    stripSecureActionChrome(btn)

    local INNER = CELL - CELL_BORDER * 2

    local edges = {}
    for i = 1, 4 do
        edges[i] = btn:CreateTexture(nil, "BORDER")
        edges[i]:SetColorTexture(0, 0, 0, 0.8)
    end
    edges[1]:SetPoint("TOPLEFT"); edges[1]:SetPoint("TOPRIGHT"); edges[1]:SetHeight(CELL_BORDER)
    edges[2]:SetPoint("BOTTOMLEFT"); edges[2]:SetPoint("BOTTOMRIGHT"); edges[2]:SetHeight(CELL_BORDER)
    edges[3]:SetPoint("TOPLEFT", edges[1], "BOTTOMLEFT"); edges[3]:SetPoint("BOTTOMLEFT", edges[2], "TOPLEFT"); edges[3]:SetWidth(CELL_BORDER)
    edges[4]:SetPoint("TOPRIGHT", edges[1], "BOTTOMRIGHT"); edges[4]:SetPoint("BOTTOMRIGHT", edges[2], "TOPRIGHT"); edges[4]:SetWidth(CELL_BORDER)
    btn.edges = edges

    local fill = btn:CreateTexture(nil, "BACKGROUND")
    fill:SetPoint("TOPLEFT", CELL_BORDER, -CELL_BORDER)
    fill:SetPoint("BOTTOMRIGHT", -CELL_BORDER, CELL_BORDER)
    fill:SetColorTexture(0.15, 0.15, 0.15, 0.9)
    btn.fill = fill

    local initial = btn:CreateFontString(nil, "OVERLAY")
    initial:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    initial:SetPoint("CENTER", 0, 0)
    initial:SetShadowOffset(1, -1)
    btn.initial = initial

    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetPoint("TOPLEFT", CELL_BORDER, -CELL_BORDER)
    hl:SetPoint("BOTTOMRIGHT", -CELL_BORDER, CELL_BORDER)
    hl:SetColorTexture(1, 1, 1, 0.18)
    hl:SetBlendMode("ADD")

    btn:SetScript("OnEnter", function(self)
        ns._hudMouseOver = true
        ns.ApplyHudFade()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local cr, cg, cb = 1, 1, 1
        if self.classColor then cr, cg, cb = unpack(self.classColor) end
        GameTooltip:AddLine(self.playerName or "?", cr, cg, cb)
        if self.ownerName then
            GameTooltip:AddLine("Pet \194\183 " .. self.ownerName, 0.5, 0.5, 0.5)
        end
        if self.needsInt then
            GameTooltip:AddLine("Needs Intellect", 1, 0.4, 0.4)
        else
            GameTooltip:AddLine("Buffed", 0.4, 1, 0.4)
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        scheduleHudLeaveCheck(mf)
    end)

    btn:SetScript("PostClick", function(self)
        local unit = self:GetAttribute("unit")
        if unit and not InCombatLockdown() then
            ns._recentlyBuffed[unit] = GetTime()
            ns.ScheduleUpdate(true)
        end
    end)

    btn:Hide()
    return btn
end

function ns.ApplyGridCellColor(btn)
    local r, g, b = 0.5, 0.5, 0.5
    if btn.classColor then r, g, b = unpack(btn.classColor) end

    if btn.needsInt then
        btn.fill:SetColorTexture(r * 0.45, g * 0.45, b * 0.45, 0.95)
        btn.initial:SetTextColor(1, 1, 1, 1)
        for _, e in ipairs(btn.edges) do e:SetColorTexture(r, g, b, 0.9) end
    else
        btn.fill:SetColorTexture(r * 0.12, g * 0.12, b * 0.12, 0.7)
        btn.initial:SetTextColor(r * 0.4, g * 0.4, b * 0.4, 0.6)
        for _, e in ipairs(btn.edges) do e:SetColorTexture(0, 0, 0, 0.4) end
    end
end
