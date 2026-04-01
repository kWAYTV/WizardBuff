local _, ns = ...

function ns.RegisterOptions(addon)
    local AceConfig       = LibStub("AceConfig-3.0")
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")

    local function refresh()
        if ns.ScheduleUpdate then ns.ScheduleUpdate() end
        if ns.ApplyHudFade  then ns.ApplyHudFade()  end
        if ns.ApplyHudScale then ns.ApplyHudScale() end
    end

    local function get(info)   return addon.db.profile[info[#info]] end
    local function set(info,v) addon.db.profile[info[#info]] = v; refresh() end
    local inCombat = function() return InCombatLockdown() end

    local function profileList(excludeCurrent)
        return function()
            local out = {}
            local cur = addon.db:GetCurrentProfile()
            for _, name in pairs(addon.db:GetProfiles({})) do
                if not (excludeCurrent and name == cur) then
                    out[name] = name
                end
            end
            return out
        end
    end

    local options = {
        type = "group",
        name = "Wizard Buff",
        childGroups = "tab",
        get  = get,
        set  = set,
        args = {

            ---------- TAB 1: General ----------
            general = {
                order = 1, type = "group", name = "General",
                args = {
                    core = {
                        order = 1, type = "group", name = "Core", inline = true,
                        args = {
                            enabled = {
                                type = "toggle", name = "Enabled", desc = "", order = 1,
                                width = "full", disabled = inCombat,
                            },
                            showWhenSolo = {
                                type = "toggle", name = "Show when solo",
                                desc = "Display the HUD even when not in a group",
                                order = 2, width = "full",
                            },
                            locked = {
                                type = "toggle", name = "Lock position", desc = "",
                                order = 3, width = "full",
                            },
                        },
                    },
                    display = {
                        order = 2, type = "group", name = "HUD Elements", inline = true,
                        args = {
                            showTimers = {
                                type = "toggle", name = "Buff timers",
                                desc = "Show remaining duration on icons",
                                order = 1, width = "full",
                            },
                            showGlow = {
                                type = "toggle", name = "Glow alerts",
                                desc = "Pulsing border when a buff needs casting",
                                order = 2, width = "full",
                            },
                            showHudNeedCount = {
                                type = "toggle", name = "Need count text",
                                desc = "Show how many group members need Intellect",
                                order = 3, width = "full",
                            },
                            showClassRows = {
                                type = "toggle", name = "Buff grid (class rows)",
                                desc = "Per-player cast buttons grouped by class",
                                order = 4, width = "full", disabled = inCombat,
                            },
                            gridColumns = {
                                type = "range", name = "Grid columns",
                                desc = "Number of player cells per row in the buff grid",
                                order = 4.5, width = "full",
                                min = 2, max = 20, step = 1,
                                disabled = function() return not addon.db.profile.showClassRows end,
                            },
                            showDragHandle = {
                                type = "toggle", name = "Show drag handle",
                                desc = "Small handle above the HUD for dragging and quick actions",
                                order = 5, width = "full",
                                set = function(_, v)
                                    addon.db.profile.showDragHandle = v
                                    if ns.UpdateHandleVisibility then ns.UpdateHandleVisibility() end
                                end,
                            },
                            minimapHide = {
                                type = "toggle", name = "Hide minimap icon", desc = "",
                                order = 6, width = "full",
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
                    sound = {
                        order = 3, type = "group", name = "Sound", inline = true,
                        args = {
                            showSound = {
                                type = "toggle", name = "Enable sound alerts",
                                desc = "Play a sound when buffs are missing",
                                order = 1, width = "full",
                            },
                            testSound = {
                                type = "execute", name = "Test self sound", desc = "",
                                order = 2, width = 0.8,
                                disabled = function() return not addon.db.profile.showSound end,
                                func = function() PlaySoundFile(ns.SOUND_SELF, "Master") end,
                            },
                            testSound2 = {
                                type = "execute", name = "Test group sound", desc = "",
                                order = 3, width = 0.8,
                                disabled = function() return not addon.db.profile.showSound end,
                                func = function() PlaySoundFile(ns.SOUND_GROUP, "Master") end,
                            },
                        },
                    },
                },
            },

            ---------- TAB 2: Appearance ----------
            appearance = {
                order = 2, type = "group", name = "Appearance",
                args = {
                    scale = {
                        order = 1, type = "group", name = "Scale & Opacity", inline = true,
                        args = {
                            hudScale = {
                                type = "range", name = "HUD scale", desc = "", order = 1,
                                width = "full", min = 0.5, max = 2, step = 0.05, isPercent = true,
                                disabled = inCombat,
                            },
                            hudAlphaIdle = {
                                type = "range", name = "Idle opacity",
                                desc = "Opacity when not hovering the HUD", order = 2,
                                width = "full", min = 0, max = 1, step = 0.05, isPercent = true,
                            },
                            hudAlphaHover = {
                                type = "range", name = "Hover opacity",
                                desc = "Opacity when hovering the HUD", order = 3,
                                width = "full", min = 0.3, max = 1, step = 0.05, isPercent = true,
                            },
                        },
                    },
                    combat = {
                        order = 2, type = "group", name = "Combat", inline = true,
                        args = {
                            hideHudInCombat = {
                                type = "toggle", name = "Fade HUD in combat",
                                desc = "Reduce opacity during combat to avoid distraction",
                                order = 1, width = "full",
                            },
                        },
                    },
                    position = {
                        order = 3, type = "group", name = "Position", inline = true,
                        args = {
                            resetPosition = {
                                type = "execute", name = "Reset position to center", desc = "",
                                order = 1, disabled = inCombat,
                                func = function()
                                    if ns.mainFrame then
                                        ns.mainFrame:ClearAllPoints()
                                        ns.mainFrame:SetPoint("CENTER", 0, 200)
                                    end
                                    if addon.db.profile then
                                        addon.db.profile.hudPos = nil
                                    end
                                end,
                            },
                        },
                    },
                },
            },

            ---------- TAB 3: Buffs ----------
            buffs = {
                order = 3, type = "group", name = "Buffs",
                args = {
                    selfBuffs = {
                        order = 1, type = "group", name = "Self Buffs (Left Button)", inline = true,
                        args = {
                            buffArmor = {
                                type = "toggle", name = "Armor", desc = "",
                                order = 1, width = 1.0,
                            },
                            armorType = {
                                type = "select", name = "Armor type", desc = "",
                                order = 2, width = 1.0,
                                values = { auto = "Auto", ice = "Ice", mage = "Mage", frost = "Frost" },
                                disabled = function() return not addon.db.profile.buffArmor end,
                            },
                            spacer1 = { order = 3, type = "description", name = "" },
                            enableBubble = {
                                type = "toggle", name = "Emergency shield",
                                desc = "Cast a shield when HP drops below the threshold",
                                order = 4, width = 1.0,
                            },
                            bubbleType = {
                                type = "select", name = "Shield type", desc = "",
                                order = 5, width = 1.0,
                                values = { auto = "Auto", icebarrier = "Ice Barrier", manashield = "Mana Shield", none = "Off" },
                                disabled = function() return not addon.db.profile.enableBubble end,
                            },
                            bubbleThreshold = {
                                type = "range", name = "Shield HP% threshold",
                                desc = "Cast shield when HP drops below this percentage",
                                order = 6, width = "full", min = 5, max = 100, step = 5,
                                disabled = function() return not addon.db.profile.enableBubble end,
                            },
                        },
                    },
                    groupBuffs = {
                        order = 2, type = "group", name = "Group Buffs (Right Button)", inline = true,
                        args = {
                            buffIntellect = {
                                type = "toggle", name = "Intellect", desc = "",
                                order = 1, width = 1.0,
                            },
                            useArcaneBrilliance = {
                                type = "toggle", name = "Prefer Arcane Brilliance",
                                desc = "Use Arcane Brilliance instead of single-target Intellect when possible",
                                order = 2, width = 1.0,
                                disabled = function() return not addon.db.profile.buffIntellect end,
                            },
                            buffPets = {
                                type = "toggle", name = "Buff pets", desc = "",
                                order = 3, width = "full",
                                disabled = function() return not addon.db.profile.buffIntellect end,
                            },
                        },
                    },
                    refreshGuard = {
                        order = 3, type = "group", name = "Refresh Guard", inline = true,
                        args = {
                            refreshDesc = {
                                order = 1, type = "description",
                                name = "Don't refresh buffs that still have more than this many seconds remaining. Set to 0 to disable.",
                            },
                            refreshFloorSec = {
                                type = "range", name = "Min remaining (seconds)", desc = "",
                                order = 2, width = "full", min = 0, max = 600, step = 30,
                            },
                        },
                    },
                },
            },

            ---------- TAB 4: Profiles ----------
            profiles = {
                order = 10, type = "group", name = "Profiles",
                args = {
                    current = {
                        order = 1, type = "description", fontSize = "medium",
                        name = function()
                            return "Active: |cffffd100" .. addon.db:GetCurrentProfile() .. "|r"
                        end,
                    },
                    manage = {
                        order = 2, type = "group", name = "Manage", inline = true,
                        args = {
                            choose = {
                                order = 1, type = "select", name = "Switch profile", desc = "",
                                width = 1.2,
                                get = function() return addon.db:GetCurrentProfile() end,
                                set = function(_, v) addon.db:SetProfile(v); refresh() end,
                                values = profileList(false),
                            },
                            new = {
                                order = 2, type = "input", name = "New profile", desc = "",
                                width = 1.2, get = false,
                                set = function(_, v)
                                    if v and v:trim() ~= "" then
                                        addon.db:SetProfile(v:trim()); refresh()
                                    end
                                end,
                            },
                            copy = {
                                order = 3, type = "select", name = "Copy from",
                                desc = "Copy all settings from another profile into the current one",
                                width = 1.2, get = false,
                                set = function(_, v) addon.db:CopyProfile(v); refresh() end,
                                values = profileList(true),
                                confirm = true,
                                confirmText = "Overwrite current settings with the selected profile?",
                            },
                            delete = {
                                order = 4, type = "select", name = "Delete", desc = "",
                                width = 1.2, get = false,
                                set = function(_, v) addon.db:DeleteProfile(v) end,
                                values = profileList(true),
                                confirm = true,
                                confirmText = "Delete the selected profile?",
                            },
                        },
                    },
                    actions = {
                        order = 3, type = "group", name = " ", inline = true,
                        args = {
                            reset = {
                                order = 1, type = "execute", name = "Reset to defaults", desc = "",
                                func = function() addon.db:ResetProfile(); refresh() end,
                                confirm = true,
                                confirmText = "Reset current profile to defaults?",
                            },
                            export = {
                                order = 2, type = "execute", name = "Export",
                                desc = "Copy profile data to share or back up",
                                width = 0.6,
                                func = function() ns.ShowProfileExport() end,
                            },
                            import = {
                                order = 3, type = "execute", name = "Import",
                                desc = "Paste and apply profile data",
                                width = 0.6,
                                func = function() ns.ShowProfileImport() end,
                            },
                        },
                    },
                },
            },
        },
    }

    AceConfig:RegisterOptionsTable("WizardBuff", options)
    AceConfigDialog:AddToBlizOptions("WizardBuff", "Wizard Buff")
end

function ns.OpenConfig()
    LibStub("AceConfigDialog-3.0"):Open("WizardBuff")
end
