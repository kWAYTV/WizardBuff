local _, ns = ...
ns = ns or _G.WizardBuffAddon
assert(ns, "WizardBuff: load WizardBuff.lua before Events.lua")

local timer

function ns.ScheduleUpdate()
    if timer then
        return
    end
    if InCombatLockdown() then
        ns._pendingUpdate = true
        return
    end
    timer = C_Timer.After(0.3, function()
        timer = nil
        ns._pendingUpdate = false
        ns.UpdateButtons()
    end)
end
