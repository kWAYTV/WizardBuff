local addonName, ns = ...
ns.addonName = addonName

local GetAddOnMetadata = _G.C_AddOns and _G.C_AddOns.GetAddOnMetadata or _G.GetAddOnMetadata

local GetSpellInfo = _G.GetSpellInfo or function(spellID)
    local info = _G.C_Spell and _G.C_Spell.GetSpellInfo(spellID)
    if not info then return nil end
    return info.name, nil, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID
end

ns.Compat = {
    GetAddOnMetadata = GetAddOnMetadata,
    GetSpellInfo     = GetSpellInfo,
}

local rawVersion = GetAddOnMetadata(addonName, "Version")
if not rawVersion or rawVersion:find("@") then
    ns.VERSION = "dev"
else
    ns.VERSION = rawVersion
end

ns.REFRESH_THRESHOLD = 0.33

ns.SpellIDs = {
    FrostArmor = {168, 7300, 7301},
    IceArmor = {7302, 7320, 10219, 10220},
    MageArmor = {6117, 22782, 22783},
    IceBarrier = {11426, 13031, 13032, 13033},
    ManaShield = {1463, 8494, 8495, 10191, 10192, 10193},
    ArcaneIntellect = {1459, 1460, 1461, 10156, 10157, 27126},
    ArcaneBrilliance = {23028, 27127},
}

ns.SpellNames = {
    FrostArmor = GetSpellInfo(168),
    IceArmor = GetSpellInfo(7302),
    MageArmor = GetSpellInfo(6117),
    IceBarrier = GetSpellInfo(11426),
    ManaShield = GetSpellInfo(1463),
    ArcaneIntellect = GetSpellInfo(1459),
    ArcaneBrilliance = GetSpellInfo(23028),
}

ns.ArmorBuffNames = {
    GetSpellInfo(168),
    GetSpellInfo(7302),
    GetSpellInfo(6117),
}

ns.ReagentIDs = {
    ArcanePowder = 17020,
}

ns.defaults = {
    enabled = true,
    showWhenSolo = true,
    locked = false,
    hideHudInCombat = true,
    hudAlphaIdle = 0.42,
    hudAlphaHover = 0.95,
    hudScale = 1.0,
    showHudNeedCount = true,
    showTimers = true,
    showGlow = true,
    showSound = false,
    showClassRows = false,
    buffArmor = true,
    armorType = "auto",
    enableBubble = true,
    bubbleType = "auto",
    bubbleThreshold = 50,
    buffIntellect = true,
    useArcaneBrilliance = true,
    buffPets = true,
    showDragHandle = true,
    refreshFloorSec = 120,
    keybind = "",
    hudPos = nil,
    minimap = { hide = false },
    migratedFromMagePower = false,
}

ns.CLASS_ORDER = {"WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID", "PET"}
ns.CLASS_COLORS = {
    WARRIOR = {0.78, 0.61, 0.43},
    PALADIN = {0.96, 0.55, 0.73},
    HUNTER = {0.67, 0.83, 0.45},
    ROGUE = {1.0, 0.96, 0.41},
    PRIEST = {1.0, 1.0, 1.0},
    SHAMAN = {0.0, 0.44, 0.87},
    MAGE = {0.41, 0.80, 0.94},
    WARLOCK = {0.58, 0.51, 0.79},
    DRUID = {1.0, 0.49, 0.04},
    PET = {0.5, 0.8, 0.5},
}

BINDING_HEADER_WIZARDBUFF = "Wizard Buff"
_G["BINDING_NAME_CLICK WizardBuffAutoBuffButton:LeftButton"] = "Self Buff (armor, shield)"
_G["BINDING_NAME_CLICK WizardBuffBrillianceButton:LeftButton"] = "Group Buff (Int / Brilliance)"

ns.db = nil
ns.isMage = false
ns.roster = {}
ns.mainFrame = nil
ns.gridCells = {}
ns.autoBuffButton = nil
ns.brillianceButton = nil
ns._hudMouseOver = false

_G.WizardBuffAddon = ns

function ns.Print(msg)
    print("|cff9ab8d4Wizard Buff|r: " .. tostring(msg))
end

function ns.PrintError(msg)
    print("|cffff6666Wizard Buff|r: " .. tostring(msg))
end

local AceAddon = LibStub("AceAddon-3.0")
local AceDB = LibStub("AceDB-3.0")

local WizardBuff = AceAddon:NewAddon("WizardBuff", "AceConsole-3.0", "AceEvent-3.0")

ns.addon = WizardBuff

local dbDefaults = {
    profile = ns.defaults,
}

local _scheduleTimer
function ns.ScheduleUpdate()
    if _scheduleTimer then return end
    if InCombatLockdown() then
        ns._pendingUpdate = true
        return
    end
    _scheduleTimer = C_Timer.After(0.3, function()
        _scheduleTimer = nil
        ns._pendingUpdate = false
        ns.UpdateButtons()
    end)
end

local function migrateLegacy(self)
    local old = _G.MagePowerDB
    if not old or type(old) ~= "table" or self.db.profile.migratedFromMagePower then
        return
    end
    for k, _ in pairs(ns.defaults) do
        if k ~= "migratedFromMagePower" and k ~= "minimap" and old[k] ~= nil then
            self.db.profile[k] = old[k]
        end
    end
    if old.minimap and type(old.minimap) == "table" then
        self.db.profile.minimap.hide = old.minimap.hide and true or false
    end
    self.db.profile.migratedFromMagePower = true
end

function WizardBuff:OnInitialize()
    self.db = AceDB:New("WizardBuffDB", dbDefaults, true)
    migrateLegacy(self)
    self.db.RegisterCallback(self, "OnProfileChanged", function()
        ns.db = self.db.profile
        ns.SetLogicContext(ns.db, ns.roster)
        if ns.ApplyHudScale  then ns.ApplyHudScale()  end
        if ns.ScheduleUpdate then ns.ScheduleUpdate() end
    end)
    ns.db = self.db.profile
    ns.SetLogicContext(ns.db, ns.roster)

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
    if not ns.isMage then
        return
    end
    ns.CreateMainFrame()
    ns.CreateHandle()
    ns.UpdateHandleVisibility()
    ns.CreateAutoBuffButton()
    ns.CreateBrillianceButton()
    if ns.ApplyHudFade then
        ns.ApplyHudFade()
    end
    if ns.ApplyHudScale then
        ns.ApplyHudScale()
    end
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:RegisterEvent("UNIT_AURA")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("BAG_UPDATE")
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    ns.ScheduleUpdate()
    ns.Print("|cff666666v" .. ns.VERSION .. "|r — /wbuff config · mage buff HUD")
end

function WizardBuff:OnDisable()
    if ns.mainFrame then
        ns.mainFrame:Hide()
    end
end

function WizardBuff:SlashHandler(input)
    local msg = (input or ""):lower()
    local cmd = msg:match("^(%S*)") or ""
    local db = ns.db
    if not db then
        return
    end
    if cmd == "" or cmd == "toggle" then
        db.enabled = not db.enabled
        ns.Print(db.enabled and "on" or "off")
        ns.ScheduleUpdate()
    elseif cmd == "config" or cmd == "options" or cmd == "settings" then
        ns.OpenConfig()
    elseif cmd == "lock" then
        db.locked = not db.locked
        if db.locked then
            if ns.CancelAutoLock then ns.CancelAutoLock() end
            ns.Print("Locked")
        else
            if ns.ScheduleAutoLock then ns.ScheduleAutoLock() end
            ns.Print("Unlocked (auto-locks in 30s)")
        end
    elseif cmd == "grid" or cmd == "rows" or cmd == "classrows" then
        db.showClassRows = not db.showClassRows
        ns.Print("Buff grid " .. (db.showClassRows and "on" or "off"))
        ns.ScheduleUpdate()
    elseif cmd == "armor" then
        db.buffArmor = not db.buffArmor
        ns.Print("Armor " .. (db.buffArmor and "on" or "off"))
        ns.ScheduleUpdate()
    elseif cmd == "bubble" then
        db.enableBubble = not db.enableBubble
        ns.Print("Bubble " .. (db.enableBubble and "on" or "off"))
        ns.ScheduleUpdate()
    elseif cmd == "int" or cmd == "intellect" then
        db.buffIntellect = not db.buffIntellect
        ns.Print("Intellect " .. (db.buffIntellect and "on" or "off"))
        ns.ScheduleUpdate()
    elseif cmd == "brilliance" then
        db.useArcaneBrilliance = not db.useArcaneBrilliance
        ns.Print("Brilliance preference " .. (db.useArcaneBrilliance and "on" or "off"))
        ns.ScheduleUpdate()
    elseif cmd == "pets" then
        db.buffPets = not db.buffPets
        ns.Print("Pets " .. (db.buffPets and "on" or "off"))
        ns.ScheduleUpdate()
    elseif cmd == "report" then
        local report = ns.GetBuffReport()
        local channel = IsInRaid() and "RAID" or IsInGroup() and "PARTY" or nil
        if channel then
            SendChatMessage(report, channel)
        else
            ns.Print(report)
        end
    elseif cmd == "macro" then
        ns.Print("Self buff macro: /click WizardBuffAutoBuffButton")
        ns.Print("Group buff macro: /click WizardBuffBrillianceButton")
    else
        ns.Print("/wbuff toggle | config | lock | grid | armor | bubble | int | brilliance | pets | report | macro")
    end
end

function WizardBuff:PLAYER_ENTERING_WORLD()
    ns.ScheduleUpdate()
end

function WizardBuff:GROUP_ROSTER_UPDATE()
    ns.ScheduleUpdate()
end

function WizardBuff:UNIT_AURA(_, unit)
    if unit == "player" or unit:match("^party") or unit:match("^raid") then
        ns.ScheduleUpdate()
    end
end

function WizardBuff:PLAYER_REGEN_ENABLED()
    if ns.isMage and ns.ApplyHudFade then
        ns.ApplyHudFade()
    end
    ns.ScheduleUpdate()
end

function WizardBuff:PLAYER_REGEN_DISABLED()
    if ns.isMage and ns.ApplyHudFade then
        ns.ApplyHudFade()
    end
end

function WizardBuff:BAG_UPDATE()
    ns.ScheduleUpdate()
end

function WizardBuff:PLAYER_TARGET_CHANGED()
    ns.ScheduleUpdate()
end
