local _, ns = ...

local function lastIcon()
    if ns.shieldButton and ns.shieldButton:IsShown() then return ns.shieldButton end
    return ns.brillianceButton
end

local function setNeedText(mf, needN, allOOR)
    if not mf.needLine then return 0 end
    if not ns.db.showHudNeedCount then
        mf.needLine:SetText("")
        return 0
    end
    local parts = {}
    if needN > 0 then
        parts[#parts + 1] = allOOR and ("|cffffaa44" .. needN .. "|r") or ("|cffff7777" .. needN .. "|r")
    elseif ns.SelfNeedsArmor() then
        parts[#parts + 1] = "|cffffaa44self|r"
    end
    local powderN = ns.GetArcanePowderCount()
    parts[#parts + 1] = "|cff" .. ns.PowderColorHex(powderN) .. powderN .. "|r"
    mf.needLine:SetText(table.concat(parts, "\n"))
    mf.needLine:ClearAllPoints()
    mf.needLine:SetPoint("LEFT", lastIcon(), "RIGHT", 4, 0)
    return ns.STATUS_W
end

function ns.LayoutGrid(gridPlayers, preferBrill, needN, allOOR)
    local db, mf = ns.db, ns.mainFrame
    local gripW = (ns.handle and ns.handle:IsShown()) and ns.GRIP_W or 0
    local nIcons = (ns.shieldButton and ns.shieldButton:IsShown()) and 3 or 2
    local iconRowW = gripW + ns.ICON_SIZE * nIcons + ns.ICON_GAP * (nIcons - 1)
    local labelH = 10

    ns.PlaceHudIcons(mf, gripW)
    local statusW = setNeedText(mf, needN, allOOR)

    if not db.showClassRows then
        ns.HideUnusedGridCells(1)
        mf:SetSize(iconRowW + statusW, ns.ICON_SIZE + labelH)
        mf:Show()
        ns.ApplyHudFade()
        return
    end

    local CW, CH, CG = ns.GRID_CELL_W, ns.GRID_CELL_H, ns.GRID_GAP
    local PER_ROW = db.gridColumns or ns.GRID_PER_ROW
    ns.gridCells = ns.gridCells or {}

    local cols = math.min(#gridPlayers, PER_ROW)
    local gridPxW = cols > 0 and (cols * CW + (cols - 1) * CG) or 0
    local FRAME_W = math.max(iconRowW + statusW, gripW + gridPxW)
    local gridY = -(ns.ICON_SIZE + labelH + ns.ICON_GAP)
    local maxRow = 0

    for i, p in ipairs(gridPlayers) do
        if not ns.gridCells[i] then ns.gridCells[i] = ns.CreateGridCell(i) end
        local cell = ns.gridCells[i]
        local col = (i - 1) % PER_ROW
        local row = math.floor((i - 1) / PER_ROW)
        if row > maxRow then maxRow = row end

        cell:ClearAllPoints()
        cell:SetPoint("TOPLEFT", mf, "TOPLEFT", gripW + col * (CW + CG), gridY - row * (CH + CG))
        cell.classColor = ns.CLASS_COLORS[p.class] or { 0.5, 0.5, 0.5 }
        cell.playerName = p.name
        cell.needsInt = p.needsInt
        cell.ownerName = p.ownerName
        cell.isDead = p.isDead
        cell.isOffline = p.isOffline
        cell.outOfRange = p.unit and not ns.IsUnitInBuffRange(p.unit) or false
        cell.hasStrongerBrill = p.hasStrongerBrill
        cell.buffRemaining = p.buffRemaining
        cell.initial:SetText(p.name:sub(1, 1):upper())
        ns.ApplyGridCellColor(cell)

        if p.needsInt and not p.isDead and not p.isOffline and not cell.outOfRange then
            local spell = ns.GetIntSpellForUnit(p.unit, preferBrill)
            if spell then
                ns.BindSecureSpell(cell, spell, p.unit)
            else
                ns.ClearSecureSpell(cell)
            end
        else
            ns.ClearSecureSpell(cell)
        end
        cell:Show()
    end
    ns.HideUnusedGridCells(#gridPlayers + 1)

    local rows = #gridPlayers > 0 and (maxRow + 1) or 0
    local gridH = rows > 0 and (ns.ICON_GAP + rows * CH + (rows - 1) * CG) or 0
    mf:SetSize(FRAME_W, ns.ICON_SIZE + labelH + gridH)
    mf:Show()
    ns.ApplyHudFade()
end
