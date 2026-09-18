local _, ns = ...

function ns.CreateGridCell(index)
    local mf = ns.mainFrame
    local btn = CreateFrame("Button", "WizardBuffCell" .. index, mf, "SecureActionButtonTemplate")
    btn:SetSize(ns.GRID_CELL_W, ns.GRID_CELL_H)
    ns.RegisterSecureClicks(btn)
    btn:SetAttribute("type", "spell")
    ns.StripSecureChrome(btn)

    local fill = btn:CreateTexture(nil, "BACKGROUND")
    fill:SetAllPoints()
    fill:SetColorTexture(0.12, 0.12, 0.12, 0.95)
    btn.fill = fill

    local initial = btn:CreateFontString(nil, "OVERLAY")
    initial:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    initial:SetPoint("CENTER")
    initial:SetShadowOffset(1, -1)
    btn.initial = initial

    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.16)
    hl:SetBlendMode("ADD")

    btn:SetScript("OnEnter", function(self)
        ns._hudMouseOver = true
        ns.ApplyHudFade()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local cr, cg, cb = 1, 1, 1
        if self.classColor then cr, cg, cb = unpack(self.classColor) end
        GameTooltip:AddLine(self.playerName or "?", cr, cg, cb)
        if self.ownerName then GameTooltip:AddLine("Pet · " .. self.ownerName, 0.5, 0.5, 0.5) end
        if self.isDead then
            GameTooltip:AddLine("Dead", 0.5, 0.5, 0.5)
        elseif self.isOffline then
            GameTooltip:AddLine("Offline", 0.5, 0.5, 0.5)
        elseif self.needsInt then
            GameTooltip:AddLine(self.outOfRange and "Needs Intellect (out of range)" or "Needs Intellect",
                1, self.outOfRange and 0.6 or 0.4, self.outOfRange and 0.2 or 0.4)
        elseif self.hasStrongerBrill then
            GameTooltip:AddLine("Buffed by other mage", 0.5, 0.8, 0.5)
        else
            local rem = self.buffRemaining
            if rem and rem > 0 then
                GameTooltip:AddLine(("Buffed (%d:%02d)"):format(math.floor(rem / 60), math.floor(rem % 60)), 0.4, 1, 0.4)
            else
                GameTooltip:AddLine("Buffed", 0.4, 1, 0.4)
            end
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
        ns.ScheduleHudLeaveCheck(mf)
    end)
    btn:SetScript("PostClick", function(self, _, down)
        if not ns.IsClickRelease(down) or InCombatLockdown() then return end
        ns.MarkCastAttempt()
        local unit = self:GetAttribute("unit")
        if unit then
            ns.MarkRecentlyBuffed(unit)
            ns.ScheduleUpdate(true)
            return
        end
        if not self.playerName then return end
        local reason
        if self.isDead then reason = self.playerName .. " is dead"
        elseif self.isOffline then reason = self.playerName .. " is offline"
        elseif self.outOfRange then reason = self.playerName .. " is out of range" end
        if reason then ns.ShowMessage(reason, 0.7, 0.7, 0.5) end
    end)
    btn:Hide()
    return btn
end

function ns.ApplyGridCellColor(btn)
    local r, g, b = 0.5, 0.5, 0.5
    if btn.classColor then r, g, b = unpack(btn.classColor) end
    if btn.isDead or btn.isOffline then
        btn.fill:SetColorTexture(0.10, 0.10, 0.10, 0.85)
        btn.initial:SetTextColor(0.35, 0.35, 0.35, 0.8)
    elseif btn.needsInt then
        local dim = btn.outOfRange and 0.28 or 0.55
        btn.fill:SetColorTexture(r * dim, g * dim, b * dim, 1)
        btn.initial:SetTextColor(1, 1, 1, btn.outOfRange and 0.55 or 1)
    else
        btn.fill:SetColorTexture(r * 0.16, g * 0.16, b * 0.16, 0.9)
        btn.initial:SetTextColor(r * 0.55, g * 0.55, b * 0.55, 0.85)
    end
end

function ns.HideUnusedGridCells(startIdx)
    for i = startIdx, #(ns.gridCells or {}) do
        ns.ClearSecureSpell(ns.gridCells[i])
        ns.gridCells[i]:Hide()
    end
end
