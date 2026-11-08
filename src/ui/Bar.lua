local _, ns = ...
local UI = ns.UI

-- The icon bar: one secure button per spell (armor, Intellect, Brilliance,
-- shield) with a time sweep, a caption under it and a proc glow when it's
-- time to cast. Plus a hidden "smart" button for the keybind that always
-- casts whatever is needed next.
--
-- Spells and units are bound out of combat only; visuals update anytime.

local GAP = 6
local CAPTION_H = 13

local bar
local slots, order = {}, { "ARMOR", "INT", "BRILL", "SHIELD" }
local smart

---------------------------------------------------------------------------
-- Click tracking: which cast came from which click (for predictions and
-- error messages).
---------------------------------------------------------------------------

local lastClick = { guid = nil, at = 0, unit = nil }

function ns.NoteCastClick(guid, unit)
    lastClick.guid, lastClick.unit, lastClick.at = guid, unit, GetTime()
end

function ns.ClickedWithin(seconds)
    return GetTime() - lastClick.at < seconds
end

function ns.LastCastClick()
    if GetTime() - lastClick.at > 3 then return nil end
    return lastClick.guid, lastClick.unit
end

---------------------------------------------------------------------------
-- Tooltips
---------------------------------------------------------------------------

local function line(text, c)
    c = c or ns.COLORS.muted
    GameTooltip:AddLine(text, c[1], c[2], c[3], true)
end

local function combatNote()
    if InCombatLockdown() then line("In combat: buffs can't be read until the fight ends.", ns.COLORS.warn) end
end

local TOOLTIPS = {
    ARMOR = function(plan)
        local a = plan.armor
        GameTooltip:AddLine(ns.SpellName(a.key) or "Armor", 1, 1, 1)
        if a.left then
            line("Active: " .. ns.FormatTime(a.left) .. " left", a.need and ns.COLORS.warn or ns.COLORS.good)
        else
            line("Not active", ns.COLORS.bad)
        end
        line("Click: cast on yourself")
    end,
    INT = function(plan)
        local p = plan.int
        GameTooltip:AddLine(ns.SpellName("INTELLECT"), 1, 1, 1)
        if p.count > 0 then
            line(p.count .. " of your people need it", ns.COLORS.bad)
            if p.target then
                line("Next: " .. p.target .. (p.outOfRange and " (out of range)" or ""),
                    p.outOfRange and ns.COLORS.warn or ns.COLORS.accent)
            end
        else
            line("Everyone you cover has it", ns.COLORS.good)
            if p.target then line("Click tops up " .. p.target .. " (least time left)") end
        end
        line("Left-click: next target")
        if plan.brill then line("Right-click: " .. ns.SpellName("BRILLIANCE")) end
    end,
    BRILL = function(plan)
        local p = plan.brill
        GameTooltip:AddLine(ns.SpellName("BRILLIANCE"), 1, 1, 1)
        local pc = p.powder == 0 and ns.COLORS.bad or (p.powder <= 5 and ns.COLORS.warn or ns.COLORS.muted)
        line("Arcane Powder: " .. p.powder, pc)
        if p.ready then
            line(p.count .. " in range need Intellect: worth a Brilliance", ns.COLORS.accent)
        else
            line("Glows when " .. (ns.db.brillianceMin or 3) .. " or more in range need Intellect")
        end
        line("Click: cast on your group")
    end,
    SHIELD = function(plan)
        local p = plan.shield
        GameTooltip:AddLine(ns.SpellName(p.key), 1, 1, 1)
        line("Glows when your health is under " .. ns.db.shieldHealth .. "%")
        line("Click: cast on yourself")
    end,
}

local function onEnter(self)
    local plan = ns.plan
    local key = self.key
    if (key == "ARMOR" and not plan.armor) or (key == "INT" and not plan.int)
        or (key == "BRILL" and not plan.brill) or (key == "SHIELD" and not plan.shield) then
        return
    end
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, -4)
    TOOLTIPS[key](plan)
    combatNote()
    GameTooltip:Show()
end

---------------------------------------------------------------------------
-- Slots
---------------------------------------------------------------------------

local NAMES = {
    ARMOR = "WizardBuffArmorButton", INT = "WizardBuffIntButton",
    BRILL = "WizardBuffBrillButton", SHIELD = "WizardBuffShieldButton",
}

local function postClick(self, button, down)
    if not UI.IsCastingClick(down) then return end
    if self.key == "INT" and button ~= "RightButton" then
        local p = ns.plan.int
        ns.NoteCastClick(p and p.guid, p and p.unit)
        if p and p.outOfRange and p.target then ns.Feedback(p.target .. " is out of range") end
    elseif self.key == "BRILL" or button == "RightButton" then
        local b = ns.plan.brill
        if b and b.powder == 0 then ns.Feedback("No Arcane Powder", ns.COLORS.bad) end
        ns.NoteCastClick(nil, b and b.unit)
    else
        ns.NoteCastClick(nil, "player")
    end
end

local function makeSlot(key)
    local b = CreateFrame("Button", NAMES[key], bar, "SecureActionButtonTemplate")
    b.key = key
    UI.RegisterSecureClicks(b)
    UI.Skin(b, { 0, 0, 0, 0.6 }, { 0, 0, 0, 1 })

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.icon = icon

    local cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
    cd:SetPoint("TOPLEFT", 1, -1)
    cd:SetPoint("BOTTOMRIGHT", -1, 1)
    cd:SetDrawEdge(false)
    cd:SetDrawBling(false)
    cd:SetHideCountdownNumbers(true)
    cd:SetSwipeColor(0, 0, 0, 0.7)
    if key == "ARMOR" then cd:SetReverse(true) end
    b.cd = cd

    -- Text sits above the cooldown swipe.
    local over = CreateFrame("Frame", nil, b)
    over:SetAllPoints()
    over:SetFrameLevel(cd:GetFrameLevel() + 2)

    local count = UI.Text(over, 11)
    count:SetPoint("BOTTOMRIGHT", -2, 2)
    b.count = count

    local caption = UI.Text(over, 10)
    caption:SetPoint("TOP", b, "BOTTOM", 0, -2)
    b.caption = caption

    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetPoint("TOPLEFT", 1, -1)
    hl:SetPoint("BOTTOMRIGHT", -1, 1)
    hl:SetColorTexture(1, 1, 1, 0.15)

    b:SetScript("OnEnter", onEnter)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:SetScript("PostClick", postClick)
    b:Hide()
    slots[key] = b
    return b
end

function ns.CreateBar(parent)
    bar = CreateFrame("Frame", nil, parent)
    bar:SetPoint("TOPLEFT")
    for _, key in ipairs(order) do makeSlot(key) end

    slots.ARMOR:SetAttribute("type", "spell")
    slots.ARMOR:SetAttribute("unit", "player")
    slots.INT:SetAttribute("type1", "spell")
    slots.INT:SetAttribute("type2", "spell")
    slots.BRILL:SetAttribute("type", "spell")
    slots.SHIELD:SetAttribute("type", "spell")
    slots.SHIELD:SetAttribute("unit", "player")

    -- Keybind / macro target. Invisible but clickable through bindings.
    smart = CreateFrame("Button", "WizardBuffBuffButton", UIParent, "SecureActionButtonTemplate")
    smart:SetSize(1, 1)
    smart:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -10, 10)
    smart:SetAlpha(0)
    smart:EnableMouse(false)
    UI.RegisterSecureClicks(smart)
    smart:SetAttribute("type1", "spell")
    smart:SetAttribute("type2", "spell")
    smart:SetScript("PostClick", function(_, button, down)
        if not UI.IsCastingClick(down) then return end
        local n = ns.plan.next
        if button == "RightButton" then
            ns.NoteCastClick(nil, ns.plan.brill and ns.plan.brill.unit)
        elseif n then
            ns.NoteCastClick(n.isInt and n.guid or nil, n.unit)
            if n.outOfRange then ns.Feedback(n.target .. " is out of range") end
        end
    end)
    return bar
end

---------------------------------------------------------------------------
-- Binding (out of combat)
---------------------------------------------------------------------------

local function setSpell(btn, spell, unit, suffix)
    suffix = suffix or ""
    btn:SetAttribute("spell" .. suffix, spell)
    if unit ~= false then btn:SetAttribute("unit" .. suffix, unit) end
end

-- Binds every slot to the plan. Out of combat only.
function ns.ApplyBar(plan)
    if InCombatLockdown() or not bar then return end
    local a, i, b, s, n = plan.armor, plan.int, plan.brill, plan.shield, plan.next

    setSpell(slots.ARMOR, a and a.spell, false)
    slots.ARMOR.spellIcon = a and a.spell

    setSpell(slots.INT, i and i.spell, i and i.unit, "1")
    setSpell(slots.INT, b and b.spell, b and b.unit, "2")
    slots.INT.spellIcon = ns.Best("INTELLECT")

    setSpell(slots.BRILL, b and b.spell, b and b.unit)
    slots.BRILL.spellIcon = b and b.spell

    setSpell(slots.SHIELD, s and s.spell, false)
    slots.SHIELD.spellIcon = s and s.spell

    setSpell(smart, n and n.spell, n and n.unit, "1")
    setSpell(smart, b and b.spell, b and b.unit, "2")

    ns.PaintBar()
end

-- Which slots are shown; part of the layout signature.
function ns.BarShape()
    local p = ns.plan
    return (p.armor and "a" or "") .. (p.int and "i" or "") .. (p.brill and "b" or "") .. (p.shield and "s" or "")
end

-- Places the visible slots in a row. Out of combat only. Returns w, h.
function ns.LayoutBar()
    local size = ns.db.iconSize or 36
    local x = 0
    local p = ns.plan
    local want = { ARMOR = p.armor, INT = p.int, BRILL = p.brill, SHIELD = p.shield }
    for _, key in ipairs(order) do
        local b = slots[key]
        if want[key] then
            b:SetSize(size, size)
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", bar, "TOPLEFT", x, 0)
            b:Show()
            x = x + size + GAP
        else
            b:Hide()
        end
    end
    local w = math.max(0, x - GAP)
    bar:SetSize(math.max(w, 1), size + CAPTION_H)
    return w, size + CAPTION_H
end

---------------------------------------------------------------------------
-- Painting (any time)
---------------------------------------------------------------------------

local function caption(b, text, c)
    b.caption:SetText(text or "")
    c = c or ns.COLORS.muted
    b.caption:SetTextColor(c[1], c[2], c[3])
end

-- state: "need" (bright + glow), "ok" (dimmed), "blocked" (grey)
local function look(b, state)
    b.icon:SetTexture(ns.SpellIcon(b.spellIcon))
    b.icon:SetDesaturated(state == "blocked")
    b.icon:SetAlpha(state == "ok" and 0.55 or (state == "blocked" and 0.45 or 1))
    UI.SetProcGlow(b, state == "need")
    local edge = state == "need" and ns.COLORS.glow or { 0, 0, 0 }
    UI.SetEdgeColor(b, edge[1], edge[2], edge[3], 1)
end

local function sweep(b, left, dur)
    if left and dur and dur > 0 then
        local ok = pcall(b.cd.SetCooldown, b.cd, GetTime() - (dur - left), dur)
        if ok then return end
    end
    b.cd:Clear()
end

local function shieldCooldown(spell)
    if not spell or not C_Spell.GetSpellCooldown then return nil end
    local ok, info = pcall(C_Spell.GetSpellCooldown, spell)
    if not ok or type(info) ~= "table" or ns.IsSecret(info) then return nil end
    local start, dur = info.startTime, info.duration
    if ns.IsSecret(start) or ns.IsSecret(dur) or not start or not dur or dur <= 1.5 then return nil end
    return start, dur
end

function ns.PaintBar()
    if not bar then return end
    local plan = ns.plan
    local rebuff = (ns.db.rebuffMinutes or 5) * 60

    local a = plan.armor
    if a then
        local b = slots.ARMOR
        if a.left then
            look(b, a.need and "need" or "ok")
            caption(b, ns.FormatTime(a.left), a.left < rebuff and ns.COLORS.warn or { 1, 1, 1 })
            sweep(b, a.left, a.dur)
        else
            look(b, "need")
            caption(b, InCombatLockdown() and "?" or "off", ns.COLORS.bad)
            sweep(b)
        end
    end

    local i = plan.int
    if i then
        local b = slots.INT
        if i.count > 0 then
            look(b, i.outOfRange and "blocked" or "need")
            caption(b, i.count .. " need", i.outOfRange and ns.COLORS.warn or ns.COLORS.bad)
            b.count:SetText("")
        else
            look(b, "ok")
            caption(b, "done", ns.COLORS.good)
            b.count:SetText("")
        end
    end

    local br = plan.brill
    if br then
        local b = slots.BRILL
        if br.powder == 0 then
            look(b, "blocked")
            caption(b, "no powder", ns.COLORS.bad)
        elseif br.ready then
            look(b, "need")
            caption(b, br.count .. " need", ns.COLORS.bad)
        else
            look(b, "ok")
            caption(b, "")
        end
        b.count:SetText(br.powder)
        local pc = br.powder <= 5 and ns.COLORS.warn or { 1, 1, 1 }
        b.count:SetTextColor(pc[1], pc[2], pc[3])
    end

    local s = plan.shield
    if s then
        local b = slots.SHIELD
        local low = ns.ShieldIsLow()
        local start, dur = shieldCooldown(s.spell)
        if start then
            look(b, "blocked")
            b.cd:SetCooldown(start, dur)
            caption(b, ns.FormatTime(start + dur - GetTime()))
        else
            b.cd:Clear()
            look(b, low and "need" or "ok")
            caption(b, low and "low HP" or "ready", low and ns.COLORS.bad or ns.COLORS.muted)
        end
    end
end
