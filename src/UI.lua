local _, ns = ...
ns = ns or _G.WizardBuffAddon
assert(ns, "WizardBuff: load WizardBuff.lua before UI.lua")

local ICON = 32
local PAD = 3
local GAP = 2

ns.UI_FRAME_W = PAD + ICON + GAP + ICON + PAD
ns.UI_BAR_H   = PAD + ICON + PAD

local CELL_W = 24
local CELL_H = 12
local CELL_GAP = 1
local ACCENT_W = 2
ns.GRID_CELL_W = CELL_W
ns.GRID_CELL_H = CELL_H
ns.GRID_GAP    = CELL_GAP
ns.GRID_PER_ROW = 4

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

local GLOW_R, GLOW_G, GLOW_B = 1, 0.75, 0.2
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
    local top, bottom, left, right = edges[1], edges[2], edges[3], edges[4]
    top:SetPoint("TOPLEFT", btn, "TOPLEFT", -GLOW_THICK, GLOW_THICK)
    top:SetPoint("TOPRIGHT", btn, "TOPRIGHT", GLOW_THICK, GLOW_THICK)
    top:SetHeight(GLOW_THICK)

    bottom:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", -GLOW_THICK, -GLOW_THICK)
    bottom:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", GLOW_THICK, -GLOW_THICK)
    bottom:SetHeight(GLOW_THICK)

    left:SetPoint("TOPLEFT", top, "BOTTOMLEFT", 0, 0)
    left:SetPoint("BOTTOMLEFT", bottom, "TOPLEFT", 0, 0)
    left:SetWidth(GLOW_THICK)

    right:SetPoint("TOPRIGHT", top, "BOTTOMRIGHT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", bottom, "TOPRIGHT", 0, 0)
    right:SetWidth(GLOW_THICK)

    btn.glowEdges = edges
    btn._glowPhase = 0
    btn._glowing = false
end

local GLOW_SPEED = 2.5
local GLOW_MIN = 0.5
local GLOW_MAX = 1.0

local function updateGlows(self, elapsed)
    for _, btn in ipairs(self._glowButtons) do
        if btn._glowing and btn.glowEdges then
            btn._glowPhase = (btn._glowPhase or 0) + elapsed * GLOW_SPEED
            local a = GLOW_MIN + (GLOW_MAX - GLOW_MIN) * (0.5 + 0.5 * math.sin(btn._glowPhase))
            for _, e in ipairs(btn.glowEdges) do
                e:SetAlpha(a)
            end
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
        for _, e in ipairs(btn.glowEdges) do
            e:SetAlpha(0)
            e:Hide()
        end
        btn._glowPhase = 0
    end
end

local function createTimer(btn)
    local t = btn:CreateFontString(nil, "OVERLAY")
    t:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    t:SetPoint("TOP", btn, "TOP", 0, -1)
    t:SetTextColor(1, 1, 1, 0.95)
    t:SetShadowOffset(1, -1)
    t:SetText("")
    btn.timerText = t
end

function ns.SetButtonTimer(btn, sec)
    if not btn or not btn.timerText then return end
    local d = ns.db
    if not d or not d.showTimers or not sec or sec <= 0 then
        btn.timerText:SetText("")
        return
    end
    if sec >= 3600 then
        btn.timerText:SetText(string.format("%dh", math.floor(sec / 3600)))
    elseif sec >= 60 then
        btn.timerText:SetText(string.format("%dm", math.floor(sec / 60)))
    else
        btn.timerText:SetText(string.format("%ds", math.floor(sec)))
        btn.timerText:SetTextColor(1, 0.6, 0.3)
        return
    end
    btn.timerText:SetTextColor(1, 1, 1, 0.95)
end

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

    local needLine = mf:CreateFontString(nil, "OVERLAY")
    needLine:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    needLine:SetShadowOffset(1, -1)
    needLine:SetText("")
    mf.needLine = needLine

    ns.ApplyHudScale()
end

local HANDLE_H = 10
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
    h:SetPoint("TOPLEFT", mf, "TOPLEFT", 0, 0)
    h:SetPoint("TOPRIGHT", mf, "TOPRIGHT", 0, 0)
    h:SetFrameStrata("MEDIUM")
    h:SetFrameLevel(mf:GetFrameLevel() + 5)
    h:EnableMouse(true)
    h:RegisterForDrag("LeftButton")
    h:RegisterForClicks("AnyUp")

    local hl = h:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.15)
    hl:SetBlendMode("ADD")

    local grip = h:CreateTexture(nil, "OVERLAY")
    grip:SetSize(16, 2)
    grip:SetPoint("CENTER", 0, 0)
    grip:SetColorTexture(1, 1, 1, 0)
    h.grip = grip

    h:SetScript("OnEnter", function(self)
        ns._hudMouseOver = true
        ns.ApplyHudFade()
        self.grip:SetColorTexture(1, 1, 1, 0.4)

        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Wizard Buff", 0.6, 0.8, 1)
        local locked = ns.db and ns.db.locked
        if locked then
            GameTooltip:AddLine("Right-click: config", 0.6, 0.6, 0.6)
            GameTooltip:AddLine("Shift+click: unlock", 0.6, 0.6, 0.6)
        else
            GameTooltip:AddLine("Drag to move", 0.6, 0.6, 0.6)
            GameTooltip:AddLine("Right-click: config", 0.6, 0.6, 0.6)
            GameTooltip:AddLine("Shift+click: lock", 0.6, 0.6, 0.6)
        end
        GameTooltip:Show()
    end)
    h:SetScript("OnLeave", function(self)
        self.grip:SetColorTexture(1, 1, 1, 0)
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
        if ns.db and not ns.db.locked then
            scheduleAutoLock()
        end
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

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.06, 0.06, 0.08, 0.9)
    b.bg = bg

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", -1, 1)
    b.icon = icon

    stripSecureActionChrome(b)
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
        if not InCombatLockdown() then self.bg:SetColorTexture(0.10, 0.10, 0.14, 1) end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Self", 0.85, 0.92, 1)
        if self.tooltipLine2 and self.tooltipLine2 ~= "" then
            GameTooltip:AddLine(self.tooltipLine2, 0.6, 0.6, 0.6, true)
        end
        GameTooltip:AddLine("/click WizardBuffAutoBuffButton", 0.4, 0.4, 0.4)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function(self)
        if not InCombatLockdown() then self.bg:SetColorTexture(0.06, 0.06, 0.08, 0.9) end
        GameTooltip:Hide()
    end)
    hookSecureHover(b, mf)
    ns.RegisterGlowButton(b)
end

function ns.CreateBrillianceButton()
    local mf = ns.mainFrame
    local b = makeIconButton("WizardBuffBrillianceButton", mf)
    ns.brillianceButton = b
    b:SetPoint("LEFT", ns.autoBuffButton, "RIGHT", GAP, 0)
    b.icon:SetTexture("Interface\\Icons\\Spell_Nature_Regeneration")

    b:SetScript("OnEnter", function(self)
        if not InCombatLockdown() then self.bg:SetColorTexture(0.10, 0.08, 0.14, 1) end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Group", 0.9, 0.85, 1)
        if self.tooltipLine2 and self.tooltipLine2 ~= "" then
            GameTooltip:AddLine(self.tooltipLine2, 0.6, 0.6, 0.6, true)
        end
        GameTooltip:AddLine("/click WizardBuffBrillianceButton", 0.4, 0.4, 0.4)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function(self)
        if not InCombatLockdown() then self.bg:SetColorTexture(0.06, 0.06, 0.08, 0.9) end
        GameTooltip:Hide()
    end)
    hookSecureHover(b, mf)
    ns.RegisterGlowButton(b)
end

function ns.CreateGridCell(index)
    local mf = ns.mainFrame
    local btn = CreateFrame("Button", "WizardBuffCell" .. index, mf, "SecureActionButtonTemplate")
    btn:SetSize(CELL_W, CELL_H)
    btn:RegisterForClicks("AnyUp", "AnyDown")
    btn:SetAttribute("type", "spell")
    stripSecureActionChrome(btn)

    local fill = btn:CreateTexture(nil, "BACKGROUND")
    fill:SetPoint("TOPLEFT", ACCENT_W, 0)
    fill:SetPoint("BOTTOMRIGHT", 0, 0)
    btn.fill = fill

    local accent = btn:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("BOTTOMLEFT", 0, 0)
    accent:SetWidth(ACCENT_W)
    btn.accent = accent

    local initial = btn:CreateFontString(nil, "OVERLAY")
    initial:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE")
    initial:SetPoint("CENTER", 1, 0)
    initial:SetShadowOffset(0, 0)
    btn.initial = initial

    btn:SetScript("OnEnter", function(self)
        ns._hudMouseOver = true
        ns.ApplyHudFade()
        local cr, cg, cb = 1, 1, 1
        if self.classColor then cr, cg, cb = unpack(self.classColor) end
        if self.fill then
            self.fill:SetColorTexture(cr * 0.35, cg * 0.35, cb * 0.35, 0.95)
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.playerName or "?", cr, cg, cb)
        if self.ownerName then
            GameTooltip:AddLine("Pet \194\183 " .. self.ownerName, 0.55, 0.55, 0.55)
        end
        if self.needsInt then
            GameTooltip:AddLine("Needs Intellect", 1, 0.4, 0.4)
        else
            GameTooltip:AddLine("Buffed", 0.4, 1, 0.4)
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        ns.ApplyGridCellColor(self)
        GameTooltip:Hide()
        scheduleHudLeaveCheck(mf)
    end)

    btn:Hide()
    return btn
end

function ns.ApplyGridCellColor(btn)
    local r, g, b = 0.5, 0.5, 0.5
    if btn.classColor then r, g, b = unpack(btn.classColor) end

    btn.accent:SetColorTexture(r, g, b, 0.9)

    if btn.needsInt then
        btn.fill:SetColorTexture(r * 0.55, g * 0.55, b * 0.55, 0.92)
        btn.initial:SetTextColor(1, 1, 1, 0.95)
    else
        btn.fill:SetColorTexture(r * 0.12, g * 0.12, b * 0.12, 0.75)
        btn.initial:SetTextColor(r * 0.5, g * 0.5, b * 0.5, 0.6)
    end
end
