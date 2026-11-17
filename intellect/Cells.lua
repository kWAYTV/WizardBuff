local _, ns = ...

-- One cell per group member: their name in class colour, a line for the
-- time left, red when Intellect is missing. A cell belongs to a unit token
-- (party2, raid17) for good; roster changes only show, hide and move cells.

local intellect = ns.intellect
local grid = ns.grid
local cells = {}  -- unit token -> cell

local LABEL = {
    missing = "No Intellect", soon = "Runs out soon", has = "Intellect",
    none = "No mana", far = "Out of range", gone = "Dead or offline",
}

local function tooltip(self)
    local rec = self.rec
    if not rec then return end
    grid.tip(self, rec.name, grid.classColor(rec.class))
    local label = LABEL[rec.state]
    if rec.left and (rec.state == "has" or rec.state == "soon") then
        label = "Intellect " .. grid.timeText(rec.left)
    end
    local color = (rec.state == "missing" and grid.RED) or (rec.state == "soon" and grid.ORANGE)
        or (rec.state == "has" and grid.GREEN) or grid.GREY
    grid.line(label, color)
    if intellect.found.stale then grid.line("In combat, last known", grid.ORANGE) end
    grid.line("Left-click: " .. (ns.spellbook.name(intellect.ranks[1]) or "Arcane Intellect"))
    if ns.spellbook.knows(intellect.brilliance) then
        grid.line("Right-click: " .. (ns.spellbook.name(intellect.brilliance) or "Arcane Brilliance"))
    end
    GameTooltip:Show()
end

local function cell(unit)
    local b = cells[unit]
    if b then return b end
    b = grid.cell("WizardBuff_" .. unit)
    b:SetAttribute("unit", unit)
    b:SetAttribute("type1", "spell")
    b:SetAttribute("type2", "spell")
    b:SetScript("OnEnter", tooltip)
    cells[unit] = b
    return b
end

-- Points each member's cell at the right rank and returns the cells in
-- rows: one row in a party, one per raid group. Out of combat only.
function intellect.bindCells()
    local brilliance = ns.spellbook.knows(intellect.brilliance) and intellect.brilliance or nil
    local byGroup, order = {}, {}
    for _, rec in ipairs(intellect.found.members) do
        local b = cell(rec.unit)
        grid.set(b, "spell1", intellect.rank(rec.level))
        grid.set(b, "spell2", brilliance)
        local row = byGroup[rec.group]
        if not row then
            row = {}
            byGroup[rec.group] = row
            order[#order + 1] = rec.group
        end
        row[#row + 1] = b
    end
    table.sort(order)
    local rows = {}
    for i, group in ipairs(order) do rows[i] = byGroup[group] end
    return rows
end

function intellect.paintCells()
    for _, rec in ipairs(intellect.found.members) do
        local b = cells[rec.unit]
        if b then
            b.rec, b.state = rec, rec.state
            local r, g, bl = grid.classColor(rec.class)
            local fraction = rec.left and rec.total and rec.total > 0 and rec.left / rec.total or nil
            grid.paint(b, grid.LOOK[rec.state], rec.name, r, g, bl, nil, fraction)
        end
    end
end

function intellect.cell(unit)
    return cells[unit]
end
