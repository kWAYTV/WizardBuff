local _, ns = ...
local UI = ns.UI

-- PallyPower-style assignment table: one row per mage, one column per raid
-- group. Click a box to give that group to that mage. Changes are shared
-- with every mage running the addon.

local CELL_W, CELL_H, NAME_W, PAD = 26, 18, 110, 8

local win, rows, footer, modeText = nil, {}, nil, nil

local function groupCounts()
    local counts = {}
    for _, rec in ipairs(ns.members) do
        if not rec.isPet then counts[rec.group] = (counts[rec.group] or 0) + 1 end
    end
    return counts
end

local function makeBox(parent)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(CELL_W, CELL_H)
    UI.Skin(b, { 0.12, 0.12, 0.14, 1 })
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.15)
    return b
end

local function getRow(i)
    local row = rows[i]
    if row then return row end
    row = CreateFrame("Frame", nil, win)
    row:SetSize(NAME_W + 8 * (CELL_W + 2), CELL_H)
    row.name = UI.Text(row, 11)
    row.name:SetPoint("LEFT")
    row.name:SetWidth(NAME_W - 4)
    row.name:SetJustifyH("LEFT")
    row.boxes = {}
    for g = 1, 8 do
        local b = makeBox(row)
        b:SetPoint("LEFT", row, "LEFT", NAME_W + (g - 1) * (CELL_W + 2), 0)
        b.group = g
        b:SetScript("OnClick", function(self)
            if row.guid then ns.SetGroupOwner(self.group, row.guid) end
        end)
        row.boxes[g] = b
    end
    rows[i] = row
    return row
end

function ns.RefreshAssign()
    if not win or not win:IsShown() then return end
    local mages = ns.GroupMages()
    local counts = groupCounts()
    local c = ns.COLORS.accent

    for i, m in ipairs(mages) do
        local row = getRow(i)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", PAD, -(26 + 14 + (i - 1) * (CELL_H + 4)))
        row.guid = m.guid
        local label = m.name .. (m.hasAddon and "" or ns.Colorize(" (no addon)", ns.COLORS.muted))
        row.name:SetText(label)
        local r, g, b = UI.ClassColor("MAGE")
        row.name:SetTextColor(r, g, b)
        for grp = 1, 8 do
            local box = row.boxes[grp]
            local owned = ns.OwnerOf(grp) == m.guid
            local present = (counts[grp] or 0) > 0
            if owned then
                box.skinFill:SetColorTexture(c[1], c[2], c[3], 0.85)
            elseif present then
                box.skinFill:SetColorTexture(0.16, 0.17, 0.2, 1)
            else
                box.skinFill:SetColorTexture(0.08, 0.08, 0.09, 1)
            end
            box:SetEnabled(present)
        end
        row:Show()
    end
    for i = #mages + 1, #rows do rows[i]:Hide() end

    local manual = ns.IsManualAssign()
    modeText:SetText(manual and "Manual split" or "Automatic split")
    if #mages == 0 then modeText:SetText("No mages in the raid") end
    win:SetHeight(26 + 14 + math.max(1, #mages) * (CELL_H + 4) + 36)
end

local function create()
    win = CreateFrame("Frame", "WizardBuffAssign", UIParent)
    win:SetSize(PAD * 2 + NAME_W + 8 * (CELL_W + 2), 160)
    win:SetPoint("CENTER")
    win:SetFrameStrata("DIALOG")
    win:SetMovable(true)
    win:EnableMouse(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", win.StopMovingOrSizing)
    win:SetClampedToScreen(true)
    UI.Skin(win)
    tinsert(UISpecialFrames, "WizardBuffAssign")

    local title = UI.Text(win, 12)
    title:SetPoint("TOPLEFT", PAD, -8)
    title:SetText(ns.Colorize("Mage assignments", ns.COLORS.accent))

    local close = UI.HeaderButton(win, nil, "x", 16)
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() win:Hide() end)

    for g = 1, 8 do
        local fs = UI.Text(win, 10)
        fs:SetPoint("TOP", win, "TOPLEFT", PAD + NAME_W + (g - 1) * (CELL_W + 2) + CELL_W / 2, -26)
        fs:SetText("G" .. g)
        fs:SetTextColor(0.55, 0.57, 0.62)
    end

    footer = CreateFrame("Frame", nil, win)
    footer:SetPoint("BOTTOMLEFT", PAD, PAD)
    footer:SetPoint("BOTTOMRIGHT", -PAD, PAD)
    footer:SetHeight(20)

    local auto = UI.HeaderButton(footer, nil, "Auto split", 20)
    UI.Skin(auto, { 0.15, 0.17, 0.22, 1 })
    auto:SetPoint("LEFT")
    auto:SetScript("OnClick", function() ns.AutoAssign() end)

    modeText = UI.Text(footer, 10)
    modeText:SetPoint("LEFT", auto, "RIGHT", 8, 0)
    modeText:SetTextColor(0.55, 0.57, 0.62)

    local hint = UI.Text(footer, 9)
    hint:SetPoint("RIGHT")
    hint:SetText("Click a box to assign")
    hint:SetTextColor(0.45, 0.47, 0.52)

    win:SetScript("OnShow", ns.RefreshAssign)
    win:Hide()

    ns.Listen("ASSIGN_CHANGED", ns.RefreshAssign)
    ns.Listen("ROSTER_SCANNED", ns.RefreshAssign)
end

function ns.ToggleAssign()
    if not IsInRaid() then
        ns.Print("Assignments are for raids. In a party every mage covers everyone.")
        return
    end
    if not win then create() end
    win:SetShown(not win:IsShown())
end
