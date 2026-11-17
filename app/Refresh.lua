local _, ns = ...

-- One pass: look, decide, point the cells, draw. Cells can only be
-- re-pointed, moved, shown or hidden out of combat; in combat they keep what
-- they had and only the colours update.

local yes = ns.yes

local function visible()
    local db = ns.db
    if not db.shown then return false end
    if db.hideResting and IsResting() then return false end
    if db.onlyNeeded and not (ns.intellect.needed() or ns.armor.needed()) then return false end
    return true
end

function ns.refresh()
    ns.cantCast = yes(UnitIsDeadOrGhost("player")) or yes(UnitOnTaxi("player"))
    if ns.intellect.scan() then ns.intellect.plan() end
    ns.armor.scan()

    if not InCombatLockdown() then
        local rows = ns.intellect.bindCells()
        local first = ns.armor.bind()
        ns.bindKeybind()
        ns.grid.fit()
        ns.grid.layout(first, rows, visible())
    end

    ns.intellect.paintCells()
    ns.armor.paint()
    ns.grid.summary(#ns.intellect.found.missing)
end
