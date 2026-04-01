local _, ns = ...

local CLASS_ORDER = ns.CLASS_ORDER
local ICON_SIZE   = ns.ICON_SIZE
local ICON_GAP    = ns.ICON_GAP

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
function ns.ClearSecureSpell(btn)
    if not btn then return end
    btn:SetAttribute("type", nil)
    btn:SetAttribute("spell", nil)
    btn:SetAttribute("unit", nil)
    btn:SetAttribute("macrotext", nil)
end

function ns.HideUnusedGridCells(startIdx)
    local cells = ns.gridCells
    if not cells then return end
    for i = startIdx, #cells do
        ns.ClearSecureSpell(cells[i])
        cells[i]:Hide()
    end
end

---------------------------------------------------------------------------
-- Build flat player list from roster, ordered by CLASS_ORDER
---------------------------------------------------------------------------
function ns.BuildGridPlayers()
    local roster = ns.roster
    local out = {}
    for _, class in ipairs(CLASS_ORDER) do
        local players = roster[class]
        if players then
            for _, p in ipairs(players) do
                out[#out + 1] = {
                    name      = p.name,
                    unit      = p.unit,
                    class     = class,
                    needsInt  = p.needsInt,
                    ownerName = p.ownerName,
                }
            end
        end
    end
    return out
end

---------------------------------------------------------------------------
-- Layout grid cells and resize main frame
---------------------------------------------------------------------------
function ns.LayoutGrid(gridPlayers, intToUse, needN)
    local db        = ns.db
    local mainFrame = ns.mainFrame
    local BAR_H     = ns.UI_BAR_H
    local BAR_W     = ns.UI_FRAME_W
    local showNeed  = db.showHudNeedCount

    if not db.showClassRows then
        ns.HideUnusedGridCells(1)
        if mainFrame.needLine then mainFrame.needLine:SetText("") end
        ns.autoBuffButton:ClearAllPoints()
        ns.autoBuffButton:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 2, -2)
        mainFrame:SetSize(BAR_W, BAR_H)
        mainFrame:Show()
        ns.ApplyHudFade()
        return
    end

    local CW      = ns.GRID_CELL_W
    local CH      = ns.GRID_CELL_H
    local CG      = ns.GRID_GAP
    local PER_ROW = ns.GRID_PER_ROW

    if not ns.gridCells then ns.gridCells = {} end

    local cols    = math.min(#gridPlayers, PER_ROW)
    local gridPxW = cols > 0 and (cols * CW + (cols - 1) * CG) or 0
    local iconPairW = ICON_SIZE * 2 + ICON_GAP
    local FRAME_W   = math.max(iconPairW + 4, gridPxW + 4)

    local xPad = math.max(2, math.floor((FRAME_W - iconPairW) / 2))
    ns.autoBuffButton:ClearAllPoints()
    ns.autoBuffButton:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", xPad, -2)

    local yAfterIcons = -(2 + ICON_SIZE + 2)

    if showNeed and mainFrame.needLine then
        local needH = 10
        mainFrame.needLine:ClearAllPoints()
        mainFrame.needLine:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 2, yAfterIcons)
        mainFrame.needLine:SetPoint("RIGHT", mainFrame, "RIGHT", -2, 0)
        mainFrame.needLine:SetJustifyH("CENTER")
        mainFrame.needLine:SetText(
            needN > 0
                and ("|cffff7777" .. needN .. "|r |cff555555need|r")
                or  "|cff448844ok|r"
        )
        yAfterIcons = yAfterIcons - needH
    elseif mainFrame.needLine then
        mainFrame.needLine:SetText("")
    end

    local gridYStart = yAfterIcons - 1
    local gridXStart = math.max(2, math.floor((FRAME_W - gridPxW) / 2))
    local maxRow     = 0

    for i, p in ipairs(gridPlayers) do
        if not ns.gridCells[i] then
            ns.gridCells[i] = ns.CreateGridCell(i)
        end
        local cell = ns.gridCells[i]
        local col  = (i - 1) % PER_ROW
        local row  = math.floor((i - 1) / PER_ROW)
        if row > maxRow then maxRow = row end

        cell:ClearAllPoints()
        cell:SetPoint("TOPLEFT", mainFrame, "TOPLEFT",
            gridXStart + col * (CW + CG),
            gridYStart - row * (CH + CG))

        cell.classColor = ns.CLASS_COLORS[p.class] or { 0.5, 0.5, 0.5 }
        cell.playerName = p.name
        cell.needsInt   = p.needsInt
        cell.ownerName  = p.ownerName
        cell.initial:SetText(p.name:sub(1, 1):upper())

        ns.ApplyGridCellColor(cell)

        if intToUse then
            cell:SetAttribute("type", "spell")
            cell:SetAttribute("spell", intToUse)
            cell:SetAttribute("unit", p.unit)
            cell:SetAttribute("macrotext", nil)
        else
            ns.ClearSecureSpell(cell)
        end

        cell:Show()
    end

    ns.HideUnusedGridCells(#gridPlayers + 1)

    local rows   = maxRow + 1
    local gridH  = rows > 0 and (rows * CH + (rows - 1) * CG) or 0
    local totalH = -gridYStart + gridH + 2
    mainFrame:SetSize(FRAME_W, totalH)
    mainFrame:Show()
    ns.ApplyHudFade()
end
