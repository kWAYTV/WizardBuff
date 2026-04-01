local _, ns = ...
ns = ns or _G.WizardBuffAddon
assert(ns, "WizardBuff: load WizardBuff.lua before UI.lua")

local CLASS_ORDER = ns.CLASS_ORDER
local CLASS_COLORS = ns.CLASS_COLORS
local db

function ns.SetUIContext(dbTable)
    db = dbTable
end

local ICON = 32
local PAD = 3
local GAP = 2
local NEED_H = 12

ns.UI_FRAME_W = PAD + ICON + GAP + ICON + PAD
ns.UI_BAR_H   = PAD + ICON + PAD
ns.UI_ROWS_TOP = -(PAD + ICON + PAD)
ns.UI_ROW_H = 18
ns.UI_CLASS_ROW_W = 120
ns.UI_PLAYER_BTN_W = 106

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

function ns.ApplySlotBadges()
    local auto = ns.autoBuffButton
    local brill = ns.brillianceButton
    if not auto or not brill then return end
    if auto.slotBadge  then auto.slotBadge:Hide()  end
    if brill.slotBadge then brill.slotBadge:Hide() end
end

function ns.RefreshHudChrome()
    local d = ns.db
    local mf = ns.mainFrame
    if not mf or not d then return end
    if mf.title then mf.title:Hide() end

    local showNeed = d.showHudNeedCount and true or false
    if mf.needLine then mf.needLine:SetShown(showNeed) end

    local h = PAD + ICON + PAD
    if showNeed then h = h + NEED_H end
    mf:SetHeight(h)
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

    local bg = mf:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.03, 0.03, 0.04, 0.82)
    mf.bg = bg

    mf:RegisterForDrag("LeftButton")
    mf:SetScript("OnDragStart", function(self)
        if not InCombatLockdown() and not (ns.db and ns.db.locked) then
            self:StartMoving()
        end
    end)
    mf:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if ns.db then
            local point, _, relPoint, x, y = self:GetPoint(1)
            ns.db.hudPos = { point = point, relPoint = relPoint, x = x, y = y }
        end
    end)

    mf:SetScript("OnEnter", function()
        ns._hudMouseOver = true
        ns.ApplyHudFade()
    end)
    mf:SetScript("OnLeave", function() scheduleHudLeaveCheck(mf) end)

    mf:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" and ns.OpenConfig then
            ns.OpenConfig()
        end
    end)

    local needLine = mf:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    needLine:SetPoint("BOTTOM", mf, "BOTTOM", 0, 2)
    needLine:SetText("")
    mf.needLine = needLine

    mf.title = mf:CreateFontString(nil, "OVERLAY")
    mf.title:Hide()

    mf.autoStatus  = mf:CreateFontString(nil, "OVERLAY")
    mf.autoStatus:Hide()
    mf.brillStatus = mf:CreateFontString(nil, "OVERLAY")
    mf.brillStatus:Hide()

    ns.ApplyHudScale()
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
    b.text = nil

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

    b.slotBadge = b:CreateFontString(nil, "OVERLAY")
    b.slotBadge:Hide()

    b:SetScript("OnEnter", function(self)
        if not InCombatLockdown() then self.bg:SetColorTexture(0.10, 0.10, 0.14, 1) end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Auto", 0.85, 0.92, 1)
        if self.tooltipLine2 and self.tooltipLine2 ~= "" then
            GameTooltip:AddLine(self.tooltipLine2, 0.6, 0.6, 0.6, true)
        end
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

    b.slotBadge = b:CreateFontString(nil, "OVERLAY")
    b.slotBadge:Hide()

    b:SetScript("OnEnter", function(self)
        if not InCombatLockdown() then self.bg:SetColorTexture(0.10, 0.08, 0.14, 1) end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Group", 0.9, 0.85, 1)
        if self.tooltipLine2 and self.tooltipLine2 ~= "" then
            GameTooltip:AddLine(self.tooltipLine2, 0.6, 0.6, 0.6, true)
        end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function(self)
        if not InCombatLockdown() then self.bg:SetColorTexture(0.06, 0.06, 0.08, 0.9) end
        GameTooltip:Hide()
    end)
    hookSecureHover(b, mf)
    ns.RegisterGlowButton(b)
end

function ns.CreateClassButton(classIndex)
    local class = CLASS_ORDER[classIndex]
    local mf = ns.mainFrame
    local playerButtons = ns.playerButtons
    local W = ns.UI_CLASS_ROW_W

    local btn = CreateFrame("Button", "WizardBuffClass" .. classIndex, mf, "SecureActionButtonTemplate")
    btn:SetSize(W, ns.UI_ROW_H)
    btn:RegisterForClicks("LeftButtonUp")
    local r, g, b = unpack(CLASS_COLORS[class] or {0.5, 0.5, 0.5})

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(r * 0.10, g * 0.10, b * 0.10, 0.85)
    btn.bg = bg
    btn.color = {r, g, b}

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ns.UI_ROW_H - 2, ns.UI_ROW_H - 2)
    icon:SetPoint("LEFT", 2, 0)
    if class == "PET" then
        icon:SetTexture("Interface\\Icons\\Ability_Hunter_BeastCall")
    else
        icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
        local coords = CLASS_ICON_TCOORDS[class]
        if coords then icon:SetTexCoord(unpack(coords)) end
    end
    btn.icon = icon

    local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetPoint("LEFT", icon, "RIGHT", 3, 0)
    txt:SetTextColor(r * 0.9, g * 0.9, b * 0.9)
    btn.text = txt

    local count = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    count:SetPoint("RIGHT", -3, 0)
    btn.count = count
    btn.class = class
    btn.classIndex = classIndex

    btn:SetScript("OnEnter", function(self)
        if not InCombatLockdown() then
            self.bg:SetColorTexture(r * 0.22, g * 0.22, b * 0.22, 0.95)
            if playerButtons[classIndex] then
                for _, pb in pairs(playerButtons[classIndex]) do
                    if pb.inUse then pb:Show() end
                end
            end
        end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:AddLine(class:sub(1,1) .. class:sub(2):lower(), r, g, b)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        if not InCombatLockdown() then
            self.bg:SetColorTexture(r * 0.10, g * 0.10, b * 0.10, 0.85)
        end
        GameTooltip:Hide()
        C_Timer.After(0.4, function()
            if not InCombatLockdown() and playerButtons[classIndex] then
                local anyHovered = self:IsMouseOver()
                for _, pb in pairs(playerButtons[classIndex]) do
                    if pb:IsMouseOver() then anyHovered = true end
                end
                if not anyHovered then
                    for _, pb in pairs(playerButtons[classIndex]) do pb:Hide() end
                end
            end
        end)
    end)
    return btn
end

function ns.CreatePlayerButton(classIndex, playerIndex)
    local class = CLASS_ORDER[classIndex]
    local mf = ns.mainFrame
    local playerButtons = ns.playerButtons
    local classButtons = ns.classButtons

    local btn = CreateFrame("Button", "WizardBuffPlayer" .. classIndex .. "_" .. playerIndex, mf, "SecureActionButtonTemplate")
    btn:SetSize(ns.UI_PLAYER_BTN_W, ns.UI_ROW_H - 1)
    btn:RegisterForClicks("LeftButtonUp")
    btn:SetFrameStrata("TOOLTIP")
    local r, g, b = unpack(CLASS_COLORS[class] or {1, 1, 1})

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.03, 0.03, 0.04, 0.95)
    btn.bg = bg

    local accent = btn:CreateTexture(nil, "BORDER")
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("BOTTOMLEFT", 0, 0)
    accent:SetWidth(2)
    accent:SetColorTexture(r * 0.55, g * 0.55, b * 0.55, 0.7)
    btn.accent = accent

    local txt = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetPoint("LEFT", 6, 0)
    txt:SetTextColor(r * 0.95, g * 0.95, b * 0.95)
    btn.text = txt

    local intIcon = btn:CreateTexture(nil, "ARTWORK")
    intIcon:SetSize(11, 11)
    intIcon:SetPoint("RIGHT", -3, 0)
    intIcon:SetTexture("Interface\\Icons\\Spell_Holy_MagicalSentry")
    btn.intIcon = intIcon

    btn:SetScript("OnEnter", function(self)
        if not InCombatLockdown() then self.bg:SetColorTexture(0.06, 0.06, 0.09, 1) end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.playerName or "Player", r, g, b)
        if self.ownerName then
            GameTooltip:AddLine("Pet \194\183 " .. self.ownerName, 0.55, 0.55, 0.55)
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        if not InCombatLockdown() then self.bg:SetColorTexture(0.03, 0.03, 0.04, 0.95) end
        GameTooltip:Hide()
        local classBtn = classButtons[classIndex]
        C_Timer.After(0.25, function()
            if not InCombatLockdown() and classBtn and not classBtn:IsMouseOver() and not self:IsMouseOver() then
                local anyHovered = false
                for _, pb in pairs(playerButtons[classIndex]) do
                    if pb:IsMouseOver() then anyHovered = true end
                end
                if not anyHovered then self:Hide() end
            end
        end)
    end)
    btn.inUse = false
    btn.classIndex = classIndex
    btn:Hide()
    return btn
end
