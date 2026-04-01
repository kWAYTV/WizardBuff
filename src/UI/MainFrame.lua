local _, ns = ...

function ns.ApplyHudScale()
    local mf = ns.mainFrame
    if not mf then return end
    mf:SetScale((ns.db and ns.db.hudScale) or 1)
end

function ns.ApplyHudFade()
    local d  = ns.db
    local mf = ns.mainFrame
    if not mf or not d or not mf:IsShown() then return end
    local a = d.hudAlphaHover or 0.95
    if not ns._hudMouseOver then
        a = d.hudAlphaIdle or 0.42
        if d.hideHudInCombat and InCombatLockdown() then
            a = math.min(a, 0.07)
        end
    end
    mf:SetAlpha(a)
end

function ns.ScheduleHudLeaveCheck(mf)
    C_Timer.After(0.08, function()
        if mf and mf:IsMouseOver() then return end
        ns._hudMouseOver = false
        ns.ApplyHudFade()
    end)
end

function ns.CreateMainFrame()
    local mf = CreateFrame("Frame", "WizardBuffFrame", UIParent)
    ns.mainFrame = mf
    mf:SetSize(ns.UI_FRAME_W, ns.UI_BAR_H)

    local pos = ns.db and ns.db.hudPos
    if pos and pos.point and pos.relPoint and pos.x and pos.y then
        mf:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else
        mf:SetPoint("CENTER", 0, 200)
    end

    mf:SetMovable(true)
    mf:EnableMouse(true)
    mf:SetClampedToScreen(true)
    mf:SetFrameStrata("MEDIUM")
    mf:SetFrameLevel(8)

    mf:SetScript("OnEnter", function()
        ns._hudMouseOver = true
        ns.ApplyHudFade()
    end)
    mf:SetScript("OnLeave", function() ns.ScheduleHudLeaveCheck(mf) end)

    local timerElapsed = 0
    mf:SetScript("OnUpdate", function(_, dt)
        timerElapsed = timerElapsed + dt
        if timerElapsed < 1 then return end
        timerElapsed = 0
        if ns.autoBuffButton  then ns.RefreshTimerText(ns.autoBuffButton)  end
        if ns.brillianceButton then ns.RefreshTimerText(ns.brillianceButton) end
    end)

    ns.ApplyHudScale()
end
