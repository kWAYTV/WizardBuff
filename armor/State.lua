local _, ns = ...

local armor = ns.armor

-- up: index into armor.lines, false for none, nil for can't tell.
armor.found = { up = nil, left = nil, total = nil }

function armor.scan()
    local found, unknown = armor.found, false
    for line = #armor.lines, 1, -1 do
        local has, left, total = ns.auras.has("player", armor.lines[line])
        if has then
            found.up, found.left, found.total = line, left, total
            ns.db.armor = line  -- remembered: this is the one to recast
            return
        end
        if has == nil then unknown = true end
    end
    if not unknown then found.up, found.left, found.total = false, nil, nil end
end

-- Down, or about to be.
function armor.needed()
    local found = armor.found
    return found.up == false or (found.left ~= nil and found.left < ns.db.remind * 60)
end

-- The spell to cast: the armor that's up, else the last one you used, else
-- the first you know. Second result: another armor, for right-click.
function armor.choice()
    local line = armor.found.up or ns.db.armor
    if not (line and armor.rank(line)) then
        line = nil
        for _, candidate in ipairs(armor.fallback) do
            if armor.rank(candidate) then line = candidate; break end
        end
    end
    if not line then return nil end
    for step = 1, #armor.lines - 1 do
        local other = armor.rank((line + step - 1) % #armor.lines + 1)
        if other then return armor.rank(line), other end
    end
    return armor.rank(line)
end
