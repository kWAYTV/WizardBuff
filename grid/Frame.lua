local _, ns = ...

-- The holder all cells sit in: position, scale, pixel sizes, font.

local grid = ns.grid
local WIDTH, HEIGHT, GAP, FONT = 76, 20, 1, 10  -- pixels on a 1080p screen
local frame, fitted

grid.all = {}  -- every cell

function grid.createFrame()
    frame = CreateFrame("Frame", "WizardBuffFrame", UIParent)
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    grid.frame = frame
end

-- Out of combat only.
function grid.place()
    local pos = ns.db.pos
    frame:ClearAllPoints()
    frame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
end

function grid.savePosition()
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

-- Works out sizes in whole pixels and refits the cells. Out of combat only;
-- cheap when nothing changed (UI scale, resolution, size setting).
function grid.fit()
    if frame:GetScale() ~= ns.db.scale then frame:SetScale(ns.db.scale) end
    local px = ns.pixel.size(frame)
    if px ~= fitted then
        fitted = px
        local _, height = GetPhysicalScreenSize()
        local grow = ns.db.scale * math.max(1, (height or 1080) / 1080)
        local function whole(n) return math.max(1, math.floor(n * grow + 0.5)) * px end
        grid.px, grid.width, grid.height, grid.gap = px, whole(WIDTH), whole(HEIGHT), whole(GAP)
        grid.font, grid.fontSize = font(), whole(FONT)
        for _, cell in ipairs(grid.all) do cell.fitted = nil end
    end
    for _, cell in ipairs(grid.all) do
        if cell.fitted ~= px then
            cell.fitted = px
            grid.fitCell(cell)
        end
    end
end
