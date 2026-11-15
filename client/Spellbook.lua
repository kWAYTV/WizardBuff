local _, ns = ...

local yes, plain = ns.yes, ns.plain
local spellbook = {}
ns.spellbook = spellbook

function spellbook.knows(id)
    if C_SpellBook and C_SpellBook.IsSpellKnown and yes(C_SpellBook.IsSpellKnown(id)) then return true end
    return IsPlayerSpell ~= nil and yes(IsPlayerSpell(id))
end

-- Highest known rank in a list (lowest first). With a target level and a
-- table of learn levels, the highest one that lands on that target: a rank
-- works down to ten levels below the level it is learned at.
function spellbook.best(ranks, level, learnedAt)
    for i = #ranks, 1, -1 do
        local id = ranks[i]
        local fits = not level or level <= 0 or level >= (learnedAt[id] or 1) - 10
        if fits and spellbook.knows(id) then return id end
    end
end

function spellbook.name(id)
    return id and plain(C_Spell.GetSpellName(id))
end

-- Castable apart from mana (so: known, reagent in bags).
function spellbook.ready(id)
    if not spellbook.knows(id) then return false end
    local usable, noMana = C_Spell.IsSpellUsable(id)
    return yes(usable) or yes(noMana)
end
