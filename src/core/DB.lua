local _, ns = ...

ns.DB_VERSION = 2

ns.defaults = {
    dbVersion      = ns.DB_VERSION,
    enabled        = true,
    showSolo       = true,
    locked         = false,
    scale          = 1.0,
    alpha          = 1.0,
    combatAlpha    = 0.6,
    layout         = "rows",      -- rows: one row per raid group; columns: one column per group
    iconSize       = 36,
    cellWidth      = 64,
    cellHeight     = 18,
    showPets       = true,

    armor          = "auto",      -- auto | mage | ice | frost | none
    shield         = "auto",      -- auto | barrier | mana | none
    shieldHealth   = 60,
    useBrilliance  = true,
    brillianceMin  = 3,
    rebuffMinutes  = 5,
    shiftClick     = "dampen",    -- none | dampen | amplify | intellect | brilliance
    ctrlClick      = "amplify",

    glow           = true,
    sound          = false,
    readyCheck     = true,
    coordinate     = true,

    minimap        = { hide = false, angle = 215 },
    pos            = nil,
}

local function fill(dst, src)
    for k, v in pairs(src) do
        if dst[k] == nil then
            if type(v) == "table" then
                dst[k] = {}
                fill(dst[k], v)
            else
                dst[k] = v
            end
        elseif type(v) == "table" and type(dst[k]) == "table" then
            fill(dst[k], v)
        end
    end
end

function ns.LoadDB()
    local db = _G.WizardBuffDB
    -- Old AceDB data (profiles) is not compatible; start fresh.
    -- 2.0.0 settings predate the icon bar; start over.
    if type(db) ~= "table" or db.profiles or db.profileKeys or db.dbVersion ~= ns.DB_VERSION then
        db = {}
    end
    fill(db, ns.defaults)
    _G.WizardBuffDB = db
    ns.db = db
end

-- Reset in place: the Settings panel holds a reference to this table.
function ns.ResetDB()
    wipe(ns.db)
    fill(ns.db, ns.defaults)
    ns.Fire("SETTINGS_CHANGED")
end
