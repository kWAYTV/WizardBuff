local _, ns = ...

local AceAddon = LibStub("AceAddon-3.0")
local AceDB    = LibStub("AceDB-3.0")

local WizardBuff = AceAddon:NewAddon("WizardBuff", "AceConsole-3.0", "AceEvent-3.0")
ns.addon = WizardBuff

local function migrateLegacy(addon)
    local old = _G.MagePowerDB
    if not old or type(old) ~= "table" or addon.db.profile.migratedFromMagePower then
        return
    end
    for k in pairs(ns.defaults) do
        if k ~= "migratedFromMagePower" and k ~= "minimap" and old[k] ~= nil then
            addon.db.profile[k] = old[k]
        end
    end
    if type(old.minimap) == "table" then
        addon.db.profile.minimap.hide = old.minimap.hide and true or false
    end
    addon.db.profile.migratedFromMagePower = true
end

function WizardBuff:OnInitialize()
    self.db = AceDB:New("WizardBuffDB", { profile = ns.defaults }, true)
    migrateLegacy(self)
    ns.db = self.db.profile

    self.db.RegisterCallback(self, "OnProfileChanged", function()
        ns.db = self.db.profile
        if ns.ApplyHudScale then ns.ApplyHudScale() end
        if ns.ScheduleUpdate then ns.ScheduleUpdate() end
    end)

    local ok, err = pcall(ns.RegisterOptions, self)
    if not ok then ns.PrintError("options registration failed — " .. tostring(err)) end

    self:RegisterChatCommand("wizardbuff", "SlashHandler")
    self:RegisterChatCommand("wbuff", "SlashHandler")
end

function WizardBuff:SlashHandler(input)
    ns.HandleSlash(input)
end

function WizardBuff:OnEnable()
    local _, class = UnitClass("player")
    ns.isMage = class == "MAGE"

    if ns.isMage then
        ns.CreateHUD()
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
        ns.ScheduleUpdate(true)
        ns.Print("|cff666666" .. ns.VERSION .. "|r — /wbuff config")
    else
        ns.Print("mage only — HUD hidden")
    end

    local ok, err = pcall(ns.RegisterLDB, self)
    if not ok then ns.PrintError("minimap icon failed — " .. tostring(err)) end
end

function WizardBuff:OnDisable()
    if ns.mainFrame then ns.mainFrame:Hide() end
end

function WizardBuff:PLAYER_ENTERING_WORLD()
    ns.InitCastFeedback()
    ns.ScheduleUpdate()
end
function WizardBuff:GROUP_ROSTER_UPDATE()  ns.ScheduleUpdate() end
function WizardBuff:BAG_UPDATE()           ns.ScheduleUpdate() end
function WizardBuff:PLAYER_TARGET_CHANGED() ns.ScheduleUpdate() end
function WizardBuff:COMBAT_LOG_EVENT_UNFILTERED() ns.OnCombatLogEvent() end
function WizardBuff:UI_ERROR_MESSAGE(_, errType, msg) ns.OnUIErrorMessage(errType, msg) end

function WizardBuff:UNIT_AURA(_, unit)
    if type(unit) ~= "string" then return end
    if unit == "player" or unit == "pet" or unit:match("^party") or unit:match("^raid") then
        ns.ScheduleUpdate()
    end
end

function WizardBuff:PLAYER_REGEN_ENABLED()
    if ns.isMage and ns.ApplyHudFade then ns.ApplyHudFade() end
    ns.ScheduleUpdate(ns._pendingUpdate and true or nil)
end

function WizardBuff:PLAYER_REGEN_DISABLED()
    if ns.isMage and ns.ApplyHudFade then ns.ApplyHudFade() end
end
