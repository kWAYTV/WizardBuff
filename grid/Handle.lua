local _, ns = ...

-- The thin bar above the cells. Alt-drag it to move everything, right-click
-- for settings, hover for a summary.

local grid = ns.grid
local handle

local function tooltip(self)
    local found = ns.intellect.found
    grid.tip(self, "Wizard Buff")
    if #found.missing > 0 then
        grid.line("No Intellect: " .. grid.names(found.missing, 10), grid.RED)
    elseif found.soonest then
        grid.line("All buffed, " .. grid.timeText(found.soonest) .. " left", grid.GREEN)
    end
    if found.stale then grid.line("In combat, last known", grid.ORANGE) end
    grid.line("Alt-drag: move")
    grid.line("Right-click: settings")
    GameTooltip:Show()
end

function grid.createHandle()
    local frame = grid.frame
    handle = CreateFrame("Button", nil, frame)
    handle:RegisterForClicks("RightButtonUp")

    local bar = handle:CreateTexture(nil, "ARTWORK")
    bar:SetAllPoints()
    bar:SetColorTexture(0, 0, 0, 0.6)
    local hover = handle:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0.35)

    handle:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and IsAltKeyDown() and not InCombatLockdown() then
            handle.moving = true
            frame:StartMoving()
        end
    end)
    local function drop()
        if not handle.moving then return end
        handle.moving = false
        frame:StopMovingOrSizing()
        grid.savePosition()
    end
    handle:SetScript("OnMouseUp", drop)
    handle:SetScript("OnHide", drop)
    handle:SetScript("OnClick", function() ns.openSettings() end)
    handle:SetScript("OnEnter", tooltip)
    handle:SetScript("OnLeave", function() GameTooltip:Hide() end)
    grid.handle = handle
end

function grid.fitHandle(width)
    handle:ClearAllPoints()
    handle:SetPoint("BOTTOMLEFT", grid.frame, "TOPLEFT", 0, grid.gap)
    handle:SetSize(width, 4 * grid.px)
end
