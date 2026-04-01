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

-- Expose for GridCells
ns.StripSecureActionChrome = stripSecureActionChrome

---------------------------------------------------------------------------
-- Auto Buff button (left icon)
---------------------------------------------------------------------------
function ns.CreateAutoBuffButton()
    local mf = ns.mainFrame
    local b  = makeIconButton("WizardBuffAutoBuffButton", mf)
    ns.autoBuffButton = b
    b:SetPoint("TOPLEFT", mf, "TOPLEFT", ICON_PAD, -ICON_PAD)
    b.icon:SetTexture(ns.ICON_PATHS.int)

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
                if unit then ns.MarkRecentlyBuffed(unit) end
            end
            ns.ScheduleUpdate(true)
        end
    end)
end

---------------------------------------------------------------------------
-- Brilliance / group button (right icon)
---------------------------------------------------------------------------
function ns.CreateBrillianceButton()
    local mf = ns.mainFrame
    local b  = makeIconButton("WizardBuffBrillianceButton", mf)
    ns.brillianceButton = b
    b:SetPoint("LEFT", ns.autoBuffButton, "RIGHT", ICON_GAP, 0)
    b.icon:SetTexture(ns.ICON_PATHS.grpIdle)

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
            ns.MarkRecentlyBuffed(unit)
            ns.ScheduleUpdate(true)
        end
    end)
end
