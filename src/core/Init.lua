local addonName, ns = ...

ns.name = addonName
_G.WizardBuff = ns

BINDING_HEADER_WIZARDBUFF = "Wizard Buff"
_G["BINDING_NAME_CLICK WizardBuffBuffButton:LeftButton"] = "Cast whatever is needed next"
_G["BINDING_NAME_CLICK WizardBuffIntButton:LeftButton"] = "Arcane Intellect (next target)"
_G["BINDING_NAME_CLICK WizardBuffBrillButton:LeftButton"] = "Arcane Brilliance"
_G["BINDING_NAME_CLICK WizardBuffArmorButton:LeftButton"] = "Armor"
_G["BINDING_NAME_CLICK WizardBuffShieldButton:LeftButton"] = "Shield"

local version = C_AddOns and C_AddOns.GetAddOnMetadata(addonName, "Version")
ns.version = (version and not version:find("@")) and ("v" .. version) or "dev"

---------------------------------------------------------------------------
-- Secret values. Forever hides combat data from addons; never compare,
-- concatenate or do math on a value that may be secret.
---------------------------------------------------------------------------

local issecretvalue = _G.issecretvalue

function ns.IsSecret(v)
    return issecretvalue ~= nil and issecretvalue(v) or false
end

-- Calls fn and returns up to four results, or nil if the call errored or
-- any result is secret.
function ns.SafeCall(fn, ...)
    if not fn then return nil end
    local ok, a, b, c, d = pcall(fn, ...)
    if not ok then return nil end
    if ns.IsSecret(a) or ns.IsSecret(b) or ns.IsSecret(c) or ns.IsSecret(d) then
        return nil
    end
    return a, b, c, d
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
local handlers = {}

function ns.On(event, fn)
    local list = handlers[event]
    if not list then
        list = {}
        handlers[event] = list
        eventFrame:RegisterEvent(event)
    end
    list[#list + 1] = fn
end

function ns.OnUnit(event, unit, fn)
    local list = handlers[event]
    if not list then
        list = {}
        handlers[event] = list
        eventFrame:RegisterUnitEvent(event, unit)
    end
    list[#list + 1] = fn
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    local list = handlers[event]
    if not list then return end
    for i = 1, #list do list[i](...) end
end)

-- Internal signals between modules.
local listeners = {}

function ns.Listen(signal, fn)
    listeners[signal] = listeners[signal] or {}
    table.insert(listeners[signal], fn)
end

function ns.Fire(signal, ...)
    local list = listeners[signal]
    if not list then return end
    for i = 1, #list do list[i](...) end
end

---------------------------------------------------------------------------
-- Output
---------------------------------------------------------------------------

local PREFIX = "|cff69ccf0Wizard Buff|r: "

function ns.Print(...)
    print(PREFIX .. strjoin(" ", tostringall(...)))
end

ns.COLORS = {
    accent  = { 0.41, 0.80, 0.94 },
    good    = { 0.40, 0.90, 0.45 },
    warn    = { 1.00, 0.70, 0.25 },
    bad     = { 1.00, 0.35, 0.35 },
    muted   = { 0.55, 0.57, 0.62 },
    glow    = { 1.00, 0.82, 0.30 },
}

function ns.Hex(c)
    return string.format("%02x%02x%02x", c[1] * 255, c[2] * 255, c[3] * 255)
end

function ns.Colorize(text, c)
    return "|cff" .. ns.Hex(c) .. text .. "|r"
end

function ns.FormatTime(sec)
    if not sec or sec <= 0 then return "" end
    if sec >= 3600 then return string.format("%dh", math.floor(sec / 3600)) end
    if sec >= 60 then return string.format("%dm", math.ceil(sec / 60)) end
    return string.format("%ds", math.floor(sec))
end

function ns.InCombat()
    return InCombatLockdown()
end
