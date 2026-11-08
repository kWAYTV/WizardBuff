local _, ns = ...

-- Minimap button (no LibDBIcon) plus the addon compartment entry from the TOC.

local button

local function onClick(_, mouse)
    if mouse == "RightButton" then
        ns.OpenSettings()
    elseif IsShiftKeyDown() then
        ns.ToggleLock()
    else
        ns.ToggleEnabled()
    end
end

local function tooltip(owner)
    GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
    GameTooltip:AddLine("Wizard Buff " .. ns.version, 1, 1, 1)
    local plan = ns.plan
    if ns.isMage then
        GameTooltip:AddLine((ns.db.enabled and "Shown" or "Hidden"), 0.7, 0.7, 0.7)
        if (plan.needMine or 0) > 0 then
            GameTooltip:AddLine(plan.needMine .. " need Intellect", 1, 0.4, 0.4)
        end
        if ns.Knows("BRILLIANCE") then
            GameTooltip:AddLine("Arcane Powder: " .. ns.PowderCount(), 0.7, 0.7, 0.7)
        end
    end
    local m = ns.COLORS.muted
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-click: show / hide", m[1], m[2], m[3])
    GameTooltip:AddLine("Shift-click: lock / unlock", m[1], m[2], m[3])
    GameTooltip:AddLine("Right-click: settings", m[1], m[2], m[3])
    GameTooltip:Show()
end

local function place()
    local angle = math.rad(ns.db.minimap.angle or 215)
    local radius = (Minimap:GetWidth() / 2) + 6
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function onDragUpdate()
    local mx, my = Minimap:GetCenter()
    local cx, cy = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    cx, cy = cx / scale, cy / scale
    ns.db.minimap.angle = math.deg(math.atan2(cy - my, cx - mx)) % 360
    place()
end

function ns.CreateMinimapButton()
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
    icon:SetTexture(ns.ICONS.addon)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    button:SetScript("OnClick", onClick)
    button:SetScript("OnEnter", tooltip)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", onDragUpdate) end)
    button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

    place()
    ns.UpdateMinimapButton()
end

function ns.UpdateMinimapButton()
    if button then button:SetShown(not ns.db.minimap.hide) end
end

-- Addon compartment (TOC: AddonCompartmentFunc*).
function WizardBuff_OnCompartmentClick(_, mouse)
    onClick(nil, mouse)
end

function WizardBuff_OnCompartmentEnter(_, owner)
    tooltip(owner)
end

function WizardBuff_OnCompartmentLeave()
    GameTooltip:Hide()
end
