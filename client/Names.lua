local _, ns = ...

-- Forever characters have a surname; UnitName returns it second (where
-- retail returns the realm). Returns the first name and "First Last".

local plain = ns.plain
local SEPARATOR = Constants and Constants.CharacterNameSeparatorConsts
    and Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR or " "

function ns.names(unit)
    local first, last = UnitName(unit)
    first, last = plain(first), plain(last)
    if type(first) ~= "string" then return unit, unit end
    if type(last) ~= "string" or last == "" then return first, first end
    local tail = SEPARATOR .. last
    -- Some units already carry the surname in the first value.
    if first:sub(-#tail) == tail then return first, first end
    return first, first .. tail
end
