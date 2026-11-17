local _, ns = ...

local grid = {}
ns.grid = grid

-- How a cell looks per state.
--   back: background in the frames layout     edge: its border
--   bar:  the timer line                      text: label alpha
--   row:  background in the list layout       side: colour of the right-hand text
--   mark: flag it as "do this one"            word: right-hand text in the list
local BLACK, CLEAR = { 0, 0, 0 }, { 0, 0, 0, 0 }
local RED, ORANGE, GREEN, GREY = { 0.85, 0.21, 0.21 }, { 0.94, 0.60, 0.15 }, { 0.16, 0.56, 0.32 }, { 0.6, 0.6, 0.6 }
grid.LOOK = {
    missing = { back = { 0.30, 0.08, 0.08, 0.95 }, edge = RED, text = 1, mark = RED,
                row = { 0.85, 0.21, 0.21, 0.25 }, side = { 1, 0.4, 0.4 }, word = "missing" },
    soon    = { back = { 0.26, 0.16, 0.05, 0.95 }, edge = ORANGE, text = 1, bar = ORANGE, mark = ORANGE,
                row = { 0.94, 0.60, 0.15, 0.20 }, side = { 1, 0.75, 0.35 } },
    has     = { back = { 0.08, 0.08, 0.08, 0.90 }, edge = BLACK, text = 1, bar = GREEN,
                row = CLEAR, side = { 0.55, 0.85, 0.6 } },
    none    = { back = { 0.08, 0.08, 0.08, 0.90 }, edge = BLACK, text = 0.55, row = CLEAR, side = GREY },
    far     = { back = { 0.08, 0.08, 0.08, 0.50 }, edge = BLACK, text = 0.40, row = CLEAR, side = GREY, word = "far" },
    skip    = { back = { 0.08, 0.08, 0.08, 0.50 }, edge = BLACK, text = 0.40, row = CLEAR, side = GREY, word = "skip" },  -- ignored
    gone    = { back = { 0.08, 0.08, 0.08, 0.50 }, edge = BLACK, text = 0.30, row = CLEAR, side = GREY, word = "gone" },
}

grid.RED = { 1, 0.3, 0.3 }
grid.GREEN = { 0.4, 0.9, 0.45 }
grid.ORANGE = { 1, 0.7, 0.25 }
grid.GREY = GREY
grid.ARMOR = { 0.60, 0.67, 0.87 }  -- label colour of the armor cell

function grid.classColor(class)
    local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if c then return c.r, c.g, c.b end
    return 0.7, 0.7, 0.7
end
