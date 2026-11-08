local _, ns = ...

-- Refresh pipeline.
--   Out of combat: rescan roster and auras, rebuild the plan, rebind
--   secure buttons and, when the roster shape changed, lay out the HUD.
--   In combat: secure frames are frozen, so only repaint from the last
--   known state and remember to do a full pass when combat ends.

local pending, pendingLayout = false, false
local timer
local lastShape

local function shape()
    local parts = { tostring(ns.ShouldShow()), tostring(ns.shieldButton and ns.shieldButton:IsShown()) }
    for _, rec in ipairs(ns.members) do
        parts[#parts + 1] = rec.unit .. rec.guid .. rec.group .. (rec.level or 0)
    end
    return table.concat(parts, "|")
end

local function lightRefresh()
    ns.BuildPlan()
    ns.PaintGrid()
    ns.RefreshStatus()
    ns.RefreshShieldGlow()
end

local hadBuff, lastSound = false, 0

local function alerts(plan)
    local has = plan.buff ~= nil and not plan.buff.outOfRange
    if has and not hadBuff and ns.db.sound and GetTime() - lastSound > 20 then
        lastSound = GetTime()
        PlaySound(SOUNDKIT and SOUNDKIT.ALARM_CLOCK_WARNING_3 or 12889, "Master")
    end
    hadBuff = has
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
    ns.ApplyButtons(plan)

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

-- Once a second: timers and, out of combat, range.
function ns.StartTicker()
    C_Timer.NewTicker(1, function()
        if not ns.frame or not ns.frame:IsShown() then return end
        if not InCombatLockdown() then
            ns.UpdateRange()
            ns.ApplyButtons(ns.BuildPlan())
            ns.RefreshStatus()
        end
        ns.PaintGrid()
        if ns.buffButton then ns.RefreshButtonTimer(ns.buffButton) end
    end)
end

function ns.ToggleEnabled()
    ns.db.enabled = not ns.db.enabled
    ns.Print(ns.db.enabled and "HUD shown." or "HUD hidden. Type /wbuff to show it again.")
    if InCombatLockdown() then ns.Print("It will update when combat ends.") end
    ns.Update(true)
end

---------------------------------------------------------------------------
-- Cast tracking: lets the grid update right after a cast, even in combat.
---------------------------------------------------------------------------

local INT_IDS, BRILL_IDS = {}, {}
for _, id in ipairs(ns.SPELLS.INTELLECT) do INT_IDS[id] = true end
for _, id in ipairs(ns.SPELLS.BRILLIANCE) do BRILL_IDS[id] = true end

function ns.OnSpellcastSucceeded(_, _, spellID)
    if ns.IsSecret(spellID) then return end
    if BRILL_IDS[spellID] or spellID == ns.Best("BRILLIANCE") then
        ns.PredictIntellectAll()
    elseif INT_IDS[spellID] then
        local guid, unit = ns.LastCastClick()
        guid = guid or (unit and ns.SafeCall(UnitGUID, unit))
        if guid then ns.PredictIntellect(guid) end
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
