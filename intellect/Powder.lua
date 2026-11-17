local _, ns = ...

-- Arcane Powder, the reagent for Arcane Brilliance.

local intellect = ns.intellect
local POWDER, LOW = 17020, 5

-- How many you carry, or nil if Brilliance isn't learned yet.
function intellect.powder()
    if not ns.spellbook.knows(intellect.brilliance) then return nil end
    local count = (C_Item and C_Item.GetItemCount or GetItemCount)(POWDER)
    return ns.plain(count) or 0
end

function intellect.powderLow()
    local count = intellect.powder()
    return count ~= nil and count <= LOW
end
