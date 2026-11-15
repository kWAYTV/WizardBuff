local _, ns = ...

local intellect = ns.intellect

-- What a left-click does.
intellect.cast = {
    spell = nil,
    unit = "player",
    target = nil,   -- the member it is for
    topUp = false,  -- nobody needs it; this refreshes whoever runs out first
}

function intellect.plan()
    local found, cast = intellect.found, intellect.cast
    local target = found.missing[1] or found.soonestOn
    cast.target = target
    cast.topUp = found.missing[1] == nil
    cast.spell, cast.unit = nil, "player"
    if not target then return end

    -- Brilliance hits the raid, so it pays off once enough people it can
    -- land on are missing Intellect. Cast on yourself.
    local takers = 0
    for _, rec in ipairs(found.missing) do
        if rec.level >= intellect.brillianceLevel then takers = takers + 1 end
    end
    if ns.db.brilliance and takers >= ns.db.brillianceMin and ns.spellbook.ready(intellect.brilliance) then
        cast.spell = intellect.brilliance
    else
        cast.spell, cast.unit = intellect.rank(target.level), target.unit
    end
end
