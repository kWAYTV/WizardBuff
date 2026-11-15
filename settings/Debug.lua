local _, ns = ...

-- /wb debug: what the game answers. Paste it into bug reports.

local function show(v)
    if ns.isSecret(v) then return "<secret>" end
    return tostring(v)
end

local function family(label, fam)
    local known = {}
    for _, id in ipairs(fam.ids) do
        if ns.spellbook.knows(id) then known[#known + 1] = id end
    end
    print(string.format("  %s: names [%s], known [%s], readable %s", label,
        table.concat(ns.auras.names(fam), ", "), table.concat(known, ", "), show(ns.auras.readable(fam))))
end

function ns.debug()
    local intellect, armor, timeText = ns.intellect, ns.armor, ns.icons.timeText
    ns.say("debug")
    print("  in combat:", show(InCombatLockdown()), " auras restricted:", show(ns.auras.restricted()))
    family("Intellect", intellect.family)
    for i, fam in ipairs(armor.lines) do family("Armor " .. i, fam) end

    for _, rec in ipairs(intellect.units()) do
        local unit = rec.unit
        local _, class = UnitClass(unit)
        local has, left = ns.auras.has(unit, intellect.family)
        local byIndex = pcall(C_UnitAuras.GetAuraDataByIndex, unit, 1, "HELPFUL")
        print(string.format("  %s %s (%s, group %d): Intellect %s %s, in range %s, list readable %s",
            unit, show(UnitName(unit)), show(class), rec.group, show(has), timeText(left),
            show(ns.inRange(unit, intellect.rank())), show(byIndex)))
    end

    print("  armor:", show(armor.found.up), timeText(armor.found.left), " remembered:", show(ns.db.armor))
    print("  left-click casts", show(intellect.button:GetAttribute("spell1")), "on",
        show(intellect.button:GetAttribute("unit1")))
end
