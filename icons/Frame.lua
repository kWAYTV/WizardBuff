local _, ns = ...

-- The holder both icons sit in: position, scale, pixel sizes, who shows.

local icons = ns.icons
local SIZE, GAP = 32, 3  -- pixels on a 1080p screen
local frame, fitted, size, gap

icons.all = {}

function icons.createFrame()
    frame = CreateFrame("Frame", "WizardBuffFrame", UIParent)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    icons.frame = frame
end

-- Out of combat only.
function icons.place()
    local pos = ns.db.pos
    frame:ClearAllPoints()
    frame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
end

function icons.savePosition()
    local point, _, relPoint, x, y = frame:GetPoint(1)
    if point then ns.db.pos = { point = point, relPoint = relPoint, x = x, y = y } end
end

local function font()
    -- EllesmereUI's font when that suite is installed, so text matches it.
    if EllesmereUI and EllesmereUI.GetFontPath then
        local ok, path = pcall(EllesmereUI.GetFontPath, "auraBuff")
        if ok and type(path) == "string" and path ~= "" then return path end
    end
    return STANDARD_TEXT_FONT
end

-- Sizes everything in whole pixels. Out of combat only; cheap when nothing
-- changed (UI scale, resolution, size setting).
function icons.fit()
    if frame:GetScale() ~= ns.db.scale then frame:SetScale(ns.db.scale) end
    local px = ns.pixel.size(frame)
    if px == fitted then return end
    fitted = px

    local _, height = GetPhysicalScreenSize()
    local grow = ns.db.scale * math.max(1, (height or 1080) / 1080)
    local function whole(n) return math.floor(n * grow + 0.5) * px end
    size, gap = whole(SIZE), whole(GAP)
    frame:SetSize(size * 2 + gap, size)

    local path = font()
    for _, button in ipairs(icons.all) do
        button:SetSize(size, size)
        icons.fitBorder(button, px)
        button.text:SetFont(path, whole(11), "OUTLINE")
        button.count:SetFont(path, whole(13), "OUTLINE")
    end
end

-- Lines the shown icons up left to right. Out of combat only.
function icons.arrange(visible)
    local x, any = 0, false
    for _, button in ipairs(icons.all) do
        local show = visible[button] and true or false
        button:SetShown(show)
        if show then
            button:SetPoint("LEFT", frame, "LEFT", x, 0)
            x = x + size + gap
            any = true
        end
    end
    local resting = ns.db.hideResting and IsResting()
    frame:SetShown(ns.db.shown and any and not resting)
end
