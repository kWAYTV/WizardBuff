local _, ns = ...

local grid = {}
ns.grid = grid

-- How a cell looks per state.
--   back: background r, g, b, a      edge: border r, g, b
--   bar:  timer line r, g, b         text: label alpha
--   mark: a small red block on the right, "do this one"
local BLACK = { 0, 0, 0 }
grid.LOOK = {
    missing = { back = { 0.30, 0.08, 0.08, 0.95 }, edge = { 0.85, 0.21, 0.21 }, text = 1, mark = true },
    soon    = { back = { 0.26, 0.16, 0.05, 0.95 }, edge = { 0.94, 0.60, 0.15 }, text = 1, bar = { 0.94, 0.60, 0.15 } },
    has     = { back = { 0.08, 0.08, 0.08, 0.90 }, edge = BLACK, text = 1, bar = { 0.16, 0.56, 0.32 } },
    none    = { back = { 0.08, 0.08, 0.08, 0.90 }, edge = BLACK, text = 0.55 },  -- no mana
    far     = { back = { 0.08, 0.08, 0.08, 0.50 }, edge = BLACK, text = 0.40 },  -- out of range
    gone    = { back = { 0.08, 0.08, 0.08, 0.50 }, edge = BLACK, text = 0.30 },  -- dead or offline
}

grid.RED = { 1, 0.3, 0.3 }
grid.GREEN = { 0.4, 0.9, 0.45 }
grid.ORANGE = { 1, 0.7, 0.25 }
grid.GREY = { 0.6, 0.6, 0.6 }
grid.ARMOR = { 0.60, 0.67, 0.87 }  -- label colour of the armor cell

function grid.classColor(class)
    local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if c then return c.r, c.g, c.b end
    return 0.7, 0.7, 0.7
end
