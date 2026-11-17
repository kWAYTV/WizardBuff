local _, ns = ...

local intellect = ns.intellect

-- What the "Buff next" key casts.
intellect.cast = { spell = nil, unit = "player" }

function intellect.plan()
    local found, cast = intellect.found, intellect.cast
    local target = found.missing[1]
    cast.spell, cast.unit = nil, "player"
    if not target or intellect.testing() then return end

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
