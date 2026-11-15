local _, ns = ...

-- Forever hides some values from addons ("secrets"). Comparing one throws,
-- so everything read from the game goes through these first.

local issecret = issecretvalue or function() return false end

ns.isSecret = issecret

-- The value, or nil if hidden.
function ns.plain(v)
    if not issecret(v) then return v end
end

-- True only for a visible, truthy value.
function ns.yes(v)
    return not issecret(v) and v and true or false
end
