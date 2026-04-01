local _, ns = ...

local AUTO_LOCK_SEC = ns.AUTO_LOCK_SEC
local HANDLE_SIZE   = ns.HANDLE_SIZE

local autoLockTimer

---------------------------------------------------------------------------
-- Lock helpers (single source for slash, handle, LDB)
---------------------------------------------------------------------------
local function cancelAutoLock()
    if autoLockTimer then autoLockTimer:Cancel(); autoLockTimer = nil end
end

local function scheduleAutoLock()
    cancelAutoLock()
    autoLockTimer = C_Timer.NewTimer(AUTO_LOCK_SEC, function()
        autoLockTimer = nil
        if ns.db and not ns.db.locked then
            ns.db.locked = true
            ns.Print("Auto-locked after " .. AUTO_LOCK_SEC .. "s")
        end
    end)
end

ns.CancelAutoLock  = cancelAutoLock
ns.ScheduleAutoLock = scheduleAutoLock

function ns.ToggleLock()
    local db = ns.db
    if not db then return end
    db.locked = not db.locked
    if db.locked then
        cancelAutoLock()
        ns.Print("Locked")
    else
        scheduleAutoLock()
        ns.Print("Unlocked (auto-locks in " .. AUTO_LOCK_SEC .. "s)")
    end
end

---------------------------------------------------------------------------
-- Handle widget
---------------------------------------------------------------------------
function ns.CreateHandle()
    local mf = ns.mainFrame
    local h  = CreateFrame("Button", "WizardBuffHandle", mf)
    ns.handle = h

    h:SetSize(HANDLE_SIZE, HANDLE_SIZE)
    h:SetPoint("BOTTOMLEFT", mf, "TOPLEFT", 0, 0)
    h:SetFrameStrata("MEDIUM")
    h:SetFrameLevel(mf:GetFrameLevel() + 5)
    h:EnableMouse(true)
    h:RegisterForClicks("AnyUp")

    local hl = h:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    hl:SetBlendMode("ADD")

    local function showHandleTooltip(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Wizard Buff", 0.6, 0.8, 1)
        if ns.db and ns.db.locked then
            GameTooltip:AddLine("Shift+click \194\183 unlock to move", 0.55, 0.55, 0.55)
        else
            GameTooltip:AddLine("Alt+drag \194\183 move", 0.55, 0.55, 0.55)
            GameTooltip:AddLine("Shift+click \194\183 lock", 0.55, 0.55, 0.55)
        end
        GameTooltip:AddLine("Right-click \194\183 config", 0.55, 0.55, 0.55)
        GameTooltip:Show()
    end

    h:SetScript("OnEnter", function(self)
        ns._hudMouseOver = true
        ns.ApplyHudFade()
        showHandleTooltip(self)
    end)
    h:SetScript("OnLeave", function()
        GameTooltip:Hide()
        ns.ScheduleHudLeaveCheck(mf)
    end)

    h:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and IsAltKeyDown()
           and not InCombatLockdown()
           and not (ns.db and ns.db.locked) then
            h._isMoving = true
            cancelAutoLock()
            mf:StartMoving()
        end
    end)

    h:SetScript("OnMouseUp", function(_, button)
        if h._isMoving then
            mf:StopMovingOrSizing()
            h._isMoving = false
            if ns.db then
                local point, _, relPoint, x, y = mf:GetPoint(1)
                ns.db.hudPos = { point = point, relPoint = relPoint, x = x, y = y }
            end
            if ns.db and not ns.db.locked then scheduleAutoLock() end
            return
        end
        if IsShiftKeyDown() then
            ns.ToggleLock()
            showHandleTooltip(h)
        elseif button == "RightButton" then
            if ns.OpenConfig then ns.OpenConfig() end
        end
    end)

    h:SetScript("OnHide", function()
        if h._isMoving then
            mf:StopMovingOrSizing()
            h._isMoving = false
        end
    end)
end

function ns.UpdateHandleVisibility()
    if not ns.handle then return end
    if ns.db and ns.db.showDragHandle == false then
        ns.handle:Hide()
    else
        ns.handle:Show()
    end
end
