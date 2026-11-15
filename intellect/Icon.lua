local _, ns = ...

local intellect = ns.intellect
local icons = ns.icons
local button

local function names(list, limit)
    local out = {}
    for i = 1, math.min(#list, limit) do
        out[i] = type(list[i]) == "table" and list[i].name or list[i]
    end
    if #list > limit then out[#out + 1] = "+" .. (#list - limit) end
    return table.concat(out, ", ")
end

local function tooltip(self)
    local found, cast = intellect.found, intellect.cast
    local brilliance = ns.spellbook.name(intellect.brilliance) or "Arcane Brilliance"
    icons.tip(self, ns.spellbook.name(intellect.ranks[1]) or "Arcane Intellect")

    if #found.missing > 0 then
        icons.line("Missing: " .. names(found.missing, 10), icons.RED)
    elseif found.soonest then
        icons.line("All buffed, " .. icons.timeText(found.soonest) .. " left", icons.GREEN)
    else
        icons.line("All buffed", icons.GREEN)
    end
    if #found.far > 0 then icons.line("Out of range: " .. names(found.far, 6)) end
    if found.stale then icons.line("In combat, last known", icons.ORANGE) end

    local target = cast.target
    if target and cast.spell == intellect.brilliance then
        icons.line("Left-click: " .. brilliance)
    elseif target and cast.spell then
        icons.line("Left-click: " .. (cast.topUp and "refresh " or "") .. (target.isMe and "you" or target.name))
    end
    if ns.spellbook.knows(intellect.brilliance) then
        local ready = ns.spellbook.ready(intellect.brilliance)
        icons.line("Right-click: " .. brilliance .. (ready and "" or " (not ready)"))
    end
    icons.line("Alt-drag: move")
    GameTooltip:Show()
end

function intellect.createIcon()
    button = icons.button("WizardBuffIntButton")
    button:SetScript("OnEnter", tooltip)
    intellect.button = button
end

function intellect.paint()
    local found = intellect.found
    local idle = found.stale or ns.cantCast
    if #found.missing > 0 then
        icons.paint(button, intellect.cast.spell or intellect.rank(), not idle, idle, #found.missing)
    else
        icons.paint(button, intellect.rank(), false, idle, nil, found.soonest)
    end
end

-- Out of combat only.
function intellect.bind()
    local cast = intellect.cast
    local brilliance = ns.spellbook.knows(intellect.brilliance) and intellect.brilliance or nil
    icons.set(button, "type1", "spell")
    icons.set(button, "spell1", cast.spell)
    icons.set(button, "unit1", cast.unit)
    icons.set(button, "type2", "spell")
    icons.set(button, "spell2", brilliance)
    icons.set(button, "unit2", "player")
end
