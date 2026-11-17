local _, ns = ...

-- A round button on the minimap's rim. Drag it along the rim.

local button

local function place()
    local angle = math.rad(ns.db.minimapAngle)
    local radius = Minimap:GetWidth() / 2 + 6
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function follow()
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    if not mx or not scale or scale <= 0 then return end
    local atan = math.atan2 or math.atan
    ns.db.minimapAngle = math.deg(atan(cy / scale - my, cx / scale - mx)) % 360
    place()
end

local function tooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Wizard Buff", 1, 1, 1)
    GameTooltip:AddLine("Left-click: settings", 0.6, 0.6, 0.6)
    GameTooltip:AddLine("Right-click: show / hide", 0.6, 0.6, 0.6)
    GameTooltip:AddLine("Drag: move", 0.6, 0.6, 0.6)
    GameTooltip:Show()
end

function ns.createMinimapButton()
    if not Minimap then return end
    button = CreateFrame("Button", "WizardBuffMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("AnyUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\AddOns\\WizardBuff\\Media\\icon")

    local ring = button:CreateTexture(nil, "OVERLAY")
    ring:SetSize(53, 53)
    ring:SetPoint("TOPLEFT")
    ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    button:SetScript("OnClick", function(_, mouse)
        if mouse == "RightButton" then ns.toggleShown() else ns.openSettings() end
    end)
    button:SetScript("OnEnter", tooltip)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", follow) end)
    button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

    place()
    ns.updateMinimapButton()
end

function ns.updateMinimapButton()
    if button then button:SetShown(ns.db.minimap) end
end
