local _, ns = ...

local yes, plain = ns.yes, ns.plain
local spellbook = {}
ns.spellbook = spellbook

-- The old globals (IsSpellKnown, IsPlayerSpell) only exist while a
-- compatibility setting is on, so they are a last resort.
function spellbook.knows(id)
    local book = C_SpellBook
    if book and book.IsSpellKnown and yes(book.IsSpellKnown(id)) then return true end
    if book and book.IsSpellInSpellBook and Enum and Enum.SpellBookSpellBank
        and yes(book.IsSpellInSpellBook(id, Enum.SpellBookSpellBank.Player, false)) then
        return true
    end
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
