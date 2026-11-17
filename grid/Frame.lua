local _, ns = ...

-- The holder all cells sit in: position, scale, pixel sizes, font, and the
-- dark plate the list layout draws on.

local grid = ns.grid
local FONT = 10  -- pixels on a 1080p screen
local frame, fitted

grid.all = {}  -- every cell

function grid.createFrame()
    frame = CreateFrame("Frame", "WizardBuffFrame", UIParent)
    frame:SetSize(64, 16)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)

    frame.plate = frame:CreateTexture(nil, "BACKGROUND")
    frame.plate:SetAllPoints()
    frame.plate:SetColorTexture(0.05, 0.05, 0.05, 0.85)
    frame.edges = {}
    for i = 1, 4 do
        local edge = frame:CreateTexture(nil, "BORDER")
        edge:SetColorTexture(0, 0, 0, 1)
        ns.pixel.sharp(edge)
        frame.edges[i] = edge
    end
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

-- Picks the layout, works out sizes in whole pixels and refits the cells.
-- Out of combat only; cheap when nothing changed.
function grid.fit()
    if frame:GetScale() ~= ns.db.scale then frame:SetScale(ns.db.scale) end
    local style = grid.styles[ns.db.layout] or grid.styles.list
    local px = ns.pixel.size(frame)
    local key = px .. ns.db.layout
    if key ~= fitted then
        fitted = key
        local _, height = GetPhysicalScreenSize()
        local grow = ns.db.scale * math.max(1, (height or 1080) / 1080)
        local function whole(n) return math.floor(n * grow + 0.5) * px end
        grid.style, grid.px = style, px
        grid.width, grid.height, grid.gap = whole(style.WIDTH), whole(style.HEIGHT), whole(style.GAP)
        grid.font, grid.fontSize = font(), whole(FONT)

        grid.fitEdges(frame.edges, px)
        frame.plate:SetShown(style.plate and true or false)
        for _, edge in ipairs(frame.edges) do edge:SetShown(style.plate and true or false) end
        for _, cell in ipairs(grid.all) do cell.fitted = nil end
    end
    for _, cell in ipairs(grid.all) do
        if cell.fitted ~= key then
            cell.fitted = key
            cell.label:SetFont(grid.font, grid.fontSize, "OUTLINE")
            cell.side:SetFont(grid.font, grid.fontSize, "OUTLINE")
            style.fitCell(cell)
        end
    end
end

-- One cell at an offset from the holder's top left corner.
function grid.put(cell, x, y)
    cell:ClearAllPoints()
    cell:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -y)
    cell:SetSize(grid.width, grid.height)
    cell:Show()
end

-- Lays the cells out in the current layout and hides the rest. first: the
-- armor cell (may be nil). rows: member cells. Out of combat only.
function grid.layout(first, rows, visible)
    local placed, width, height = grid.style.layout(first, rows)
    for _, cell in ipairs(grid.all) do
        if not placed[cell] then cell:Hide() end
    end
    frame:SetSize(width, height)
    grid.fitHandle(width)
    frame:SetShown(visible and true or false)
end
