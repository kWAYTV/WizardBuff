local _, ns = ...

-- Native Settings panel (Esc > Options > AddOns > Wizard Buff).

local category

local function changed()
    ns.Fire("SETTINGS_CHANGED")
end

local function var(key)
    return "WIZARDBUFF_" .. key:upper()
end

local function addSetting(key, label)
    local default = ns.defaults[key]
    local setting = Settings.RegisterAddOnSetting(category, var(key), key, ns.db, type(default), label, default)
    setting:SetValueChangedCallback(changed)
    return setting
end

local function checkbox(key, label, tip)
    Settings.CreateCheckbox(category, addSetting(key, label), tip)
end

local function slider(key, label, tip, min, max, step, format)
    local options = Settings.CreateSliderOptions(min, max, step)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, format)
    Settings.CreateSlider(category, addSetting(key, label), options, tip)
end

local function dropdown(key, label, tip, choices)
    local function getOptions()
        local container = Settings.CreateControlTextContainer()
        for _, c in ipairs(choices) do container:Add(c[1], c[2]) end
        return container:GetData()
    end
    Settings.CreateDropdown(category, addSetting(key, label), getOptions, tip)
end

local function header(layout, text)
    layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
end

local function percent(v) return string.format("%d%%", math.floor(v * 100 + 0.5)) end
local function plain(v) return tostring(math.floor(v + 0.5)) end

local CLICK_CHOICES = {
    { "none", "Nothing" },
    { "dampen", "Dampen Magic" },
    { "amplify", "Amplify Magic" },
    { "intellect", "Arcane Intellect" },
    { "brilliance", "Arcane Brilliance" },
}

local function build()
    local layout
    category, layout = Settings.RegisterVerticalLayoutCategory("Wizard Buff")

    header(layout, "General")
    checkbox("enabled", "Show Wizard Buff", "Turn the icon bar and grid on or off.")
    checkbox("showSolo", "Show when solo", "Keep the icon bar visible when you are not in a group.")
    checkbox("locked", "Lock position", "Unlock to show a mover you can drag. Right-click it to lock again.")
    checkbox("showPets", "Include pets", "Show and buff group members' pets.")

    header(layout, "Buffs")
    dropdown("armor", "Armor", "Armor on the armor icon. Auto picks Mage Armor in dungeons and raids, Ice Armor elsewhere.", {
        { "auto", "Auto" }, { "mage", "Mage Armor" }, { "ice", "Ice Armor" },
        { "frost", "Frost Armor" }, { "none", "None" },
    })
    checkbox("useBrilliance", "Suggest Arcane Brilliance", "Light up the Brilliance icon (and let the keybind cast it) when several people need Intellect.")
    slider("brillianceMin", "Brilliance when this many need it",
        "Below this count, single-target Intellect is suggested to save Arcane Powder.", 1, 10, 1, plain)
    slider("rebuffMinutes", "Rebuff under (minutes)",
        "Treat buffs with less time left than this as missing.", 0, 30, 1, plain)
    dropdown("shield", "Shield", "Spell on the shield icon.", {
        { "auto", "Auto" }, { "barrier", "Ice Barrier" }, { "mana", "Mana Shield" }, { "none", "None" },
    })
    slider("shieldHealth", "Shield alert below health %", "The shield icon glows when your health drops below this.",
        10, 100, 5, function(v) return plain(v) .. "%" end)

    header(layout, "Grid clicks")
    dropdown("shiftClick", "Shift-click", "Spell cast by Shift-clicking a grid cell.", CLICK_CHOICES)
    dropdown("ctrlClick", "Ctrl-click", "Spell cast by Ctrl-clicking a grid cell.", CLICK_CHOICES)

    header(layout, "Look")
    dropdown("layout", "Grid layout", "How raid groups are arranged.", {
        { "rows", "One row per group" }, { "columns", "One column per group" },
    })
    slider("iconSize", "Icon size", nil, 24, 64, 2, plain)
    slider("cellWidth", "Cell width", nil, 30, 120, 2, plain)
    slider("cellHeight", "Cell height", nil, 14, 40, 2, plain)
    slider("scale", "Scale", nil, 0.5, 2, 0.05, percent)
    slider("alpha", "Opacity", "Opacity when the mouse is not over it.", 0.2, 1, 0.05, percent)
    slider("combatAlpha", "Opacity in combat", nil, 0, 1, 0.05, percent)

    header(layout, "Alerts")
    checkbox("glow", "Glow", "Glow icons and cells that need a buff.")
    checkbox("sound", "Sound", "Play a sound when someone you cover needs a buff.")
    checkbox("readyCheck", "Ready check reminder", "On a ready check, tell you who still needs Intellect.")

    header(layout, "Coordination")
    checkbox("coordinate", "Share work with other mages",
        "Split raid groups between mages running Wizard Buff, like PallyPower assignments.")

    local mm = Settings.RegisterProxySetting(category, var("minimap_hide"), type(true), "Minimap button", true,
        function() return not ns.db.minimap.hide end,
        function(v) ns.db.minimap.hide = not v; ns.UpdateMinimapButton() end)
    Settings.CreateCheckbox(category, mm, "Show the minimap button. Wizard Buff is also in the addon compartment.")

    layout:AddInitializer(CreateSettingsButtonInitializer("Reset", "Reset settings", function()
        ns.ResetDB()
        ns.Print("Settings reset. Reopen this panel to see the defaults.")
    end, "Restore every setting to its default.", true))

    Settings.RegisterAddOnCategory(category)
end

function ns.CreateSettings()
    local ok, err = pcall(build)
    if not ok then
        category = nil
        ns.Print("Settings panel unavailable (" .. tostring(err) .. "). Use /wbuff help.")
    end
end

function ns.OpenSettings()
    if category then
        Settings.OpenToCategory(category:GetID())
    else
        ns.PrintHelp()
    end
end
