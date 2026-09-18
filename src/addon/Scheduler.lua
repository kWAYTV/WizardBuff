local _, ns = ...

local _scheduleTimer

function ns.ScheduleUpdate(immediate)
    if InCombatLockdown() then
        ns._pendingUpdate = true
        return
    end
    if _scheduleTimer then
        if not immediate then return end
        if _scheduleTimer.Cancel then _scheduleTimer:Cancel() end
        _scheduleTimer = nil
    end
    _scheduleTimer = C_Timer.After(immediate and 0.01 or 0.3, function()
        _scheduleTimer = nil
        ns._pendingUpdate = false
        local ok, err = pcall(ns.RefreshHUD)
        if not ok then
            ns.PrintError(err)
            if ns.mainFrame then ns.mainFrame:Show() end
        end
    end)
end
