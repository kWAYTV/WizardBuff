local _, ns = ...

local grid = ns.grid

-- Puts the cells in place: `first` (the armor cell, may be nil) on the left,
-- then one row of member cells per entry in `rows`. Every cell is the same
-- size. Cells not mentioned are hidden. Out of combat only.
function grid.layout(first, rows, visible)
    local frame = grid.frame
    local stepX, stepY = grid.width + grid.gap, grid.height + grid.gap
    local placed = {}

    local function put(cell, x, y)
        cell:ClearAllPoints()
        cell:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -y)
        cell:SetSize(grid.width, grid.height)
        cell:Show()
        placed[cell] = true
    end

    local indent = 0
    if first then
        put(first, 0, 0)
        indent = stepX
    end

    local widest = 0
    for r, row in ipairs(rows) do
        for c, cell in ipairs(row) do
            put(cell, indent + (c - 1) * stepX, (r - 1) * stepY)
        end
        widest = math.max(widest, #row)
    end

    for _, cell in ipairs(grid.all) do
        if not placed[cell] then cell:Hide() end
    end

    local width = math.max(grid.width, indent + widest * stepX - grid.gap)
    frame:SetSize(width, math.max(grid.height, #rows * stepY - grid.gap))
    grid.fitHandle(width)
    frame:SetShown(visible and true or false)
end
