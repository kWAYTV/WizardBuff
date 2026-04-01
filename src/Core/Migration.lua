local _, ns = ...

function ns.MigrateLegacy(addon)
    local old = _G.MagePowerDB
    if not old or type(old) ~= "table" or addon.db.profile.migratedFromMagePower then
        return
    end
    for k, _ in pairs(ns.defaults) do
        if k ~= "migratedFromMagePower" and k ~= "minimap" and old[k] ~= nil then
            addon.db.profile[k] = old[k]
        end
    end
    if old.minimap and type(old.minimap) == "table" then
        addon.db.profile.minimap.hide = old.minimap.hide and true or false
    end
    addon.db.profile.migratedFromMagePower = true
end
