local addonName, ns = ...

local function isGroupUnit(unit)
    if type(unit) ~= "string" or ns.IsSecret(unit) then return false end
    return unit == "player" or unit == "pet" or unit:find("^party") ~= nil or unit:find("^raid") ~= nil
end

local function start()
    local _, class = UnitClass("player")
    ns.isMage = class == "MAGE"
    if not ns.isMage then
        ns.Print("Wizard Buff is for mages; it stays idle on this character.")
        return
    end

    ns.RefreshKnownSpells()
    ns.CreateHUD()
    ns.CreateMinimapButton()
    ns.CreateSettings()
    ns.InitSync()

    local request = function() ns.RequestUpdate() end
    ns.On("PLAYER_ENTERING_WORLD", function() ns.Update(true) end)
    ns.On("GROUP_ROSTER_UPDATE", request)
    ns.On("UNIT_PET", request)
    ns.On("UNIT_CONNECTION", request)
    ns.On("UNIT_LEVEL", request)
    ns.On("UNIT_FLAGS", function(unit) if isGroupUnit(unit) then request() end end)
    ns.On("UNIT_AURA", function(unit) if isGroupUnit(unit) then request() end end)
    ns.On("BAG_UPDATE_DELAYED", request)
    ns.On("ZONE_CHANGED_NEW_AREA", request)
    ns.On("SPELLS_CHANGED", function()
        ns.RefreshKnownSpells()
        ns.RequestUpdate()
    end)
    ns.On("PLAYER_REGEN_ENABLED", ns.OnCombatEnd)
    ns.On("PLAYER_REGEN_DISABLED", function()
        ns.UpdateMover()
        ns.PaintBar()
    end)
    ns.On("SPELL_UPDATE_COOLDOWN", function() ns.PaintBar() end)
    ns.On("READY_CHECK", ns.OnReadyCheck)
    ns.On("UI_ERROR_MESSAGE", ns.OnUIError)
    ns.OnUnit("UNIT_HEALTH", "player", function() ns.PaintBar() end)
    ns.OnUnit("UNIT_SPELLCAST_SUCCEEDED", "player", ns.OnSpellcastSucceeded)

    ns.Listen("SETTINGS_CHANGED", function()
        ns.UpdateMover()
        ns.UpdateMinimapButton()
        ns.Update(true)
    end)
    ns.Listen("ASSIGN_CHANGED", function()
        if InCombatLockdown() then
            ns.RecomputeOwners()
            ns.PaintGrid()
        else
            ns.Update(false)
        end
    end)

    ns.StartTicker()
    ns.Update(true)
end

ns.On("ADDON_LOADED", function(name)
    if name == addonName then ns.LoadDB() end
end)

ns.On("PLAYER_LOGIN", start)
