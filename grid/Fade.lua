local _, ns = ...

-- "Fade when idle": dim while nobody needs a buff, full again when someone
-- does or the mouse is over it. Alpha can change in combat; showing and
-- hiding can't.

local grid = ns.grid
local IDLE = 0.35
local waited = 0

local function update(frame, elapsed)
    waited = waited + elapsed
    if waited < 0.1 then return end
    waited = 0
    local busy = ns.intellect.needed() or ns.armor.needed()
    local alpha = (not ns.db.fade or busy or frame:IsMouseOver()) and 1 or IDLE
    if frame.alpha ~= alpha then
        frame.alpha = alpha
        frame:SetAlpha(alpha)
    end
end

function grid.startFade()
    grid.frame:SetScript("OnUpdate", update)
end
