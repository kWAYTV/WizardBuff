local _, ns = ...

-- Forever only lets addons read auras out of combat. In combat these
-- lookups return nil, which would look like "missing", so every reader
-- answers "unknown" while in combat and callers keep the last reading.

local GetBySpellName = C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName

local function read(unit, name)
    if not name or not GetBySpellName or InCombatLockdown() then return "unknown" end
    local ok, aura = pcall(GetBySpellName, unit, name, "HELPFUL")
    if not ok then return "unknown" end
    if aura == nil then return "no" end
    local exp, dur = aura.expirationTime, aura.duration
    if ns.IsSecret(exp) or ns.IsSecret(dur) then return "yes", 0, 0 end
    return "yes", exp or 0, dur or 0
end

-- Seconds left on an expiration time, or nil for permanent / unknown.
function ns.Remaining(expires)
    if not expires or expires <= 0 then return nil end
    return math.max(0, expires - GetTime())
end

local function later(e1, e2)
    if e1 == 0 then return true end
    if e2 == 0 then return false end
    return e1 >= e2
end

-- Arcane Intellect or Arcane Brilliance from anyone.
-- Returns state ("yes" | "no" | "unknown"), expires, duration.
function ns.ReadIntellect(unit)
    local s1, e1, d1 = read(unit, ns.SpellName("BRILLIANCE"))
    local s2, e2, d2 = read(unit, ns.SpellName("INTELLECT"))
    if s1 == "yes" and s2 == "yes" then
        if later(e1, e2) then return "yes", e1, d1 end
        return "yes", e2, d2
    end
    if s1 == "yes" then return "yes", e1, d1 end
    if s2 == "yes" then return "yes", e2, d2 end
    if s1 == "unknown" or s2 == "unknown" then return "unknown" end
    return "no"
end

local ARMORS = { "MAGE_ARMOR", "ICE_ARMOR", "FROST_ARMOR" }

-- Returns the active armor key (or nil), its expiration and duration.
-- Returns "unknown" as the first value while auras can't be read.
function ns.ReadArmor()
    for _, key in ipairs(ARMORS) do
        local state, exp, dur = read("player", ns.SpellName(key))
        if state == "unknown" then return "unknown" end
        if state == "yes" then return key, exp, dur end
    end
    return nil
end

function ns.ReadShield()
    for _, key in ipairs({ "ICE_BARRIER", "MANA_SHIELD" }) do
        local state, exp, dur = read("player", ns.SpellName(key))
        if state == "unknown" then return "unknown" end
        if state == "yes" then return key, exp, dur end
    end
    return nil
end

-- Player health in percent (0-100), readable in combat on Forever.
function ns.PlayerHealthPercent()
    if UnitHealthPercent then
        local curve = CurveConstants and CurveConstants.ScaleTo100
        local pct = ns.SafeCall(UnitHealthPercent, "player", false, curve)
        if pct then
            if not curve and pct <= 1 then pct = pct * 100 end
            return pct
        end
    end
    local cur, max = ns.SafeCall(function()
        return UnitHealth("player"), UnitHealthMax("player")
    end)
    if cur and max and max > 0 then return cur / max * 100 end
    return nil
end
