local _, ns = ...

-- The armor cell: the armor's name and time left, red when it's down. The
-- frames layout only has room for the short name ("Frost", "Ice", "Mage").

local armor = ns.armor
local grid = ns.grid
local cell

local function tooltip(self)
    local found = armor.found
    local spell, other = armor.choice()
    grid.tip(self, ns.spellbook.name(spell) or "Armor")
    if found.up == false then
        grid.line("Not up", grid.RED)
    elseif found.up == nil then
        grid.line("In combat, last known", grid.ORANGE)
    elseif found.left then
        grid.line(grid.timeText(found.left) .. " left", grid.GREEN)
    else
        grid.line("Up", grid.GREEN)
    end
    grid.line("Left-click: cast")
    if other then grid.line("Right-click: " .. (ns.spellbook.name(other) or "other armor")) end
    GameTooltip:Show()
end

function armor.createCell()
    cell = grid.cell("WizardBuffArmorButton")
    cell:SetAttribute("type1", "spell")
    cell:SetAttribute("unit1", "player")
    cell:SetAttribute("type2", "spell")
    cell:SetAttribute("unit2", "player")
    cell:SetScript("OnEnter", tooltip)
    armor.cell = cell
end

function armor.paint()
    local found = armor.found
    local name = ns.spellbook.name(armor.choice()) or "Armor"
    if not (grid.style and grid.style.plate) then name = name:match("^%S+") end
    local r, g, b = grid.ARMOR[1], grid.ARMOR[2], grid.ARMOR[3]
    local state, side
    if found.up == false then
        state, side = "missing", "off"
    elseif found.up == nil then
        state = "none"
    else
        state, side = armor.needed() and "soon" or "has", grid.timeText(found.left)
    end
    if ns.cantCast and state ~= "has" then state = "none" end
    local fraction = found.left and found.total and found.total > 0 and found.left / found.total or nil
    grid.paint(cell, state, name, r, g, b, side, fraction)
end

-- Out of combat only. Returns the cell if there is an armor to cast.
function armor.bind()
    local spell, other = armor.choice()
    grid.set(cell, "spell1", spell)
    grid.set(cell, "spell2", other)
    return spell and cell or nil
end
