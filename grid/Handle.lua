local _, ns = ...

-- What you grab to move everything: Alt-drag it, right-click for a menu,
-- hover for a summary. In the list it's the title bar; in the frames layout
-- a thin bar above the cells.

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
    local powder = ns.intellect.powder()
    if powder then grid.line("Arcane Powder: " .. powder, ns.intellect.powderLow() and grid.RED or nil) end
    grid.line("Alt-drag: move")
    grid.line("Right-click: menu")
    GameTooltip:Show()
end

function grid.createHandle()
    local frame = grid.frame
    handle = CreateFrame("Button", nil, frame)
    handle:RegisterForClicks("RightButtonUp")

    handle.back = handle:CreateTexture(nil, "ARTWORK")
    handle.back:SetAllPoints()
    local hover = handle:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0.15)

    handle.title = handle:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    handle.title:SetText("Wizard Buff")
    handle.title:SetTextColor(0.6, 0.6, 0.6)
    handle.count = handle:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")

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
    handle:SetScript("OnClick", function(self) grid.openMenu(self) end)
    handle:SetScript("OnEnter", tooltip)
    handle:SetScript("OnLeave", function() GameTooltip:Hide() end)
    grid.handle = handle
end

function grid.fitHandle(width)
    local px, titled = grid.px, grid.style.plate
    handle:ClearAllPoints()
    if titled then
        handle:SetPoint("TOPLEFT", grid.frame, "TOPLEFT", px, -px)
        handle:SetSize(width - 2 * px, grid.height)
        handle.back:SetColorTexture(0.13, 0.13, 0.13, 1)
        handle.title:SetFont(grid.font, grid.fontSize, "OUTLINE")
        handle.title:SetPoint("LEFT", 5 * px, 0)
        handle.count:SetFont(grid.font, grid.fontSize, "OUTLINE")
        handle.count:SetPoint("RIGHT", -5 * px, 0)
    else
        handle:SetPoint("BOTTOMLEFT", grid.frame, "TOPLEFT", 0, grid.gap)
        handle:SetSize(width, 4 * px)
        handle.back:SetColorTexture(0, 0, 0, 0.6)
    end
    handle.title:SetShown(titled and true or false)
    handle.count:SetShown(titled and true or false)
end

-- The title bar. Right: how many of the people who can be judged have the
-- buff. Left: the name, or a warning when Arcane Powder is running low.
function grid.summary(have, total)
    handle.count:SetText(total > 0 and (have .. "/" .. total) or "")
    if have < total then handle.count:SetTextColor(1, 0.4, 0.4) else handle.count:SetTextColor(0.55, 0.85, 0.6) end

    if ns.intellect.testing() then
        handle.title:SetText("Test")
        handle.title:SetTextColor(1, 0.8, 0.3)
    elseif ns.intellect.powderLow() then
        handle.title:SetText("Powder " .. ns.intellect.powder())
        handle.title:SetTextColor(1, 0.4, 0.4)
    else
        handle.title:SetText("Wizard Buff")
        handle.title:SetTextColor(0.6, 0.6, 0.6)
    end
end
