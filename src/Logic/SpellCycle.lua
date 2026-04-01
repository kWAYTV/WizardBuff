local _, ns = ...

local SpellIDs   = ns.SpellIDs
local SpellNames = ns.SpellNames

---------------------------------------------------------------------------
-- Generic: is any rank of a spell key known?
---------------------------------------------------------------------------
local function isAnyRankKnown(key)
    local ids = SpellIDs[key]
    if not ids then return false end
    for i = #ids, 1, -1 do
        if IsSpellKnown(ids[i]) then return true end
    end
    return false
end

---------------------------------------------------------------------------
-- Cycle list definitions (key + label + optional spell key to check)
-- "auto" is always first and always present.
---------------------------------------------------------------------------
local SELF_DEFS = {
    { key = "auto",      label = "Auto" },
    { key = "FrostArmor", label = SpellNames.FrostArmor,  spellKey = "FrostArmor" },
    { key = "IceArmor",   label = SpellNames.IceArmor,    spellKey = "IceArmor" },
    { key = "MageArmor",  label = SpellNames.MageArmor,   spellKey = "MageArmor" },
    { key = "SelfInt",    label = SpellNames.ArcaneIntellect and ("Self " .. SpellNames.ArcaneIntellect),
                          spellKey = "ArcaneIntellect" },
}

local GROUP_DEFS = {
    { key = "auto",  label = "Auto" },
    { key = "int",   label = "Intellect",  spellKey = "ArcaneIntellect" },
    { key = "brill", label = "Brilliance", spellKey = "ArcaneBrilliance" },
}

local SHIELD_DEFS = {
    { key = "auto",       label = "Auto" },
    { key = "IceBarrier", label = SpellNames.IceBarrier,  spellKey = "IceBarrier" },
    { key = "ManaShield", label = SpellNames.ManaShield,  spellKey = "ManaShield" },
}

---------------------------------------------------------------------------
-- Build a filtered list from a definition table (lazy, cached per table)
---------------------------------------------------------------------------
local caches = {}

local function buildList(defs)
    if caches[defs] then return caches[defs] end
    local out = {}
    for _, d in ipairs(defs) do
        if not d.spellKey or isAnyRankKnown(d.spellKey) then
            out[#out + 1] = d
        end
    end
    caches[defs] = out
    return out
end

function ns.BuildSelfSpellList()   return buildList(SELF_DEFS) end
function ns.BuildGroupModeList()   return buildList(GROUP_DEFS) end
function ns.BuildShieldSpellList() return buildList(SHIELD_DEFS) end

---------------------------------------------------------------------------
-- Resolve a mode index → key from a built list
---------------------------------------------------------------------------
local function getModeKey(modeVar, builder)
    local list = builder()
    local idx  = (ns[modeVar] or 0) + 1
    if idx < 1 or idx > #list then return "auto" end
    return list[idx].key
end

function ns.GetSelfModeKey()   return getModeKey("_selfMode",   ns.BuildSelfSpellList) end
function ns.GetGroupModeKey()  return getModeKey("_groupMode",  ns.BuildGroupModeList) end
function ns.GetShieldModeKey() return getModeKey("_shieldMode", ns.BuildShieldSpellList) end

---------------------------------------------------------------------------
-- Cycle a mode index (called from OnMouseWheel handlers)
---------------------------------------------------------------------------
function ns.CycleMode(modeVar, builder, delta)
    if InCombatLockdown() then return end
    local list = builder()
    if #list <= 1 then return end
    local cur = ns[modeVar] or 0
    cur = cur + (delta > 0 and 1 or -1)
    if cur >= #list then cur = 0 end
    if cur < 0 then cur = #list - 1 end
    ns[modeVar] = cur
    ns.Print(list[cur + 1].label)
    ns.ScheduleUpdate(true)
end

---------------------------------------------------------------------------
-- Convenience
---------------------------------------------------------------------------
function ns.AnyShieldKnown()
    return #ns.BuildShieldSpellList() > 1
end
