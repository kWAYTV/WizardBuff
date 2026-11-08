local _, ns = ...
local UI = ns.UI

-- Click-to-cast group grid. One secure cell per member, one row per raid
-- group. The class-coloured fill is the Intellect time left: a full bar is
-- a fresh buff, an empty dark-red cell needs one.
--   Left-click: Arcane Intellect (right rank for the target's level)
--   Right-click: Arcane Brilliance
--   Shift / Ctrl: configurable
-- Cells are bound out of combat and stay clickable during fights.

local GAP = 2
local LABEL_W = 12

local cells, labels = {}, {}
local cellFor = {}  -- guid -> cell

local function shortName(name, maxChars)
    local out, n = {}, 0
    for ch in name:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        n = n + 1
        if n > maxChars then break end
        out[n] = ch
    end
    return table.concat(out)
end

local function statusText(rec)
    if rec.dead then return "Dead", ns.COLORS.muted end
    if rec.offline then return "Offline", ns.COLORS.muted end
    if rec.int == "unknown" then return "Buffs can't be read right now", ns.COLORS.muted end
    local left = ns.IntRemaining(rec)
    if rec.int == "yes" then
        if left then
            local c = rec.needs and ns.COLORS.warn or ns.COLORS.good
            return "Intellect: " .. ns.FormatTime(left) .. " left", c
        end
        return "Intellect: active", ns.COLORS.good
    end
    if not rec.inRange then return "Needs Intellect (out of range)", ns.COLORS.warn end
    return "Needs Intellect", ns.COLORS.bad
end

local function clickHelp(choice, prefix)
    local key = ns.ClickSpellKey(choice)
    local name = key and ns.SpellName(key)
    if name then GameTooltip:AddLine(prefix .. name, 0.55, 0.57, 0.62) end
end

local function onEnter(self)
    local rec = self.rec
    if not rec then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local r, g, b = UI.ClassColor(rec.class)
    GameTooltip:AddLine(rec.name, r, g, b)
    GameTooltip:AddLine((rec.isPet and "Pet · " or "") .. "Group " .. rec.group .. " · Level " .. (rec.level or "?"),
        0.55, 0.57, 0.62)
    local text, c = statusText(rec)
    GameTooltip:AddLine(text, c[1], c[2], c[3])
    if not rec.mine then
        local owner = ns.byGuid[ns.OwnerOf(rec.group) or ""]
        GameTooltip:AddLine("Covered by " .. (owner and owner.name or "another mage"), 0.55, 0.57, 0.62)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-click: " .. (ns.SpellName("INTELLECT") or "Intellect"), 0.55, 0.57, 0.62)
    if ns.Knows("BRILLIANCE") then
        GameTooltip:AddLine("Right-click: " .. ns.SpellName("BRILLIANCE"), 0.55, 0.57, 0.62)
    end
    clickHelp(ns.db.shiftClick, "Shift-click: ")
    clickHelp(ns.db.ctrlClick, "Ctrl-click: ")
    GameTooltip:Show()
end

local function postClick(self, button, down)
    if not UI.IsCastingClick(down) then return end
    local rec = self.rec
    if not rec then return end
    if rec.dead then ns.Feedback(rec.name .. " is dead")
    elseif rec.offline then ns.Feedback(rec.name .. " is offline")
    elseif not rec.inRange then ns.Feedback(rec.name .. " is out of range")
    end
    local mod = (IsShiftKeyDown() and ns.db.shiftClick) or (IsControlKeyDown() and ns.db.ctrlClick) or nil
    local isInt = button == "LeftButton" and (not mod or mod == "intellect")
    ns.NoteCastClick(isInt and rec.guid or nil, rec.unit)
end

local function createCell(i, parent)
    local b = CreateFrame("Button", "WizardBuffCell" .. i, parent, "SecureActionButtonTemplate")
    UI.RegisterSecureClicks(b)
    UI.Skin(b, { 0.07, 0.07, 0.09, 0.9 }, { 0, 0, 0, 1 })

    local fill = b:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMLEFT", 1, 1)
    fill:SetColorTexture(1, 1, 1, 1)
    b.fill = fill

    local name = UI.Text(b, 10)
    name:SetPoint("LEFT", 4, 0)
    name:SetPoint("RIGHT", -3, 0)
    name:SetJustifyH("LEFT")
    b.name = name

    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.12)

    UI.AddGlow(b, 1)
    b:SetScript("OnEnter", onEnter)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:SetScript("PostClick", postClick)
    b:Hide()
    return b
end

local function label(i, parent)
    local fs = labels[i]
    if not fs then
        fs = UI.Text(parent, 9)
        fs:SetTextColor(0.55, 0.57, 0.62)
        labels[i] = fs
    end
    return fs
end

local function bindCell(cell, rec)
    cell:SetAttribute("unit", rec.unit)
    cell:SetAttribute("type1", "spell")
    cell:SetAttribute("spell1", ns.BestForLevel("INTELLECT", rec.level))
    cell:SetAttribute("type2", "spell")
    cell:SetAttribute("spell2", ns.Best("BRILLIANCE"))
    for _, mod in ipairs({ "shift", "ctrl" }) do
        local key = ns.ClickSpellKey(ns.db[mod .. "Click"])
        local spell = key and (key == "INTELLECT" and ns.BestForLevel(key, rec.level) or ns.Best(key))
        cell:SetAttribute(mod .. "-type1", spell and "spell" or nil)
        cell:SetAttribute(mod .. "-spell1", spell)
    end
end

local function hideAll()
    for li = 1, #labels do labels[li]:Hide() end
    for _, cell in ipairs(cells) do
        cell.rec = nil
        cell:SetAttribute("unit", nil)
        cell:Hide()
    end
    wipe(cellFor)
end

-- The grid only shows in a group; solo, the bar says it all.
function ns.GridVisible()
    return IsInGroup() and #ns.members > 0
end

-- Lays the grid out at (left, top) from the parent's top-left corner.
-- Out of combat only. Returns the grid's width and height.
function ns.LayoutGrid(parent, left, top)
    if not ns.GridVisible() then hideAll(); return 0, 0 end
    local W, H = ns.db.cellWidth, ns.db.cellHeight
    local byRow, rowKeys = {}, {}
    for _, rec in ipairs(ns.members) do
        local key = rec.isPet and 99 or rec.group
        if not byRow[key] then byRow[key] = {}; rowKeys[#rowKeys + 1] = key end
        table.insert(byRow[key], rec)
    end
    table.sort(rowKeys)

    wipe(cellFor)
    local columns = ns.db.layout == "columns"
    local showLabels = IsInRaid() or byRow[99] ~= nil
    local offset = (showLabels and not columns) and LABEL_W or 0
    local labelH = (showLabels and columns) and 12 or 0
    local n, maxW, maxH = 0, 0, 0

    for li = 1, #labels do labels[li]:Hide() end

    for r, key in ipairs(rowKeys) do
        local recs = byRow[key]
        if showLabels then
            local fs = label(r, parent)
            fs:SetText(key == 99 and "P" or tostring(key))
            fs:ClearAllPoints()
            if columns then
                fs:SetPoint("TOP", parent, "TOPLEFT", left + (r - 1) * (W + GAP) + W / 2, -top)
            else
                fs:SetPoint("CENTER", parent, "TOPLEFT", left + LABEL_W / 2 - 1, -top - (r - 1) * (H + GAP) - H / 2)
            end
            fs:Show()
        end
        for c, rec in ipairs(recs) do
            n = n + 1
            local cell = cells[n]
            if not cell then cell = createCell(n, parent); cells[n] = cell end
            cell:SetSize(W, H)
            cell:ClearAllPoints()
            local x, y
            if columns then
                x, y = (r - 1) * (W + GAP), top + labelH + (c - 1) * (H + GAP)
            else
                x, y = offset + (c - 1) * (W + GAP), top + (r - 1) * (H + GAP)
            end
            cell:SetPoint("TOPLEFT", parent, "TOPLEFT", left + x, -y)
            maxW = math.max(maxW, x + W)
            maxH = math.max(maxH, y + H - top)
            cell.rec = rec
            cell.name:SetText(shortName(rec.name, math.max(1, math.floor((W - 6) / 6))))
            bindCell(cell, rec)
            cell:Show()
            cellFor[rec.guid] = cell
        end
    end

    for i = n + 1, #cells do
        cells[i].rec = nil
        cells[i]:SetAttribute("unit", nil)
        cells[i]:Hide()
    end

    ns.PaintGrid()
    return maxW, maxH
end

-- Visual state only; safe in combat.
function ns.PaintGrid()
    local W = ns.db.cellWidth
    local rebuff = (ns.db.rebuffMinutes or 5) * 60
    for _, cell in ipairs(cells) do
        local rec = cell.rec
        if rec and cell:IsShown() then
            local r, g, b = UI.ClassColor(rec.class)
            local needs = rec.needs
            local glow = false
            local left = ns.IntRemaining(rec)
            local frac = 0
            if rec.int == "yes" then
                frac = (left and (rec.duration or 0) > 0) and math.min(1, left / rec.duration) or 1
            end

            if rec.dead or rec.offline then
                cell.skinFill:SetColorTexture(0.06, 0.06, 0.06, 0.9)
                cell.name:SetTextColor(0.45, 0.45, 0.45)
                frac = 0
            elseif needs then
                cell.skinFill:SetColorTexture(0.32, 0.06, 0.06, 0.95)
                cell.name:SetTextColor(1, 1, 1)
                glow = rec.mine and rec.inRange
            else
                cell.skinFill:SetColorTexture(0.07, 0.07, 0.09, 0.9)
                cell.name:SetTextColor(1, 1, 1)
            end

            if frac > 0 then
                cell.fill:SetWidth(math.max(1, (W - 2) * frac))
                local dim = (left and left < rebuff) and 0.45 or 0.7
                cell.fill:SetColorTexture(r * dim, g * dim, b * dim, 1)
                cell.fill:Show()
            else
                cell.fill:Hide()
            end

            local alpha = 1
            if not rec.mine then alpha = 0.35
            elseif not rec.inRange and not rec.isMe then alpha = 0.5 end
            cell:SetAlpha(alpha)
            UI.SetGlow(cell, glow)
        end
    end
end

function ns.CellFor(guid)
    return cellFor[guid]
end
