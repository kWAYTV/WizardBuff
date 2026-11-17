local _, ns = ...

-- Startup, and when to look again: shortly after anything changes, and once
-- a second regardless (range and timers move without events).

local EVENTS = {
    "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE", "UNIT_AURA", "UNIT_CONNECTION",
    "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "SPELLS_CHANGED", "BAG_UPDATE_DELAYED",
    "PLAYER_UPDATE_RESTING", "READY_CHECK", "ENCOUNTER_START", "ENCOUNTER_END",
}

local driver = CreateFrame("Frame")
local dirty, waited = true, 0

function ns.lookAgain()
    dirty = true
end

local function inGroup(unit)
    return unit == "player" or (unit ~= nil and (unit:find("^party%d") or unit:find("^raid%d")) ~= nil)
end

local function start()
    ns.grid.createFrame()
    ns.grid.createHandle()
    ns.armor.createCell()
    ns.createKeybind()
    ns.grid.place()
    ns.buildSettings()
    -- A moment later: EllesmereUI sets its unlock mode up after loading.
    C_Timer.After(1, ns.grid.joinUnlockMode)
    for _, event in ipairs(EVENTS) do driver:RegisterEvent(event) end
    driver:SetScript("OnUpdate", function(_, elapsed)
        waited = waited + elapsed
        if waited >= 1 or (dirty and waited >= 0.2) then
            waited, dirty = 0, false
            ns.refresh()
        end
    end)
end

driver:SetScript("OnEvent", function(_, event, arg)
    if event == "ADDON_LOADED" then
        if arg ~= ns.name then return end
        ns.loadSaved()
        if ns.isMage then start() end
    elseif event == "UNIT_AURA" then
        -- Fires for everything in sight; only the group matters.
        if inGroup(ns.plain(arg)) then dirty = true end
    elseif event == "READY_CHECK" then
        ns.intellect.onReadyCheck()
    else
        dirty = true
    end
end)
driver:RegisterEvent("ADDON_LOADED")
