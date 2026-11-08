local _, ns = ...
local UI = ns.UI

-- The two big HUD buttons. Their spells are set out of combat; in combat
-- they keep the last setup (Blizzard forbids changing secure attributes).

local SIZE = 34

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

local function makeButton(name, parent)
    local b = CreateFrame("Button", name, parent, "SecureActionButtonTemplate")
    b:SetSize(SIZE, SIZE)
    UI.RegisterSecureClicks(b)
    UI.Skin(b, { 0, 0, 0, 0.7 })

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    b.icon = icon

    local timer = UI.Text(b, 10)
    timer:SetPoint("BOTTOM", 0, 2)
    b.timer = timer

    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.15)

    UI.AddGlow(b)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end

local function tooltipLine(text, c)
    c = c or ns.COLORS.muted
    GameTooltip:AddLine(text, c[1], c[2], c[3], true)
end

function ns.CreateBuffButton(parent)
    local b = makeButton("WizardBuffBuffButton", parent)
    b:SetAttribute("type1", "spell")
    b:SetAttribute("type2", "spell")

    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Buff", 1, 1, 1)
        local buff = ns.plan.buff
        if buff then
            tooltipLine(buff.label .. "  >  " .. buff.target, ns.COLORS.accent)
            if buff.outOfRange then tooltipLine("Out of range: move closer", ns.COLORS.warn) end
        else
            tooltipLine("Everyone you cover is buffed", ns.COLORS.good)
        end
        if InCombatLockdown() then tooltipLine("In combat: target updates after the fight", ns.COLORS.warn) end
        tooltipLine("Left-click: next buff  ·  Right-click: Arcane Brilliance")
        GameTooltip:Show()
    end)

    b:SetScript("PostClick", function(self, button, down)
        if not UI.IsCastingClick(down) then return end
        local buff = ns.plan.buff
        if button == "RightButton" then
            ns.NoteCastClick(nil, self:GetAttribute("unit2"))
        elseif buff and buff.isInt then
            ns.NoteCastClick(buff.guid, buff.unit)
        else
            ns.NoteCastClick(nil, "player")
        end
    end)
    ns.buffButton = b
    return b
end

function ns.CreateShieldButton(parent)
    local b = makeButton("WizardBuffShieldButton", parent)
    b:SetAttribute("type", "spell")
    b:SetAttribute("unit", "player")
    b:SetScript("PostClick", function(_, _, down)
        if UI.IsCastingClick(down) then ns.NoteCastClick(nil, "player") end
    end)

    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Shield", 1, 1, 1)
        local s = ns.plan.shield
        if s then
            tooltipLine(s.label, ns.COLORS.accent)
            tooltipLine("Glows when your health drops below " .. ns.db.shieldHealth .. "%")
        else
            tooltipLine("No shield spell known or shield is turned off")
        end
        GameTooltip:Show()
    end)
    ns.shieldButton = b
    return b
end

local function setTimer(btn, seconds)
    btn.expiresAt = seconds and (GetTime() + seconds) or nil
    ns.RefreshButtonTimer(btn)
end

function ns.RefreshButtonTimer(btn)
    local left = btn.expiresAt and (btn.expiresAt - GetTime())
    if not left or left <= 0 then btn.timer:SetText(""); return end
    btn.timer:SetText(ns.FormatTime(left))
    local c = left < (ns.db.rebuffMinutes or 5) * 60 and ns.COLORS.warn or { 1, 1, 1 }
    btn.timer:SetTextColor(c[1], c[2], c[3])
end

-- Out of combat only: binds spells and refreshes visuals.
function ns.ApplyButtons(plan)
    local b = ns.buffButton
    local buff = plan.buff
    if buff and buff.spell then
        b:SetAttribute("spell1", buff.spell)
        b:SetAttribute("unit1", buff.unit)
        b.icon:SetTexture(ns.SpellIcon(buff.spell))
        b.icon:SetDesaturated(buff.outOfRange or false)
        b.icon:SetAlpha(buff.outOfRange and 0.5 or 1)
    else
        b:SetAttribute("spell1", nil)
        b:SetAttribute("unit1", nil)
        local armor = ns.ArmorKey()
        b.icon:SetTexture(ns.SpellIcon(armor and ns.Best(armor) or ns.Best("INTELLECT")))
        b.icon:SetDesaturated(true)
        b.icon:SetAlpha(0.6)
    end
    local brill = ns.Best("BRILLIANCE")
    b:SetAttribute("spell2", brill)
    b:SetAttribute("unit2", plan.brillUnit or "player")
    UI.SetGlow(b, buff ~= nil and not buff.outOfRange)
    setTimer(b, ns.ArmorRemaining())

    local s = ns.shieldButton
    local shield = plan.shield
    if shield and shield.spell then
        s:SetAttribute("spell", shield.spell)
        s.icon:SetTexture(ns.SpellIcon(shield.spell))
        s:Show()
    else
        s:SetAttribute("spell", nil)
        s:Hide()
    end
    ns.RefreshShieldGlow()
end

function ns.RefreshShieldGlow()
    local s = ns.shieldButton
    if not s or not s:IsShown() then return end
    local low = ns.ShieldIsLow()
    UI.SetGlow(s, low)
    s.icon:SetDesaturated(not low)
    s.icon:SetAlpha(low and 1 or 0.75)
end
