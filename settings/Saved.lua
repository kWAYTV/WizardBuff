local _, ns = ...

local DEFAULT_POS = { point = "CENTER", relPoint = "CENTER", x = 0, y = -180 }

function ns.defaultPosition()
    return { point = DEFAULT_POS.point, relPoint = DEFAULT_POS.relPoint, x = DEFAULT_POS.x, y = DEFAULT_POS.y }
end

-- Rebuilt from the keys still in use, so settings from old versions don't
-- pile up in the saved file.
function ns.loadSaved()
    local old = type(WizardBuffDB) == "table" and WizardBuffDB or {}
    local pos = type(old.pos) == "table" and old.pos or {}
    local default = ns.defaultPosition()
    ns.db = {
        shown = old.shown ~= false and old.enabled ~= false,
        scale = tonumber(old.scale) or 1,
        layout = ns.grid.styles[old.layout] and old.layout or "list",
        layoutChosen = old.layoutChosen == true,
        minimap = old.minimap ~= false,
        minimapAngle = tonumber(old.minimapAngle) or 215,
        onlyNeeded = old.onlyNeeded == true,
        hideResting = old.hideResting == true,
        remind = tonumber(old.remind) or 0,
        brilliance = old.brilliance ~= false,
        brillianceMin = tonumber(old.brillianceMin) or 3,
        readyCheck = old.readyCheck ~= false,
        sound = old.sound ~= false,
        fade = old.fade == true,
        armor = ns.armor.lines[old.armor] and old.armor or nil,
        pos = {
            point = pos.point or default.point, relPoint = pos.relPoint or default.relPoint,
            x = tonumber(pos.x) or default.x, y = tonumber(pos.y) or default.y,
        },
    }
    WizardBuffDB = ns.db

    -- One line after an update; nothing on a fresh install.
    if old.version and old.version ~= ns.version then ns.say("Updated to " .. ns.version .. ".") end
    ns.db.version = ns.version
end
