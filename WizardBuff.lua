-- Wizard Buff: two icons for a mage on WoW Forever.
--   Intellect: how many people near you are missing it. Click to buff the
--              next one (Arcane Brilliance when three or more need it).
--   Armor:     glows when your armor is down. Click to put it back.
--
-- Forever runs the modern client. Three of its rules shape this file:
--   * Buffs are looked up by spell name (C_UnitAuras.GetAuraDataBySpellName).
--     Walking a unit's buff list by index is refused for addons in some
--     situations, and a by-name lookup is not.
--   * While auras are restricted (combat, encounters) a lookup for a buff the
--     game treats as secret returns nothing, exactly like a missing buff. So
--     a buff is only read when C_Secrets says it is readable; otherwise the
--     last reading is kept.
--   * What a button casts can only be changed out of combat.
--
-- How the buffs behave on Forever (differs from Classic in places):
--   * Arcane Intellect lasts an hour. A rank lands on targets up to ten
--     levels below the level it is learned at, never lower.
--   * Arcane Brilliance (level 56) covers the whole raid, not one party.
--   * Any rank, Brilliance, or another caster's Intellect counts as having
--     it: they share two spell names.
--   * A unit that is out of sight reports no buffs at all, so only people in
--     range are judged; the rest are listed as out of range.

local ADDON = ...

BINDING_HEADER_WIZARDBUFF = "Wizard Buff"
_G["BINDING_NAME_CLICK WizardBuffBuffButton:LeftButton"] = "Cast the next buff that is needed"

local _, CLASS = UnitClass("player")
if CLASS ~= "MAGE" then return end

---------------------------------------------------------------------------
-- Spells (ranks lowest first)
---------------------------------------------------------------------------

local INT_RANKS = { 1459, 1460, 1461, 10156, 10157 }
local BRILLIANCE = 23028

-- Level each rank is learned at; it can be cast on targets up to ten levels
-- below that.
local RANK_LEVEL = { [1459] = 1, [1460] = 14, [1461] = 28, [10156] = 42, [10157] = 56, [23028] = 56 }

-- A buff family: every spell that gives the buff. nameIDs are spells whose
-- names cover all of them.
local INTELLECT = {
    ids = { 1459, 1460, 1461, 10156, 10157, 23028 },
    nameIDs = { 1459, 23028 },
}

local ARMORS = {
    { ids = { 168, 7300, 7301 }, nameIDs = { 168 } },            -- Frost Armor
    { ids = { 7302, 7320, 10219, 10220 }, nameIDs = { 7302 } },  -- Ice Armor
    { ids = { 6117, 22782, 22783 }, nameIDs = { 6117 } },        -- Mage Armor
}
local ARMOR_DEFAULT = { 2, 1, 3 }

-- Classes with mana; the others get nothing from Intellect.
local WANTS_INT = {
    DRUID = true, HUNTER = true, MAGE = true, PALADIN = true,
    PRIEST = true, SHAMAN = true, WARLOCK = true,
}

local BRILLIANCE_MIN = 3      -- people needing it before Brilliance is used
local BRILLIANCE_LEVEL = 46   -- lowest level Brilliance can land on
local SOON = 300              -- seconds left at which a timer turns yellow
local SIZE, GAP = 32, 3

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local issecret = issecretvalue or function() return false end

-- The value, or nil when the game hides it.
local function plain(v)
    if not issecret(v) then return v end
end

local function yes(v)
    return not issecret(v) and v and true or false
end

local function isKnown(id)
    if C_SpellBook and C_SpellBook.IsSpellKnown and yes(C_SpellBook.IsSpellKnown(id)) then return true end
    return IsPlayerSpell ~= nil and yes(IsPlayerSpell(id))
end

-- Highest known rank in a list, optionally one that can land on a target of
-- the given level.
local function bestRank(ids, level)
    for i = #ids, 1, -1 do
        local id = ids[i]
        if isKnown(id) and (not level or level <= 0 or level >= (RANK_LEVEL[id] or 1) - 10) then
            return id
        end
    end
end

local function spellName(id)
    return id and plain(C_Spell.GetSpellName(id))
end

-- Brilliance is known and castable (reagent in the bags); being short on
-- mana doesn't count against it.
local function brillianceReady()
    if not isKnown(BRILLIANCE) then return false end
    local usable, noMana = C_Spell.IsSpellUsable(BRILLIANCE)
    return yes(usable) or yes(noMana)
end

local function timeText(sec)
    if not sec then return "" end
    if sec >= 60 then return math.ceil(sec / 60) .. "m" end
    return math.max(0, math.floor(sec)) .. "s"
end

local function say(...)
    print("|cff69ccf0Wizard Buff|r:", ...)
end

---------------------------------------------------------------------------
-- Reading buffs
---------------------------------------------------------------------------

local function restricted()
    local f = C_Secrets and C_Secrets.ShouldAurasBeSecret
    if not f then return InCombatLockdown() end
    local v = f()
    return issecret(v) or (v and true or false)
end

-- Can this family be read right now?
local function readable(fam)
    if not restricted() then return true end
    local f = C_Secrets and C_Secrets.ShouldSpellAuraBeSecret
    if not f then return false end
    for _, id in ipairs(fam.ids) do
        local ok, hidden = pcall(f, id)
        if not ok or issecret(hidden) or hidden ~= false then return false end
    end
    return true
end

local function names(fam)
    if fam.names then return fam.names end
    local list = {}
    for _, id in ipairs(fam.nameIDs) do
        local name = spellName(id)
        if not name then return list end  -- spell data not loaded yet; try again later
        list[#list + 1] = name
    end
    fam.names = list
    return list
end

-- true (plus seconds left, when the buff has a timer), false, or nil when
-- the answer can't be read right now.
local function hasBuff(unit, fam)
    if not readable(fam) then return nil end
    local list = names(fam)
    if #list == 0 then return nil end
    for _, name in ipairs(list) do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataBySpellName, unit, name, "HELPFUL")
        if not ok or issecret(aura) then return nil end
        if aura then
            local expires = plain(aura.expirationTime)
            if expires and expires > 0 then return true, expires - GetTime() end
            return true
        end
    end
    return false
end

local function inRange(unit, spell)
    local r = spell and C_Spell.IsSpellInRange(spell, unit)
    if not issecret(r) and r ~= nil then return r end
    local near, checked = UnitInRange(unit)
    if not issecret(near) and yes(checked) then return near and true or false end
    local visible = UnitIsVisible(unit)
    return issecret(visible) or (visible and true or false)
end

---------------------------------------------------------------------------
-- State: what the last look at the group found
---------------------------------------------------------------------------

local db
local S = {
    missing = {},     -- people in range without Intellect, best target first
    far = {},         -- names of people too far away to judge
    target = nil,     -- who the Intellect button buffs
    topUp = false,    -- nobody is missing it; target is whoever runs out first
    spell = nil,      -- what a left-click casts
    unit = "player",  -- and on whom
    soonest = nil,    -- seconds until the first Intellect near you runs out
    stale = false,    -- Intellect couldn't be read; this is the last reading
    armor = nil,      -- active armor (index into ARMORS), false for none, nil for unknown
    armorLeft = nil,
    idle = false,     -- you can't cast right now (dead, on a flight path)
}

local function groupUnits()
    local list = {}
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local _, _, subgroup = GetRaidRosterInfo(i)
            list[#list + 1] = { unit = "raid" .. i, group = plain(subgroup) or 1 }
        end
    else
        list[1] = { unit = "player", group = 1 }
        for i = 1, GetNumSubgroupMembers() do
            list[#list + 1] = { unit = "party" .. i, group = 1 }
        end
    end
    return list
end

local function lookAtGroup()
    if not readable(INTELLECT) then
        S.stale = true
        return
    end
    local me = UnitGUID("player")
    local rangeSpell = bestRank(INT_RANKS)
    local missing, far, soonest, soonestRec, myGroup = {}, {}, nil, nil, 1

    for _, rec in ipairs(groupUnits()) do
        local unit = rec.unit
        local _, class = UnitClass(unit)
        rec.isMe = plain(UnitGUID(unit)) == me
        if rec.isMe then myGroup = rec.group end
        -- Skipped: gone, offline, dead, classes without mana, and anyone you
        -- can't cast on (mind-controlled, duelling you).
        if yes(UnitExists(unit)) and yes(UnitIsConnected(unit)) and not yes(UnitIsDeadOrGhost(unit))
            and WANTS_INT[plain(class) or ""] and (rec.isMe or yes(UnitCanAssist("player", unit))) then
            rec.name = plain(UnitName(unit)) or unit
            if rec.isMe or inRange(unit, rangeSpell) then
                local has, left = hasBuff(unit, INTELLECT)
                if has == nil then
                    S.stale = true
                    return
                end
                rec.level = plain(UnitLevel(unit)) or 0
                if not has then
                    missing[#missing + 1] = rec
                elseif left and (not soonest or left < soonest) then
                    soonest, soonestRec = left, rec
                end
            else
                far[#far + 1] = rec.name
            end
        end
    end

    -- Yourself, then your own group, then everyone else.
    for i, rec in ipairs(missing) do
        rec.order = (rec.isMe and 0 or rec.group == myGroup and 100 or 200) + i
    end
    table.sort(missing, function(a, b) return a.order < b.order end)

    S.stale = false
    S.missing, S.far, S.soonest = missing, far, soonest
    S.target = missing[1] or soonestRec
    S.topUp = missing[1] == nil
    S.spell, S.unit = nil, "player"

    local t = S.target
    if not t then return end
    -- Brilliance covers the raid, so it is worth it once enough people it
    -- can land on are missing Intellect. It is cast on yourself.
    local need = 0
    for _, rec in ipairs(missing) do
        if rec.level >= BRILLIANCE_LEVEL then need = need + 1 end
    end
    if need >= BRILLIANCE_MIN and brillianceReady() then
        S.spell = BRILLIANCE
    else
        S.spell, S.unit = bestRank(INT_RANKS, t.level), t.unit
    end
end

local function lookAtArmor()
    local unknown
    for i = #ARMORS, 1, -1 do
        local has, left = hasBuff("player", ARMORS[i])
        if has then
            S.armor, S.armorLeft = i, left
            db.armor = i
            return
        end
        if has == nil then unknown = true end
    end
    if not unknown then S.armor, S.armorLeft = false, nil end
end

-- The armor to cast: the one that is up, else the one you used last, else
-- the first you know. Second result: another armor you know, for right-click.
local function armorChoice()
    local line = S.armor or db.armor
    if not (line and bestRank(ARMORS[line].ids)) then
        line = nil
        for _, i in ipairs(ARMOR_DEFAULT) do
            if bestRank(ARMORS[i].ids) then line = i; break end
        end
    end
    if not line then return nil end
    for step = 1, #ARMORS - 1 do
        local other = (line + step - 1) % #ARMORS + 1
        local spell = bestRank(ARMORS[other].ids)
        if spell then return bestRank(ARMORS[line].ids), spell end
    end
    return bestRank(ARMORS[line].ids)
end

---------------------------------------------------------------------------
-- Frames
---------------------------------------------------------------------------

local frame = CreateFrame("Frame", "WizardBuffFrame", UIParent)
frame:SetMovable(true)
frame:SetClampedToScreen(true)

local function place()
    local pos = db.pos
    frame:ClearAllPoints()
    frame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    frame:SetScale(db.scale)
end

-- Sizes are whole screen pixels, the way ElvUI, EllesmereUI and WeakAuras
-- draw: a "1" in UI units is rarely one pixel, and a border that isn't lands
-- between pixels and comes out thick on one side and blurry on the other.
local function pixel()
    local _, height = GetPhysicalScreenSize()
    local scale = frame:GetEffectiveScale()
    if not height or height <= 0 or not scale or scale <= 0 then return 1 end
    return 768 / height / scale
end

local function sharp(texture)
    texture:SetSnapToPixelGrid(false)
    texture:SetTexelSnappingBias(0)
end

-- "Pixel glow": short bright lines running around the icon, as LibCustomGlow
-- draws it for WeakAuras and Hekili. Shown while a cast is needed.
local LINES, LAP = 8, 4  -- lines, seconds per lap

local function makeGlow(parent)
    local g = CreateFrame("Frame", nil, parent)
    g:Hide()
    g.parts, g.at = {}, 0
    for i = 1, LINES * 2 do  -- a line bending round a corner needs two pieces
        local t = g:CreateTexture(nil, "OVERLAY")
        t:SetColorTexture(1, 0.85, 0.3, 1)
        sharp(t)
        g.parts[i] = t
    end

    -- Draws the stretch from a to b (both on one side) of the outline, which
    -- is measured clockwise from the top left corner.
    local function piece(t, a, b, w, h, th)
        if b - a < 0.01 then return t:Hide() end
        t:ClearAllPoints()
        if a < w then
            t:SetPoint("TOPLEFT", g, "TOPLEFT", a, 0)
            t:SetSize(b - a, th)
        elseif a < w + h then
            t:SetPoint("TOPRIGHT", g, "TOPRIGHT", 0, w - a)
            t:SetSize(th, b - a)
        elseif a < 2 * w + h then
            t:SetPoint("BOTTOMRIGHT", g, "BOTTOMRIGHT", w + h - a, 0)
            t:SetSize(b - a, th)
        else
            t:SetPoint("BOTTOMLEFT", g, "BOTTOMLEFT", 0, a - 2 * w - h)
            t:SetSize(th, b - a)
        end
        t:Show()
    end

    g:SetScript("OnUpdate", function(self, elapsed)
        self.at = (self.at + elapsed / LAP) % 1
        local w, h = self:GetSize()
        local th = 2 * pixel()
        local around = 2 * (w + h)
        local length = around / (LINES * 2)
        for i = 1, LINES do
            local a = ((i - 1) / LINES + self.at) % 1 * around
            local b = a + length
            -- The corner this line runs into.
            local corner = (a < w and w) or (a < w + h and w + h) or (a < 2 * w + h and 2 * w + h) or around
            piece(self.parts[2 * i - 1], a, math.min(b, corner), w, h, th)
            if b > corner then
                local from = corner % around
                piece(self.parts[2 * i], from, from + b - corner, w, h, th)
            else
                self.parts[2 * i]:Hide()
            end
        end
    end)
    return g
end

local function makeButton(name, visible)
    local b = CreateFrame("Button", name, visible and frame or UIParent, "SecureActionButtonTemplate")
    b:RegisterForClicks("AnyUp", "AnyDown")
    if not visible then
        -- Only reached through a key binding.
        b:SetSize(1, 1)
        b:SetPoint("TOPRIGHT", UIParent, "TOPLEFT", -50, 50)
        return b
    end

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Border: four strips, each exactly one screen pixel (see fit).
    b.edges = {}
    for i = 1, 4 do
        local t = b:CreateTexture(nil, "OVERLAY", nil, 7)
        t:SetColorTexture(0, 0, 0, 1)
        sharp(t)
        b.edges[i] = t
    end

    local hover = b:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0.12)

    -- Text and glow live on a child frame so they draw over the border.
    local top = CreateFrame("Frame", nil, b)
    top:SetAllPoints()
    b.text = top:CreateFontString(nil, "OVERLAY")
    b.text:SetPoint("TOP", b, "BOTTOM", 0, -2)
    b.count = top:CreateFontString(nil, "OVERLAY")
    b.count:SetPoint("BOTTOMRIGHT", -1, 2)
    b.glow = makeGlow(top)

    -- Alt-drag moves the pair; an Alt-click casts nothing.
    b:SetAttribute("alt-type1", "")
    b:SetAttribute("alt-type2", "")
    b:RegisterForDrag("LeftButton")
    b:SetScript("OnDragStart", function()
        if IsAltKeyDown() and not InCombatLockdown() then frame:StartMoving() end
    end)
    b:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local point, _, relPoint, x, y = frame:GetPoint(1)
        if point then db.pos = { point = point, relPoint = relPoint, x = x, y = y } end
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end

local intButton = makeButton("WizardBuffIntButton", true)
local armorButton = makeButton("WizardBuffArmorButton", true)
local nextButton = makeButton("WizardBuffBuffButton", false)

-- Sizes everything in whole screen pixels. Out of combat only; runs again
-- whenever the pixel size changes (UI scale, resolution, /wb scale).
local fitted, size, gap

local function fit()
    local px = pixel()
    if px == fitted then return end
    fitted = px
    -- SIZE is pixels on a 1080p screen; bigger screens and /wb scale grow it.
    local _, height = GetPhysicalScreenSize()
    local grow = db.scale * math.max(1, (height or 1080) / 1080)
    local function whole(n) return math.floor(n * grow + 0.5) * px end
    size, gap = whole(SIZE), whole(GAP)
    frame:SetSize(size * 2 + gap, size)

    -- The font of the EllesmereUI suite when it is installed, so the text
    -- matches the rest of the screen; the game's own otherwise.
    local font = STANDARD_TEXT_FONT
    if EllesmereUI and EllesmereUI.GetFontPath then
        local ok, path = pcall(EllesmereUI.GetFontPath, "auraBuff")
        if ok and type(path) == "string" and path ~= "" then font = path end
    end

    for _, b in ipairs({ intButton, armorButton }) do
        b:SetSize(size, size)
        local top, bottom, left, right = b.edges[1], b.edges[2], b.edges[3], b.edges[4]
        top:SetPoint("TOPLEFT"); top:SetPoint("TOPRIGHT"); top:SetHeight(px)
        bottom:SetPoint("BOTTOMLEFT"); bottom:SetPoint("BOTTOMRIGHT"); bottom:SetHeight(px)
        left:SetPoint("TOPLEFT"); left:SetPoint("BOTTOMLEFT"); left:SetWidth(px)
        right:SetPoint("TOPRIGHT"); right:SetPoint("BOTTOMRIGHT"); right:SetWidth(px)
        b.glow:SetPoint("TOPLEFT", b, "TOPLEFT", -px, px)
        b.glow:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", px, -px)
        b.text:SetFont(font, whole(11), "OUTLINE")
        b.count:SetFont(font, whole(13), "OUTLINE")
    end
end

-- need: glowing. blocked: grey. count: number in the corner. left: the
-- timer under the icon.
local function paint(b, spell, need, blocked, count, left)
    b.icon:SetTexture(spell and C_Spell.GetSpellTexture(spell) or 134400)
    b.icon:SetDesaturated(blocked and true or false)
    local v = blocked and 0.6 or 1
    b.icon:SetVertexColor(v, v, v)
    b.count:SetText(count or "")
    b.text:SetText(timeText(left))
    if left and left < SOON then b.text:SetTextColor(1, 0.8, 0.2) else b.text:SetTextColor(1, 1, 1) end
    b.glow:SetShown((need and not blocked) and true or false)
end

local function paintAll()
    local count = #S.missing
    local intSpell = bestRank(INT_RANKS)
    if count > 0 then
        local blocked = S.stale or S.idle
        paint(intButton, S.spell or intSpell, not blocked, blocked, count)
    else
        paint(intButton, intSpell, false, S.stale or S.idle, nil, S.soonest)
    end

    local armorSpell = armorChoice()
    if S.armor == false then
        paint(armorButton, armorSpell, not S.idle, S.idle)
    else
        paint(armorButton, armorSpell, false, S.armor == nil or S.idle, nil, S.armorLeft)
    end
end

local function set(b, key, value)
    if b:GetAttribute(key) ~= value then b:SetAttribute(key, value) end
end

-- Points the buttons at what the last look found. Out of combat only.
local function bind()
    fit()
    set(intButton, "type1", "spell")
    set(intButton, "spell1", S.spell)
    set(intButton, "unit1", S.unit)
    set(intButton, "type2", "spell")
    set(intButton, "spell2", isKnown(BRILLIANCE) and BRILLIANCE or nil)
    set(intButton, "unit2", "player")

    local armorSpell, otherArmor = armorChoice()
    set(armorButton, "type1", "spell")
    set(armorButton, "spell1", armorSpell)
    set(armorButton, "unit1", "player")
    set(armorButton, "type2", "spell")
    set(armorButton, "spell2", otherArmor)
    set(armorButton, "unit2", "player")

    -- Key binding: armor first, then whatever the Intellect button would do.
    local armorDown = S.armor == false and armorSpell
    set(nextButton, "type", "spell")
    set(nextButton, "spell", armorDown and armorSpell or (not S.topUp and S.spell or nil))
    set(nextButton, "unit", armorDown and "player" or S.unit)

    local showInt, showArmor = bestRank(INT_RANKS) ~= nil, armorSpell ~= nil
    intButton:SetShown(showInt)
    armorButton:SetShown(showArmor)
    intButton:SetPoint("LEFT", frame, "LEFT", 0, 0)
    armorButton:SetPoint("LEFT", frame, "LEFT", showInt and (size + gap) or 0, 0)
    frame:SetShown(db.shown and (showInt or showArmor))
end

local function refresh()
    S.idle = yes(UnitIsDeadOrGhost("player")) or yes(UnitOnTaxi("player"))
    lookAtGroup()
    lookAtArmor()
    if not InCombatLockdown() then bind() end
    paintAll()
end

---------------------------------------------------------------------------
-- Tooltips
---------------------------------------------------------------------------

local GREY = { 0.6, 0.6, 0.6 }

local function tip(self, title)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:AddLine(title, 1, 1, 1)
end

local function line(text, r, g, b)
    GameTooltip:AddLine(text, r or GREY[1], g or GREY[2], b or GREY[3], true)
end

local function nameList(recs, limit)
    local list = {}
    for i = 1, math.min(#recs, limit) do
        local rec = recs[i]
        list[i] = type(rec) == "table" and rec.name or rec
    end
    if #recs > limit then list[#list + 1] = "+" .. (#recs - limit) end
    return table.concat(list, ", ")
end

intButton:SetScript("OnEnter", function(self)
    local brilliance = spellName(BRILLIANCE) or "Arcane Brilliance"
    tip(self, spellName(INT_RANKS[1]) or "Arcane Intellect")
    local count = #S.missing
    if count > 0 then
        line("Missing on " .. count .. ": " .. nameList(S.missing, 10), 1, 0.3, 0.3)
    elseif S.soonest then
        line("Everyone near you has it. First one runs out in " .. timeText(S.soonest) .. ".", 0.4, 0.9, 0.45)
    else
        line("Everyone near you has it.", 0.4, 0.9, 0.45)
    end
    if #S.far > 0 then line("Out of range: " .. nameList(S.far, 6)) end
    if S.stale then line("Buffs can't be read in combat; this is the last reading.", 1, 0.7, 0.25) end
    local t = S.target
    if t and S.spell == BRILLIANCE then
        line("Left-click: " .. brilliance .. " on everyone")
    elseif t and S.spell then
        line("Left-click: " .. (S.topUp and "refresh " or "buff ") .. (t.isMe and "yourself" or t.name))
    end
    if isKnown(BRILLIANCE) then
        line("Right-click: " .. brilliance .. (brillianceReady() and "" or " (can't be cast right now)"))
    end
    line("Alt-drag to move")
    GameTooltip:Show()
end)

armorButton:SetScript("OnEnter", function(self)
    local spell, other = armorChoice()
    tip(self, spellName(spell) or "Armor")
    if S.armor == false then
        line("Not active", 1, 0.3, 0.3)
    elseif S.armor == nil then
        line("Can't be read right now", 1, 0.7, 0.25)
    elseif S.armorLeft then
        line(timeText(S.armorLeft) .. " left", 0.4, 0.9, 0.45)
    else
        line("Active", 0.4, 0.9, 0.45)
    end
    line("Left-click: cast")
    if other then line("Right-click: switch to " .. (spellName(other) or "another armor")) end
    line("Alt-drag to move")
    GameTooltip:Show()
end)

---------------------------------------------------------------------------
-- Driver: look again shortly after anything changes, and once a second
-- regardless (ranges and timers move without events).
---------------------------------------------------------------------------

local driver = CreateFrame("Frame")
local dirty, waited = true, 0

local function onUpdate(_, elapsed)
    waited = waited + elapsed
    if waited >= 1 or (dirty and waited >= 0.2) then
        waited, dirty = 0, false
        refresh()
    end
end

driver:SetScript("OnEvent", function(self, event, arg)
    if event == "ADDON_LOADED" then
        if arg ~= ADDON then return end
        local old = type(WizardBuffDB) == "table" and WizardBuffDB or {}
        local pos = type(old.pos) == "table" and old.pos or {}
        -- Rebuilt from the few keys still used, so settings of older
        -- versions don't pile up in the saved file.
        db = {
            shown = old.shown ~= false and old.enabled ~= false,
            scale = tonumber(old.scale) or 1,
            armor = ARMORS[old.armor] and old.armor or nil,
            pos = {
                point = pos.point or "CENTER", relPoint = pos.relPoint or "CENTER",
                x = tonumber(pos.x) or 0, y = tonumber(pos.y) or -180,
            },
        }
        WizardBuffDB = db
        place()
    elseif event == "PLAYER_LOGIN" then
        for _, e in ipairs({
            "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE", "UNIT_AURA", "UNIT_CONNECTION",
            "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "SPELLS_CHANGED", "BAG_UPDATE_DELAYED",
        }) do
            self:RegisterEvent(e)
        end
        self:SetScript("OnUpdate", onUpdate)
    elseif event == "UNIT_AURA" then
        -- Fires for every unit in sight; only the group matters.
        local unit = plain(arg)
        if unit == "player" or (unit and (unit:find("^party%d") or unit:find("^raid%d"))) then dirty = true end
    else
        dirty = true
    end
end)
driver:RegisterEvent("ADDON_LOADED")
driver:RegisterEvent("PLAYER_LOGIN")

---------------------------------------------------------------------------
-- /wb
---------------------------------------------------------------------------

local function show(v)
    if issecret(v) then return "<secret>" end
    return tostring(v)
end

-- What the game answers, for bug reports.
local function debug()
    say("debug")
    print("  in combat:", show(InCombatLockdown()), " auras restricted:", show(restricted()))
    local function family(label, fam)
        local known = {}
        for _, id in ipairs(fam.ids) do
            if isKnown(id) then known[#known + 1] = id end
        end
        print(string.format("  %s: names [%s], known ranks [%s], readable %s", label,
            table.concat(names(fam), ", "), table.concat(known, ", "), show(readable(fam))))
    end
    family("Intellect", INTELLECT)
    for i, fam in ipairs(ARMORS) do family("Armor " .. i, fam) end
    for _, rec in ipairs(groupUnits()) do
        local unit = rec.unit
        local _, class = UnitClass(unit)
        local has, left = hasBuff(unit, INTELLECT)
        local byIndex = pcall(C_UnitAuras.GetAuraDataByIndex, unit, 1, "HELPFUL")
        print(string.format("  %s %s (%s, group %d): Intellect %s %s, in range %s, list readable %s",
            unit, show(UnitName(unit)), show(class), rec.group, show(has), timeText(left),
            show(inRange(unit, bestRank(INT_RANKS))), show(byIndex)))
    end
    print("  armor:", show(S.armor), timeText(S.armorLeft), " remembered:", show(db.armor))
    print("  Intellect button casts", show(intButton:GetAttribute("spell1")), "on", show(intButton:GetAttribute("unit1")))
end

SLASH_WIZARDBUFF1, SLASH_WIZARDBUFF2, SLASH_WIZARDBUFF3 = "/wb", "/wbuff", "/wizardbuff"
SlashCmdList.WIZARDBUFF = function(msg)
    local cmd, arg = strsplit(" ", strlower(strtrim(msg or "")), 2)
    if cmd == "debug" then
        return debug()
    elseif cmd ~= "" and cmd ~= "reset" and cmd ~= "scale" then
        return say("/wb to show or hide, /wb scale 1.2, /wb reset to bring it back to the middle, /wb debug. "
            .. "Alt-drag an icon to move it.")
    end
    if InCombatLockdown() then return say("Not in combat. Try again after the fight.") end
    if cmd == "reset" then
        db.pos = { point = "CENTER", relPoint = "CENTER", x = 0, y = -180 }
        db.scale, db.shown = 1, true
    elseif cmd == "scale" then
        local n = tonumber(arg)
        if not n then return say("Give a number, like /wb scale 1.2") end
        db.scale = math.min(3, math.max(0.5, n))
    else
        db.shown = not db.shown
        say(db.shown and "Shown." or "Hidden. /wb shows it again.")
    end
    place()
    refresh()
end
