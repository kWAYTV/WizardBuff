local _, ns = ...

-- With EllesmereUI installed, the grid shows up in its Unlock mode and can
-- be moved there like the rest of that UI. Without it, nothing happens and
-- the handle is the way to move.

local grid = ns.grid

local function register()
    local eui = EllesmereUI
    if not (eui and eui.RegisterUnlockElements and eui.MakeUnlockElement) then return end
    eui:RegisterUnlockElements({
        eui.MakeUnlockElement({
            key = "WizardBuff_Grid",
            label = "Wizard Buff",
            group = "Wizard Buff",
            order = 900,
            noAnchorTarget = true,  -- its size follows the group
            noResize = true,
            getFrame = function() return grid.frame end,
            getSize = function() return grid.frame:GetSize() end,
            savePos = function(_, point, relPoint, x, y)
                ns.db.pos = { point = point, relPoint = relPoint, x = x, y = y }
                if not InCombatLockdown() then grid.place() end
            end,
            loadPos = function() return ns.db.pos end,
            clearPos = function() ns.db.pos = ns.defaultPosition() end,
            applyPos = function()
                if not InCombatLockdown() then grid.place() end
            end,
        }),
    })
end

function grid.joinUnlockMode()
    local ok, err = pcall(register)
    if not ok then ns.say("EllesmereUI unlock mode: " .. tostring(err)) end
end
