local _, ns = ...

local function hookHover(btn, mf)
    btn:HookScript("OnEnter", function()
        ns._hudMouseOver = true
        ns.ApplyHudFade()
    end)
    btn:HookScript("OnLeave", function() ns.ScheduleHudLeaveCheck(mf) end)
end

local function showIconTip(self, title)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(title, 0.85, 0.92, 1)
    if self.tooltipSpell then GameTooltip:AddLine(self.tooltipSpell, 1, 1, 1) end
    if self.tooltipTarget then GameTooltip:AddLine("Target: " .. self.tooltipTarget, 0.7, 0.7, 0.7) end
    if self.tooltipStatus then
        local c = ns.STATUS_COLORS[self.tooltipColor] or ns.STATUS_COLORS.neutral
        GameTooltip:AddLine(self.tooltipStatus, c[1], c[2], c[3], true)
    end
    if self.tooltipMode then GameTooltip:AddLine("Mode: " .. self.tooltipMode, 0.55, 0.55, 0.55) end
    GameTooltip:AddLine("Scroll to cycle spells", 0.4, 0.4, 0.4)
    GameTooltip:Show()
end

local function makeIconButton(name, parent)
    local b = CreateFrame("Button", name, parent, "SecureActionButtonTemplate")
    b:SetSize(ns.ICON_SIZE, ns.ICON_SIZE)
    ns.RegisterSecureClicks(b)
    b:SetAttribute("type", "spell")
    ns.StripSecureChrome(b)

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    ns.SetSolidColor(bg, 0, 0, 0, 0.7)

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", -1, 1)
    ns.CropIcon(icon)
    b.icon = icon

    local tag = b:CreateFontString(nil, "OVERLAY")
    tag:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE")
    tag:SetPoint("TOPRIGHT", b, "TOPRIGHT", 1, 1)
    tag:SetTextColor(1, 0.92, 0.55)
    tag:SetText("")
    b.modeTag = tag

    local slot = b:CreateFontString(nil, "OVERLAY")
    slot:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE")
    slot:SetPoint("TOP", b, "BOTTOM", 0, -1)
    slot:SetTextColor(0.55, 0.55, 0.58)
    slot:SetText("")
    b.slotLabel = slot

    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.15)
    hl:SetBlendMode("ADD")

    ns.CreateGlow(b)
    ns.CreateTimer(b)
    return b
end

function ns.CreateAutoBuffButton()
    local mf = ns.mainFrame
    local b = makeIconButton("WizardBuffAutoBuffButton", mf)
    ns.autoBuffButton = b
    b.icon:SetTexture(ns.ICON_PATHS.frostArmor)
    if b.slotLabel then b.slotLabel:SetText("Auto") end
    b:EnableMouseWheel(true)
    b:SetScript("OnEnter", function(self) showIconTip(self, "Auto Buff") end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:SetScript("OnMouseWheel", function(_, delta)
        ns.CycleMode("_selfMode", ns.BuildSelfSpellList, delta)
    end)
    hookHover(b, mf)
    ns.RegisterGlowButton(b)
    b:SetScript("PostClick", function(self, _, down)
        if not ns.IsClickRelease(down) or InCombatLockdown() then return end
        ns.MarkCastAttempt()
        if self._isIntCast then
            local unit = self:GetAttribute("unit")
            if unit then ns.MarkRecentlyBuffed(unit) end
        end
        ns.ScheduleUpdate(true)
    end)
end

function ns.CreateBrillianceButton()
    local mf = ns.mainFrame
    local b = makeIconButton("WizardBuffBrillianceButton", mf)
    ns.brillianceButton = b
    b.icon:SetTexture(ns.ICON_PATHS.int)
    if b.slotLabel then b.slotLabel:SetText("Group") end
    b:EnableMouseWheel(true)
    b:SetScript("OnEnter", function(self) showIconTip(self, "Group Buff") end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:SetScript("OnMouseWheel", function(_, delta)
        ns.CycleMode("_groupMode", ns.BuildGroupModeList, delta)
    end)
    hookHover(b, mf)
    ns.RegisterGlowButton(b)
    b:SetScript("PostClick", function(self, _, down)
        if not ns.IsClickRelease(down) or InCombatLockdown() then return end
        ns.MarkCastAttempt()
        local unit = self:GetAttribute("unit")
        if unit then ns.MarkRecentlyBuffed(unit) end
        ns.ScheduleUpdate(true)
    end)
end

function ns.CreateShieldButton()
    local mf = ns.mainFrame
    local b = makeIconButton("WizardBuffShieldButton", mf)
    ns.shieldButton = b
    b.icon:SetTexture(ns.ICON_PATHS.iceBarrier)
    if b.slotLabel then b.slotLabel:SetText("Shield") end
    b:EnableMouseWheel(true)
    b:SetScript("OnEnter", function(self) showIconTip(self, "Shield") end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:SetScript("OnMouseWheel", function(_, delta)
        ns.CycleMode("_shieldMode", ns.BuildShieldSpellList, delta)
    end)
    hookHover(b, mf)
    ns.RegisterGlowButton(b)
    b:SetScript("PostClick", function(self, _, down)
        if not ns.IsClickRelease(down) or InCombatLockdown() then return end
        ns.MarkCastAttempt()
        ns.ScheduleUpdate(true)
    end)
    b:Hide()
end

function ns.ApplyButtonSpec(btn, spec)
    if spec.spellName then
        ns.BindSecureSpell(btn, spec.spellName, spec.unit or "player")
    else
        ns.ClearSecureSpell(btn)
    end
    btn.icon:SetTexture(spec.icon)
    if spec.outOfRange then
        btn.icon:SetDesaturated(true)
        btn.icon:SetAlpha(0.45)
    elseif spec.needsAction then
        btn.icon:SetDesaturated(false)
        btn.icon:SetAlpha(1)
    else
        btn.icon:SetDesaturated(true)
        btn.icon:SetAlpha(0.55)
    end
    if btn.modeTag then btn.modeTag:SetText(spec.modeTag or "") end
    btn.tooltipSpell  = spec.tooltipSpell
    btn.tooltipTarget = spec.tooltipTarget
    btn.tooltipStatus = spec.tooltipStatus
    btn.tooltipMode   = spec.tooltipMode
    btn.tooltipColor  = spec.tooltipColor
    btn._isIntCast    = spec.isIntCast or false
    ns.SetButtonTimer(btn, spec.timerSec)
    ns.SetButtonGlow(btn, spec.needsAction and not spec.outOfRange)
end

function ns.PlaceHudIcons(mf, gripW)
    ns.autoBuffButton:ClearAllPoints()
    ns.autoBuffButton:SetPoint("TOPLEFT", mf, "TOPLEFT", gripW, 0)
    ns.brillianceButton:ClearAllPoints()
    ns.brillianceButton:SetPoint("LEFT", ns.autoBuffButton, "RIGHT", ns.ICON_GAP, 0)
    if ns.shieldButton then
        ns.shieldButton:ClearAllPoints()
        ns.shieldButton:SetPoint("LEFT", ns.brillianceButton, "RIGHT", ns.ICON_GAP, 0)
    end
end
