local _, ns = ...

local issecret, yes = ns.isSecret, ns.yes

-- Can the spell reach this unit? Falls back to "within 40 yards", then to
-- "visible at all" when the game won't say.
function ns.inRange(unit, spell)
    local reach = spell and C_Spell.IsSpellInRange(spell, unit)
    if not issecret(reach) and reach ~= nil then return reach end
    local near, checked = UnitInRange(unit)
    if not issecret(near) and yes(checked) then return near and true or false end
    local visible = UnitIsVisible(unit)
    return issecret(visible) or (visible and true or false)
end
