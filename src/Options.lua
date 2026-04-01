local _, ns = ...
ns = ns or _G.WizardBuffAddon
assert(ns, "WizardBuff: load WizardBuff.lua before Options.lua")

function WizardBuff_RegisterOptions(addon)
    local AceConfig       = LibStub("AceConfig-3.0")
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")
    local AceDBOptions    = LibStub("AceDBOptions-3.0")

    local function refresh()
        if ns.ScheduleUpdate  then ns.ScheduleUpdate()  end
        if ns.RefreshHudChrome then ns.RefreshHudChrome() end
        if ns.ApplyHudFade    then ns.ApplyHudFade()    end
        if ns.ApplyHudScale   then ns.ApplyHudScale()   end
    end

    local function get(info)   return addon.db.profile[info[#info]] end
    local function set(info,v) addon.db.profile[info[#info]] = v; refresh() end
    local inCombat = function() return InCombatLockdown() end

    local profileOpts = AceDBOptions:GetOptionsTable(addon.db)
    profileOpts.order  = 50
    profileOpts.inline = true

    local options = {
        type = "group",
        name = "Wizard Buff",
        get  = get,
        set  = set,
        args = {
            core = {
                order  = 1,
                type   = "group",
                name   = "General",
                inline = true,
                args   = {
                    enabled = {
                        type = "toggle", name = "Enabled", order = 1,
                        width = 1.0, disabled = inCombat,
                    },
                    locked = {
                        type = "toggle", name = "Lock position", order = 2,
                        width = 1.0,
                    },
                    showWhenSolo = {
                        type = "toggle", name = "Show solo", order = 3,
                        width = 1.0,
                    },
                    showHudNeedCount = {
                        type = "toggle", name = "Need count", order = 4,
                        width = 1.0,
                    },
                    showTimers = {
                        type = "toggle", name = "Buff timers", order = 5,
                        width = 1.0,
                    },
                    showGlow = {
                        type = "toggle", name = "Glow alerts", order = 6,
                        width = 1.0,
                    },
                    showSound = {
                        type = "toggle", name = "Sound alert", order = 7,
                        width = 1.0,
                    },
                    showClassRows = {
                        type = "toggle", name = "Class rows", order = 8,
                        width = 1.0, disabled = inCombat,
                    },
                    minimapHide = {
                        type = "toggle", name = "Hide minimap icon", order = 9,
                        width = 1.0,
                        get = function() return addon.db.profile.minimap.hide end,
                        set = function(_, v)
                            addon.db.profile.minimap.hide = v
                            local icon = LibStub("LibDBIcon-1.0", true)
                            if icon then
                                if v then icon:Hide("WizardBuff") else icon:Show("WizardBuff") end
                            end
                        end,
                    },
                },
            },
            appearance = {
                order  = 2,
                type   = "group",
                name   = "Appearance",
                inline = true,
                args   = {
                    hudScale = {
                        type = "range", name = "Scale", order = 1,
                        width = 1.5,
                        min = 0.5, max = 2, step = 0.05, isPercent = true,
                        disabled = inCombat,
                    },
                    hudAlphaIdle = {
                        type = "range", name = "Idle opacity", order = 2,
                        width = 1.5,
                        min = 0, max = 1, step = 0.05, isPercent = true,
                    },
                    hudAlphaHover = {
                        type = "range", name = "Hover opacity", order = 3,
                        width = 1.5,
                        min = 0.3, max = 1, step = 0.05, isPercent = true,
                    },
                    hideHudInCombat = {
                        type = "toggle", name = "Fade in combat", order = 4,
                        width = 1.0,
                    },
                    resetPosition = {
                        type = "execute", name = "Reset position", order = 5,
                        disabled = inCombat,
                        func = function()
                            if ns.mainFrame then
                                ns.mainFrame:ClearAllPoints()
                                ns.mainFrame:SetPoint("CENTER", 0, 200)
                            end
                        end,
                    },
                },
            },
            buffs = {
                order  = 3,
                type   = "group",
                name   = "Buffs",
                inline = true,
                args   = {
                    buffArmor = {
                        type = "toggle", name = "Armor", order = 1,
                        width = 1.0,
                    },
                    armorType = {
                        type = "select", name = "Armor type", order = 2,
                        width = 1.0,
                        values = { auto = "Auto", ice = "Ice", mage = "Mage", frost = "Frost" },
                        disabled = function() return not addon.db.profile.buffArmor end,
                    },
                    buffIntellect = {
                        type = "toggle", name = "Intellect", order = 3,
                        width = 1.0,
                    },
                    useArcaneBrilliance = {
                        type = "toggle", name = "Prefer Brilliance", order = 4,
                        width = 1.0,
                        disabled = function() return not addon.db.profile.buffIntellect end,
                    },
                    buffPets = {
                        type = "toggle", name = "Buff pets", order = 5,
                        width = 1.0,
                        disabled = function() return not addon.db.profile.buffIntellect end,
                    },
                    enableBubble = {
                        type = "toggle", name = "Emergency shield", order = 6,
                        width = 1.0,
                    },
                    bubbleType = {
                        type = "select", name = "Shield type", order = 7,
                        width = 1.0,
                        values = { auto = "Auto", icebarrier = "Ice Barrier", manashield = "Mana Shield", none = "Off" },
                        disabled = function() return not addon.db.profile.enableBubble end,
                    },
                    bubbleThreshold = {
                        type = "range", name = "Shield HP%", order = 8,
                        width = 1.5,
                        min = 5, max = 100, step = 5,
                        disabled = function() return not addon.db.profile.enableBubble end,
                    },
                },
            },
            profiles = profileOpts,
        },
    }

    AceConfig:RegisterOptionsTable("WizardBuff", options)
    AceConfigDialog:AddToBlizOptions("WizardBuff", "Wizard Buff")
end

function ns.OpenConfig()
    LibStub("AceConfigDialog-3.0"):Open("WizardBuff")
end
