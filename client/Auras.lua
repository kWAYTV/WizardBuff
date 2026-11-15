local _, ns = ...

-- Buffs are looked up by spell name. Walking a unit's buff list by index is
-- refused for addons in places; a by-name lookup is not.
--
-- While auras are restricted (combat, encounters), a lookup for a buff the
-- game treats as secret returns nothing, same as a missing buff. So a family
-- is only read when the game says it is readable. Otherwise: nil, "can't
-- tell".
--
-- A family is { ids = every spell giving the buff, nameIDs = spells whose
-- names cover them all }.

local issecret, plain = ns.isSecret, ns.plain
local auras = {}
ns.auras = auras

function auras.restricted()
    local f = C_Secrets and C_Secrets.ShouldAurasBeSecret
    if not f then return InCombatLockdown() end
    local v = f()
    return issecret(v) or (v and true or false)
end

function auras.readable(family)
    if not auras.restricted() then return true end
    local f = C_Secrets and C_Secrets.ShouldSpellAuraBeSecret
    if not f then return false end
    for _, id in ipairs(family.ids) do
        local ok, hidden = pcall(f, id)
        if not ok or issecret(hidden) or hidden ~= false then return false end
    end
    return true
end

function auras.names(family)
    if family.names then return family.names end
    local list = {}
    for _, id in ipairs(family.nameIDs) do
        local name = ns.spellbook.name(id)
        if not name then return list end  -- spell data not loaded yet
        list[#list + 1] = name
    end
    family.names = list
    return list
end

-- true (and seconds left, if timed), false, or nil when it can't be read.
function auras.has(unit, family)
    if not auras.readable(family) then return nil end
    local names = auras.names(family)
    if #names == 0 then return nil end
    for _, name in ipairs(names) do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataBySpellName, unit, name, "HELPFUL")
        if not ok or issecret(aura) then return nil end
        if aura then
            local expires = plain(aura.expirationTime)
            if expires and expires > 0 then return true, expires - GetTime() end
            return true
        end
    end
    return false
end
