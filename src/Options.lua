local _, ns = ...
ns = ns or _G.WizardBuffAddon
assert(ns, "WizardBuff: load WizardBuff.lua before Options.lua")

function ns.RegisterOptions(addon)
    local AceConfig       = LibStub("AceConfig-3.0")
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")

    local function refresh()
        if ns.ScheduleUpdate  then ns.ScheduleUpdate()  end
        if ns.ApplyHudFade    then ns.ApplyHudFade()    end
        if ns.ApplyHudScale   then ns.ApplyHudScale()   end
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
                    testSound = {
                        type = "execute", name = "Test self sound", order = 7.5,
                        width = 0.7,
                        func = function()
                            PlaySoundFile("Sound\\Interface\\AlarmClockWarning3.ogg", "Master")
                        end,
                    },
                    testSound2 = {
                        type = "execute", name = "Test group sound", order = 7.6,
                        width = 0.7,
                        func = function()
                            PlaySoundFile("Sound\\Interface\\iQuestUpdate.ogg", "Master")
                        end,
                    },
                    showClassRows = {
                        type = "toggle", name = "Buff grid", order = 8,
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
                            if addon.db.profile then
                                addon.db.profile.hudPos = nil
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
            profiles = {
                order  = 50,
                type   = "group",
                name   = "Profiles",
                inline = true,
                args   = {
                    current = {
                        order = 1, type = "description", fontSize = "medium",
                        name = function()
                            return "Active: |cffffd100" .. addon.db:GetCurrentProfile() .. "|r"
                        end,
                    },
                    choose = {
                        order = 2, type = "select", name = "Switch",
                        width = 1.0,
                        get = function() return addon.db:GetCurrentProfile() end,
                        set = function(_, v) addon.db:SetProfile(v); refresh() end,
                        values = profileList(false),
                    },
                    new = {
                        order = 3, type = "input", name = "New",
                        width = 1.0,
                        get = false,
                        set = function(_, v)
                            if v and v:trim() ~= "" then
                                addon.db:SetProfile(v:trim()); refresh()
                            end
                        end,
                    },
                    copy = {
                        order = 4, type = "select", name = "Copy from",
                        width = 1.0,
                        get = false,
                        set = function(_, v) addon.db:CopyProfile(v); refresh() end,
                        values = profileList(true),
                        confirm = true,
                        confirmText = "Overwrite current settings with the selected profile?",
                    },
                    delete = {
                        order = 5, type = "select", name = "Delete",
                        width = 1.0,
                        get = false,
                        set = function(_, v) addon.db:DeleteProfile(v) end,
                        values = profileList(true),
                        confirm = true,
                        confirmText = "Delete the selected profile?",
                    },
                    reset = {
                        order = 6, type = "execute", name = "Reset to defaults",
                        width = 1.0,
                        func = function() addon.db:ResetProfile(); refresh() end,
                        confirm = true,
                        confirmText = "Reset current profile to defaults?",
                    },
                    spacer = {
                        order = 9, type = "description", name = "",
                    },
                    export = {
                        order = 10, type = "execute", name = "Export",
                        width = 0.6,
                        func = function() ns.ShowProfileExport() end,
                    },
                    import = {
                        order = 11, type = "execute", name = "Import",
                        width = 0.6,
                        func = function() ns.ShowProfileImport() end,
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

local function serializeValue(v)
    local t = type(v)
    if t == "string" then return string.format("%q", v)
    elseif t == "number" then return tostring(v)
    elseif t == "boolean" then return v and "true" or "false"
    elseif t == "table" then
        local parts = {}
        for k, sv in pairs(v) do
            local key
            if type(k) == "string" then
                key = k:match("^[%a_][%w_]*$") and k or ("[" .. string.format("%q", k) .. "]")
            else
                key = "[" .. tostring(k) .. "]"
            end
            local val = serializeValue(sv)
            if val then parts[#parts + 1] = key .. "=" .. val end
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
end

local function deserializeProfile(str)
    if not str or str:trim() == "" then return nil, "Empty string" end
    local fn, err = loadstring("return " .. str)
    if not fn then return nil, err end
    setfenv(fn, {})
    local ok, result = pcall(fn)
    if not ok then return nil, result end
    if type(result) ~= "table" then return nil, "Expected a table" end
    return result
end

local function createPopupFrame(name, titleText, w, h)
    local f = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    f:SetSize(w, h)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -10)
    title:SetText(titleText)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    local scroll = CreateFrame("ScrollFrame", name .. "Scroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -32)
    scroll:SetPoint("BOTTOMRIGHT", -30, 40)

    local eb = CreateFrame("EditBox", name .. "Edit", scroll)
    eb:SetMultiLine(true)
    eb:SetAutoFocus(false)
    eb:SetFont(STANDARD_TEXT_FONT, 11)
    eb:SetWidth(scroll:GetWidth() or (w - 50))
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scroll:SetScrollChild(eb)
    f.editBox = eb

    f:Hide()
    return f
end

function ns.ShowProfileExport()
    if not ns._exportFrame then
        ns._exportFrame = createPopupFrame("WizardBuffExport", "Export Profile", 420, 300)
    end
    local data = serializeValue(ns.db) or "{}"
    local eb = ns._exportFrame.editBox
    eb:SetText(data)
    ns._exportFrame:Show()
    eb:HighlightText()
    eb:SetFocus()
end

function ns.ShowProfileImport()
    if not ns._importFrame then
        local f = createPopupFrame("WizardBuffImport", "Import Profile", 420, 300)
        local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        btn:SetSize(80, 22)
        btn:SetPoint("BOTTOM", 0, 10)
        btn:SetText("Apply")
        btn:SetScript("OnClick", function()
            local str = f.editBox:GetText()
            local tbl, err = deserializeProfile(str)
            if not tbl then
                ns.PrintError("Import failed — " .. tostring(err))
                return
            end
            local profile = ns.db
            for k, v in pairs(tbl) do
                if ns.defaults[k] ~= nil or k == "minimap" or k == "hudPos" then
                    profile[k] = v
                end
            end
            if ns.ScheduleUpdate then ns.ScheduleUpdate() end
            if ns.ApplyHudScale then ns.ApplyHudScale() end
            if ns.ApplyHudFade then ns.ApplyHudFade() end
            f:Hide()
            ns.Print("Profile imported.")
        end)
        ns._importFrame = f
    end
    local eb = ns._importFrame.editBox
    eb:SetText("")
    ns._importFrame:Show()
    eb:SetFocus()
end
