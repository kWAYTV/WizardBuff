local _, ns = ...

local armor = ns.armor
local icons = ns.icons
local button

local function tooltip(self)
    local found = armor.found
    local spell, other = armor.choice()
    icons.tip(self, ns.spellbook.name(spell) or "Armor")
    if found.up == false then
        icons.line("Not up", icons.RED)
    elseif found.up == nil then
        icons.line("In combat, last known", icons.ORANGE)
    elseif found.left then
        icons.line(icons.timeText(found.left) .. " left", icons.GREEN)
    else
        icons.line("Up", icons.GREEN)
    end
    icons.line("Left-click: cast")
    if other then icons.line("Right-click: " .. (ns.spellbook.name(other) or "other armor")) end
    icons.line("Alt-drag: move")
    GameTooltip:Show()
end

function armor.createIcon()
    button = icons.button("WizardBuffArmorButton")
    button:SetScript("OnEnter", tooltip)
    armor.button = button
end

function armor.paint()
    local found = armor.found
    local spell = armor.choice()
    if armor.needed() then
        icons.paint(button, spell, not ns.cantCast, ns.cantCast, nil, found.left)
    else
        icons.paint(button, spell, false, found.up == nil or ns.cantCast, nil, found.left)
    end
end

-- Out of combat only.
function armor.bind()
    local spell, other = armor.choice()
    icons.set(button, "type1", "spell")
    icons.set(button, "spell1", spell)
    icons.set(button, "unit1", "player")
    icons.set(button, "type2", "spell")
    icons.set(button, "spell2", other)
    icons.set(button, "unit2", "player")
end
