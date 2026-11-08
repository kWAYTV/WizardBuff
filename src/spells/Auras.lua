local _, ns = ...

-- Forever lets addons read auras out of combat only. In combat every reader
-- answers "unknown" and callers keep the last reading.
--
-- Each unit's buff list is walked by index (the method other Forever addons
-- use), and a buff matches by spell ID, then name, then icon, so a renamed
-- or renumbered rank is still found. The by-name lookup is a second check.

local MAX_AURAS = 40
local GetByIndex = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
local GetByName = C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName

local matchers = {}

local function matcher(key)
    local m = matchers[key]
    if m then return m end
    m = { ids = {}, icons = {} }
    for _, id in ipairs(ns.SPELLS[key] or {}) do
        m.ids[id] = true
        local icon = C_Spell.GetSpellTexture(id)
        if icon then m.icons[icon] = true end
    end
    for _, id in ipairs(ns.KnownIDs(key)) do m.ids[id] = true end
    m.name = ns.SpellName(key)
    if m.name then matchers[key] = m end
    return m
end

function ns.ResetAuraMatchers()
    wipe(matchers)
end

-- One pass over a unit's buffs. Returns a list, or nil and a reason.
local function scan(unit)
    if not GetByIndex then return nil, "no index API" end
    local list = {}
    for i = 1, MAX_AURAS do
        local ok, aura = pcall(GetByIndex, unit, i, "HELPFUL")
        if not ok then return nil, "error" end
        if ns.IsSecret(aura) then return nil, "secret" end
        if type(aura) ~= "table" then break end
        local id, name, icon = aura.spellId, aura.name, aura.icon
        local exp, dur = aura.expirationTime, aura.duration
        list[#list + 1] = {
            id = not ns.IsSecret(id) and id or nil,
            name = not ns.IsSecret(name) and name or nil,
            icon = not ns.IsSecret(icon) and icon or nil,
            exp = (not ns.IsSecret(exp) and exp) or 0,
            dur = (not ns.IsSecret(dur) and dur) or 0,
        }
    end
    return list
end

local function findIn(list, m)
    for _, a in ipairs(list) do
        if a.id and m.ids[a.id] then return a end
    end
    for _, a in ipairs(list) do
        if a.name and m.name and a.name == m.name then return a end
    end
    for _, a in ipairs(list) do
        if a.icon and m.icons[a.icon] then return a end
    end
end

local function byName(unit, name)
    if not GetByName or not name then return nil end
    local ok, aura = pcall(GetByName, unit, name, "HELPFUL")
    if not ok or aura == nil then return nil end
    if ns.IsSecret(aura) or type(aura) ~= "table" then return { exp = 0, dur = 0 } end
    local exp, dur = aura.expirationTime, aura.duration
    return { exp = (not ns.IsSecret(exp) and exp) or 0, dur = (not ns.IsSecret(dur) and dur) or 0 }
end

-- Looks for any of the given spell keys on a unit.
-- Returns "yes", key, expires, duration | "no" | "unknown".
local function read(unit, keys, list)
    if InCombatLockdown() then return "unknown" end
    local scanned = list ~= nil
    if not scanned then
        list = scan(unit)
        scanned = list ~= nil
    end
    for _, key in ipairs(keys) do
        local m = matcher(key)
        local a = (list and findIn(list, m)) or byName(unit, m.name)
        if a then return "yes", key, a.exp, a.dur end
    end
    if scanned or GetByName then return "no" end
    return "unknown"
end

-- Seconds left on an expiration time, or nil for permanent / unknown.
function ns.Remaining(expires)
    if not expires or expires <= 0 then return nil end
    return math.max(0, expires - GetTime())
end

local INT_KEYS = { "BRILLIANCE", "INTELLECT" }
local ARMOR_KEYS = { "MAGE_ARMOR", "ICE_ARMOR", "FROST_ARMOR" }
local SHIELD_KEYS = { "ICE_BARRIER", "MANA_SHIELD" }

-- Arcane Intellect or Arcane Brilliance from anyone.
-- Returns state ("yes" | "no" | "unknown"), expires, duration.
function ns.ReadIntellect(unit)
    local state, _, exp, dur = read(unit, INT_KEYS)
    return state, exp, dur
end

-- Returns the active armor key (or nil), expires, duration;
-- "unknown" while auras can't be read.
function ns.ReadArmor()
    local state, key, exp, dur = read("player", ARMOR_KEYS)
    if state == "unknown" then return "unknown" end
    if state == "yes" then return key, exp, dur end
    return nil
end

function ns.ReadShield()
    local state, key, exp, dur = read("player", SHIELD_KEYS)
    if state == "unknown" then return "unknown" end
    if state == "yes" then return key, exp, dur end
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

---------------------------------------------------------------------------
-- /wbuff debug: what the client tells us, so problems can be reported.
---------------------------------------------------------------------------

local function show(v)
    if v == nil then return "nil" end
    if ns.IsSecret(v) then return "<secret>" end
    return tostring(v)
end

function ns.DebugAuras(unit)
    if not UnitExists(unit) then return end
    local who = ns.SafeCall(UnitName, unit) or unit
    print(string.format("  %s (%s):", unit, show(who)))
    if InCombatLockdown() then print("    in combat: auras unreadable"); return end
    local list, why = scan(unit)
    if not list then
        print("    buff list: " .. why)
    elseif #list == 0 then
        print("    buff list: empty")
    else
        for _, a in ipairs(list) do
            local left = ns.Remaining(a.exp)
            print(string.format("    %s  id=%s icon=%s left=%s", show(a.name), show(a.id), show(a.icon),
                left and ns.FormatTime(left) or "-"))
        end
    end
    local name = ns.SpellName("INTELLECT")
    local ok, aura = pcall(GetByName or error, unit, name, "HELPFUL")
    print(string.format("    by name '%s': %s", show(name), ok and (aura and "found" or "nil") or "error"))
    local s, e = ns.ReadIntellect(unit)
    local left = ns.Remaining(e)
    print("    => Intellect " .. s .. (left and (" " .. ns.FormatTime(left)) or ""))
end
