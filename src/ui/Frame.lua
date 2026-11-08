local _, ns = ...
local UI = ns.UI

-- The HUD: the icon bar on top, the group grid under it (in a group), and a
-- "Your groups" line in raids. No title bar. While unlocked, a mover overlay
-- covers it: drag to place, right-click to lock.

local GRID_PAD = 3
local BAR_GAP = 4

local frame, panel, mover, feedback, groupsLine
local feedbackUntil = 0

local function savePosition()
    local point, _, relPoint, x, y = frame:GetPoint(1)
    ns.db.pos = { point = point, relPoint = relPoint, x = x, y = y }
end

function ns.RestorePosition()
    if InCombatLockdown() or not frame then return end
    frame:ClearAllPoints()
    local p = ns.db.pos
    if p and p.point then
        frame:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, -160)
    end
end

-- Shows the mover while unlocked and out of combat.
function ns.UpdateMover()
    if not mover then return end
    mover:SetShown(not ns.db.locked and not InCombatLockdown() and frame:IsShown())
end
ns.UpdateLockIcon = ns.UpdateMover

function ns.ToggleLock()
    ns.db.locked = not ns.db.locked
    ns.UpdateMover()
    ns.Print(ns.db.locked and "Locked." or "Unlocked: drag to move, right-click to lock.")
end

local function createMover()
    mover = CreateFrame("Button", nil, frame)
    mover:SetPoint("TOPLEFT", -4, 4)
    mover:SetPoint("BOTTOMRIGHT", 4, -4)
    mover:SetFrameStrata("HIGH")
    mover:RegisterForClicks("RightButtonUp")
    mover:RegisterForDrag("LeftButton")
    UI.Skin(mover, { ns.COLORS.accent[1], ns.COLORS.accent[2], ns.COLORS.accent[3], 0.18 },
        { ns.COLORS.accent[1], ns.COLORS.accent[2], ns.COLORS.accent[3], 0.9 })

    local title = UI.Text(mover, 11)
    title:SetPoint("BOTTOMLEFT", mover, "TOPLEFT", 0, 3)
    title:SetText(ns.Colorize("Wizard Buff", ns.COLORS.accent) .. "  "
        .. ns.Colorize("drag to move · right-click to lock", ns.COLORS.muted))

    mover:SetScript("OnDragStart", function()
        if InCombatLockdown() then return end
        frame:StartMoving()
    end)
    mover:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        savePosition()
    end)
    mover:SetScript("OnClick", function() ns.ToggleLock() end)
    mover:Hide()
end

function ns.CreateHUD()
    frame = CreateFrame("Frame", "WizardBuffFrame", UIParent)
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetSize(160, 50)
    ns.frame = frame

    ns.CreateBar(frame)

    panel = CreateFrame("Frame", nil, frame)
    panel:SetFrameLevel(frame:GetFrameLevel())  -- under the grid cells
    UI.Skin(panel, { 0, 0, 0, 0.45 }, { 0, 0, 0, 0.8 })
    panel:Hide()

    groupsLine = CreateFrame("Button", nil, frame)
    groupsLine:SetHeight(14)
    local gl = UI.Text(groupsLine, 10)
    gl:SetPoint("LEFT")
    groupsLine.text = gl
    groupsLine:SetScript("OnClick", function() ns.ToggleAssign() end)
    groupsLine:SetScript("OnEnter", function(self)
        self.text:SetAlpha(1)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("Mage assignments", 1, 1, 1)
        GameTooltip:AddLine("Click to choose which groups each mage buffs.", 0.55, 0.57, 0.62, true)
        GameTooltip:Show()
    end)
    groupsLine:SetScript("OnLeave", function(self)
        self.text:SetAlpha(0.8)
        GameTooltip:Hide()
    end)
    groupsLine.text:SetAlpha(0.8)
    groupsLine:Hide()

    feedback = UI.Text(frame, 12)
    feedback:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 6)
    feedback:SetAlpha(0)

    createMover()

    local elapsed = 0
    frame:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        if feedbackUntil > 0 then
            local left = feedbackUntil - GetTime()
            if left <= 0 then
                feedbackUntil = 0
                feedback:SetAlpha(0)
            elseif left < 0.5 then
                feedback:SetAlpha(left / 0.5)
            end
        end
        if elapsed < 0.2 then return end
        elapsed = 0
        local a = ns.db.alpha
        if InCombatLockdown() then a = ns.db.combatAlpha end
        if self:IsMouseOver(4, -4, -4, 4) then a = 1 end
        self:SetAlpha(a)
    end)

    frame:SetScale(ns.db.scale)
    ns.RestorePosition()
    frame:Hide()
end

function ns.ShouldShow()
    return ns.isMage and ns.db.enabled and (IsInGroup() or ns.db.showSolo)
end

-- Short message above the HUD that fades out.
function ns.Feedback(text, c)
    if not feedback then return end
    c = c or ns.COLORS.warn
    feedback:SetText(text)
    feedback:SetTextColor(c[1], c[2], c[3])
    feedback:SetAlpha(1)
    feedbackUntil = GetTime() + 3
end

local function coverageText()
    if not IsInRaid() or not ns.db.coordinate then return nil end
    if not ns.owners then
        return "Whole raid is yours  ·  mages"
    end
    local mine = {}
    for g, guid in pairs(ns.owners) do
        if guid == UnitGUID("player") then mine[#mine + 1] = g end
    end
    table.sort(mine)
    if #mine == 0 then return "No groups assigned  ·  mages" end
    return "Your groups: " .. table.concat(mine, " ") .. "  ·  mages"
end

-- Text that changes without a layout pass. Safe in combat.
function ns.RefreshStatus()
    if not groupsLine or not groupsLine:IsShown() then return end
    local text = coverageText() or ""
    local m = ns.COLORS.muted
    groupsLine.text:SetText(text)
    groupsLine.text:SetTextColor(m[1], m[2], m[3])
end

-- Full layout pass. Out of combat only.
function ns.LayoutHUD()
    if InCombatLockdown() or not frame then return end
    if not ns.ShouldShow() then frame:Hide(); ns.UpdateMover(); return end

    frame:SetScale(ns.db.scale)
    local barW, barH = ns.LayoutBar()
    local width, height = barW, barH

    local top = barH + BAR_GAP
    local gridW, gridH = ns.LayoutGrid(frame, GRID_PAD, top + GRID_PAD)
    if gridW > 0 then
        panel:ClearAllPoints()
        panel:SetPoint("TOPLEFT", 0, -top)
        panel:SetSize(gridW + GRID_PAD * 2, gridH + GRID_PAD * 2)
        panel:Show()
        width = math.max(width, gridW + GRID_PAD * 2)
        height = top + gridH + GRID_PAD * 2
    else
        panel:Hide()
    end

    local cover = coverageText()
    if cover then
        groupsLine:ClearAllPoints()
        groupsLine:SetPoint("TOPLEFT", 1, -(height + 2))
        groupsLine:SetWidth(math.max(width, 120))
        groupsLine:Show()
        height = height + 16
        ns.RefreshStatus()
    else
        groupsLine:Hide()
    end

    frame:SetSize(math.max(width, 1), math.max(height, 1))
    frame:Show()
    ns.UpdateMover()
end

function ns.HideHUD()
    if frame and not InCombatLockdown() then frame:Hide() end
end
