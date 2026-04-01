local _, ns = ...

local CELL       = ns.GRID_CELL_W
local CELL_BORDER = ns.GRID_BORDER

function ns.CreateGridCell(index)
    local mf  = ns.mainFrame
    local btn = CreateFrame("Button", "WizardBuffCell" .. index, mf, "SecureActionButtonTemplate")
    btn:SetSize(CELL, CELL)
    btn:RegisterForClicks("AnyUp", "AnyDown")
    btn:SetAttribute("type", "spell")
    ns.StripSecureActionChrome(btn)

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
        if self.isDead then
            GameTooltip:AddLine("Dead", 0.5, 0.5, 0.5)
        elseif self.isOffline then
            GameTooltip:AddLine("Offline", 0.5, 0.5, 0.5)
        elseif self.needsInt then
            if self.outOfRange then
                GameTooltip:AddLine("Needs Intellect (out of range)", 1, 0.6, 0.2)
            else
                GameTooltip:AddLine("Needs Intellect", 1, 0.4, 0.4)
            end
        else
            GameTooltip:AddLine("Buffed", 0.4, 1, 0.4)
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
        ns.ScheduleHudLeaveCheck(mf)
    end)

    btn:SetScript("PostClick", function(self)
        local unit = self:GetAttribute("unit")
        if unit and not InCombatLockdown() then
            ns.MarkRecentlyBuffed(unit)
            ns.ScheduleUpdate(true)
        end
    end)

    btn:Hide()
    return btn
end

function ns.ApplyGridCellColor(btn)
    local r, g, b = 0.5, 0.5, 0.5
    if btn.classColor then r, g, b = unpack(btn.classColor) end

    if btn.isDead or btn.isOffline then
        btn.fill:SetColorTexture(0.12, 0.12, 0.12, 0.6)
        btn.initial:SetTextColor(0.35, 0.35, 0.35, 0.7)
        for _, e in ipairs(btn.edges) do e:SetColorTexture(0.2, 0.2, 0.2, 0.5) end
    elseif btn.needsInt then
        local dim = btn.outOfRange and 0.25 or 0.45
        btn.fill:SetColorTexture(r * dim, g * dim, b * dim, 0.95)
        btn.initial:SetTextColor(1, 1, 1, btn.outOfRange and 0.5 or 1)
        for _, e in ipairs(btn.edges) do e:SetColorTexture(r, g, b, btn.outOfRange and 0.4 or 0.9) end
    else
        btn.fill:SetColorTexture(r * 0.12, g * 0.12, b * 0.12, 0.7)
        btn.initial:SetTextColor(r * 0.4, g * 0.4, b * 0.4, 0.6)
        for _, e in ipairs(btn.edges) do e:SetColorTexture(0, 0, 0, 0.4) end
    end
end
