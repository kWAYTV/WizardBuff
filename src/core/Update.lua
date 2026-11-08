local _, ns = ...

-- Refresh pipeline.
--   Out of combat: rescan roster and auras, rebuild the plan, rebind the
--   secure buttons and, when the shape changed, lay out the HUD. This also
--   runs every second, so a buff that lands is seen even if UNIT_AURA
--   doesn't reach us.
--   In combat: secure frames are frozen; repaint from the last known state
--   and do a full pass when combat ends.

local pending, pendingLayout = false, false
local timer
local lastShape

local function shape()
    local parts = { tostring(ns.ShouldShow()), ns.BarShape(), tostring(IsInRaid()), tostring(ns.owners ~= nil) }
    for _, rec in ipairs(ns.members) do
        parts[#parts + 1] = rec.unit .. rec.guid .. rec.group .. (rec.level or 0)
    end
    return table.concat(parts, "|")
end

local function paint()
    ns.PaintBar()
    ns.PaintGrid()
    ns.RefreshStatus()
end

local function lightRefresh()
    ns.BuildPlan()
    paint()
end

local hadNeed, lastSound = false, 0

local function alerts(plan)
    local has = plan.next ~= nil and not plan.next.outOfRange
    if has and not hadNeed and ns.db.sound and GetTime() - lastSound > 20 then
        lastSound = GetTime()
        PlaySound(SOUNDKIT and SOUNDKIT.ALARM_CLOCK_WARNING_3 or 12889, "Master")
    end
    hadNeed = has
end

function ns.Update(force)
    if not ns.isMage or not ns.frame then return end
    if InCombatLockdown() then
        pending = true
        pendingLayout = pendingLayout or force or false
        lightRefresh()
        return
    end
    pending = false

    ns.ScanRoster()
    ns.RecomputeOwners()
    local plan = ns.BuildPlan()
    ns.ApplyBar(plan)

    local s = shape()
    if force or pendingLayout or s ~= lastShape then
        lastShape = s
        pendingLayout = false
        ns.LayoutHUD()
    else
        ns.PaintGrid()
        ns.RefreshStatus()
    end
    ns.Fire("ROSTER_SCANNED")
    alerts(plan)
end

function ns.RequestUpdate(delay)
    if timer then return end
    timer = C_Timer.NewTimer(delay or 0.25, function()
        timer = nil
        ns.Update(false)
    end)
end

function ns.OnCombatEnd()
    ns.Update(pendingLayout)
end

function ns.StartTicker()
    C_Timer.NewTicker(1, function()
        if not ns.frame then return end
        if InCombatLockdown() then
            if ns.frame:IsShown() then lightRefresh() end
        else
            ns.Update(false)
        end
    end)
end

function ns.ToggleEnabled()
    ns.db.enabled = not ns.db.enabled
    ns.Print(ns.db.enabled and "Shown." or "Hidden. Type /wbuff to show it again.")
    if InCombatLockdown() then ns.Print("It will update when combat ends.") end
    ns.Update(true)
end

---------------------------------------------------------------------------
-- Cast tracking: update right after our own casts, even in combat.
---------------------------------------------------------------------------

local SPELL_KEY = {}
for key, ids in pairs(ns.SPELLS) do
    for _, id in ipairs(ids) do SPELL_KEY[id] = key end
end

local ARMOR = { FROST_ARMOR = true, ICE_ARMOR = true, MAGE_ARMOR = true }

function ns.OnSpellcastSucceeded(_, _, spellID)
    if ns.IsSecret(spellID) then return end
    local key = SPELL_KEY[spellID]
    if not key then
        for k in pairs(ns.SPELLS) do
            for _, id in ipairs(ns.KnownIDs(k)) do
                if id == spellID then key = k end
            end
        end
    end
    if key == "BRILLIANCE" then
        ns.PredictIntellectAll()
    elseif key == "INTELLECT" then
        local guid, unit = ns.LastCastClick()
        guid = guid or (unit and ns.SafeCall(UnitGUID, unit))
        if guid then ns.PredictIntellect(guid) end
    elseif key and ARMOR[key] then
        ns.PredictArmor(key)
    else
        return
    end
    if InCombatLockdown() then lightRefresh() else ns.RequestUpdate(0.3) end
end

function ns.OnUIError(_, message)
    if ns.IsSecret(message) or type(message) ~= "string" then return end
    if not ns.ClickedWithin(0.5) then return end
    ns.Feedback(message, ns.COLORS.bad)
end

function ns.OnReadyCheck()
    if not ns.db.readyCheck then return end
    local names = {}
    for _, rec in ipairs(ns.members) do
        if rec.needs and rec.mine and not rec.isPet then names[#names + 1] = rec.name end
    end
    if #names == 0 then return end
    ns.Print(#names .. " still need Intellect: " .. table.concat(names, ", "))
    ns.Feedback(#names .. " need Intellect", ns.COLORS.bad)
    if ns.db.sound then PlaySound(SOUNDKIT and SOUNDKIT.READY_CHECK or 8960, "Master") end
end
