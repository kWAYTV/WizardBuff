local _, ns = ...

-- One pass: look, decide, point the buttons, draw. Buttons can only be
-- re-pointed, shown or hidden out of combat; in combat they keep what they
-- had and only the drawing updates.

local yes = ns.yes

local function arrange()
    local onlyNeeded = ns.db.onlyNeeded
    ns.icons.arrange({
        [ns.intellect.button] = ns.intellect.rank() ~= nil and (not onlyNeeded or ns.intellect.needed()),
        [ns.armor.button] = ns.armor.choice() ~= nil and (not onlyNeeded or ns.armor.needed()),
    })
end

function ns.refresh()
    ns.cantCast = yes(UnitIsDeadOrGhost("player")) or yes(UnitOnTaxi("player"))
    if ns.intellect.scan() then ns.intellect.plan() end
    ns.armor.scan()

    if not InCombatLockdown() then
        ns.icons.fit()
        ns.intellect.bind()
        ns.armor.bind()
        ns.bindKeybind()
        arrange()
    end

    ns.intellect.paint()
    ns.armor.paint()
end
