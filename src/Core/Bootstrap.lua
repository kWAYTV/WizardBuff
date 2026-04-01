local _, ns = ...

local AceAddon = LibStub("AceAddon-3.0")
local AceDB    = LibStub("AceDB-3.0")

local WizardBuff = AceAddon:NewAddon("WizardBuff", "AceConsole-3.0", "AceEvent-3.0")
ns.addon = WizardBuff

local dbDefaults = { profile = ns.defaults }

---------------------------------------------------------------------------
-- Update scheduler (combat-safe debounce)
---------------------------------------------------------------------------
local _scheduleTimer

function ns.ScheduleUpdate(immediate)
    if InCombatLockdown() then
        ns._pendingUpdate = true
        return
    end
    if _scheduleTimer then return end
    local delay = immediate and 0.05 or 0.3
    _scheduleTimer = C_Timer.After(delay, function()
        _scheduleTimer = nil
        ns._pendingUpdate = false
        ns.UpdateButtons()
    end)
end

---------------------------------------------------------------------------
-- AceAddon lifecycle
---------------------------------------------------------------------------
function WizardBuff:OnInitialize()
    self.db = AceDB:New("WizardBuffDB", dbDefaults, true)
    ns.MigrateLegacy(self)

    self.db.RegisterCallback(self, "OnProfileChanged", function()
        ns.db = self.db.profile
        ns.SetLogicContext(ns.db)
        if ns.ApplyHudScale  then ns.ApplyHudScale()  end
        if ns.ScheduleUpdate then ns.ScheduleUpdate()  end
    end)

    ns.db = self.db.profile
    ns.SetLogicContext(ns.db)

    local ok, err = pcall(ns.RegisterOptions, self)
    if not ok then
        ns.PrintError("options registration failed — " .. tostring(err))
    end

    self:RegisterChatCommand("wizardbuff", "SlashHandler")
    self:RegisterChatCommand("wbuff", "SlashHandler")
end

function WizardBuff:OnEnable()
    ns.RegisterLDB(self)

    local _, class = UnitClass("player")
    ns.isMage = (class == "MAGE")
    if not ns.isMage then return end

    ns.CreateMainFrame()
    ns.CreateMessageFrame()
    ns.CreateHandle()
    ns.UpdateHandleVisibility()
    ns.CreateAutoBuffButton()
    ns.CreateBrillianceButton()
    ns.CreateShieldButton()
    if ns.ApplyHudFade  then ns.ApplyHudFade()  end
    if ns.ApplyHudScale then ns.ApplyHudScale() end

    ns.InitCastFeedback()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("BAG_UPDATE")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent("UI_ERROR_MESSAGE")

    ns.ScheduleUpdate()
    ns.Print("|cff666666" .. ns.VERSION .. "|r — /wbuff config · mage buff HUD")
end

function WizardBuff:OnDisable()
    if ns.mainFrame then ns.mainFrame:Hide() end
end

---------------------------------------------------------------------------
-- Event handlers
---------------------------------------------------------------------------
function WizardBuff:PLAYER_ENTERING_WORLD()  ns.ScheduleUpdate()      end
function WizardBuff:GROUP_ROSTER_UPDATE()     ns.ScheduleUpdate()      end
function WizardBuff:BAG_UPDATE()              ns.ScheduleUpdate()      end
function WizardBuff:PLAYER_TARGET_CHANGED()   ns.ScheduleUpdate()      end
function WizardBuff:COMBAT_LOG_EVENT_UNFILTERED() ns.OnCombatLogEvent() end
function WizardBuff:UI_ERROR_MESSAGE(_, errType, msg) ns.OnUIErrorMessage(errType, msg) end

function WizardBuff:UNIT_AURA(_, unit)
    if unit == "player" or unit == "pet" or unit:match("^party") or unit:match("^raid") then
        ns.ScheduleUpdate()
    end
end

function WizardBuff:PLAYER_REGEN_ENABLED()
    if ns.isMage and ns.ApplyHudFade then ns.ApplyHudFade() end
    if ns._pendingUpdate then
        ns.ScheduleUpdate(true)
    else
        ns.ScheduleUpdate()
    end
end

function WizardBuff:PLAYER_REGEN_DISABLED()
    if ns.isMage and ns.ApplyHudFade then ns.ApplyHudFade() end
end
