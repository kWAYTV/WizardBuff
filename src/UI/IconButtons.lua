local _, ns = ...

local ICON_SIZE = ns.ICON_SIZE
local ICON_PAD  = ns.ICON_PAD
local ICON_GAP  = ns.ICON_GAP

---------------------------------------------------------------------------
-- Helpers
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
    btn:HookScript("OnLeave", function() ns.ScheduleHudLeaveCheck(mf) end)
end

local function showRichTooltip(self, title, titleR, titleG, titleB)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(title, titleR, titleG, titleB)
    if self.tooltipSpell then
        GameTooltip:AddLine(self.tooltipSpell, 1, 1, 1)
    end
    if self.tooltipTarget then
        local tgt = self.tooltipTarget
        GameTooltip:AddLine("Target: " .. tgt, 0.7, 0.7, 0.7)
    end
    if self.tooltipStatus then
        local sr, sg, sb = 0.6, 0.6, 0.6
        local s = self.tooltipStatus
        if s:find("Out of range") then
            sr, sg, sb = 1, 0.5, 0.2
        elseif s:find("move closer") then
            sr, sg, sb = 1, 0.65, 0.3
        elseif s:find("Needs cast") or s:find("HP below") then
            sr, sg, sb = 1, 0.4, 0.4
        elseif s:find("Active") or s:find("buffed") or s:find("In range") then
            sr, sg, sb = 0.4, 1, 0.4
        end
        GameTooltip:AddLine(s, sr, sg, sb, true)
    end
    if self.tooltipMode then
        GameTooltip:AddLine("Mode: " .. self.tooltipMode, 0.55, 0.55, 0.55)
    end
    GameTooltip:AddLine("Scroll to cycle spells", 0.4, 0.4, 0.4)
    GameTooltip:Show()
end

local function makeIconButton(name, parent)
    local b = CreateFrame("Button", name, parent, "SecureActionButtonTemplate")
    b:SetSize(ICON_SIZE, ICON_SIZE)
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

    ns.CreateGlow(b)
    ns.CreateTimer(b)
    return b
end

ns.StripSecureActionChrome = stripSecureActionChrome

---------------------------------------------------------------------------
-- Auto Buff button (left icon)
---------------------------------------------------------------------------
function ns.CreateAutoBuffButton()
    local mf = ns.mainFrame
    local b  = makeIconButton("WizardBuffAutoBuffButton", mf)
    ns.autoBuffButton = b
    b:SetPoint("TOPLEFT", mf, "TOPLEFT", ICON_PAD, -ICON_PAD)
    b.icon:SetTexture(ns.ICON_PATHS.frostArmor)
    b:EnableMouseWheel(true)

    b:SetScript("OnEnter", function(self)
        showRichTooltip(self, "Self Buff", 0.85, 0.92, 1)
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:SetScript("OnMouseWheel", function(_, delta)
        ns.CycleMode("_selfMode", ns.BuildSelfSpellList, delta)
    end)
    hookSecureHover(b, mf)
    ns.RegisterGlowButton(b)

    b:SetScript("PostClick", function(self)
        if not InCombatLockdown() then
            if self._isIntCast then
                local unit = self:GetAttribute("unit")
                if unit then ns.MarkRecentlyBuffed(unit) end
            end
            ns.ScheduleUpdate(true)
        end
    end)
end

---------------------------------------------------------------------------
-- Brilliance / group button (middle icon)
---------------------------------------------------------------------------
function ns.CreateBrillianceButton()
    local mf = ns.mainFrame
    local b  = makeIconButton("WizardBuffBrillianceButton", mf)
    ns.brillianceButton = b
    b:SetPoint("LEFT", ns.autoBuffButton, "RIGHT", ICON_GAP, 0)
    b.icon:SetTexture(ns.ICON_PATHS.int)
    b:EnableMouseWheel(true)

    b:SetScript("OnEnter", function(self)
        showRichTooltip(self, "Group", 0.9, 0.85, 1)
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:SetScript("OnMouseWheel", function(_, delta)
        ns.CycleMode("_groupMode", ns.BuildGroupModeList, delta)
    end)
    hookSecureHover(b, mf)
    ns.RegisterGlowButton(b)

    b:SetScript("PostClick", function(self)
        local unit = self:GetAttribute("unit")
        if unit and not InCombatLockdown() then
            ns.MarkRecentlyBuffed(unit)
            ns.ScheduleUpdate(true)
        end
    end)
end

---------------------------------------------------------------------------
-- Shield button (right icon)
---------------------------------------------------------------------------
function ns.CreateShieldButton()
    local mf = ns.mainFrame
    local b  = makeIconButton("WizardBuffShieldButton", mf)
    ns.shieldButton = b
    b:SetPoint("LEFT", ns.brillianceButton, "RIGHT", ICON_GAP, 0)
    b.icon:SetTexture(ns.ICON_PATHS.iceBarrier)
    b:EnableMouseWheel(true)

    b:SetScript("OnEnter", function(self)
        showRichTooltip(self, "Self", 0.85, 0.85, 1)
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:SetScript("OnMouseWheel", function(_, delta)
        ns.CycleMode("_shieldMode", ns.BuildShieldSpellList, delta)
    end)
    hookSecureHover(b, mf)
    ns.RegisterGlowButton(b)

    b:SetScript("PostClick", function()
        if not InCombatLockdown() then
            ns.ScheduleUpdate(true)
        end
    end)

    b:Hide()
end
