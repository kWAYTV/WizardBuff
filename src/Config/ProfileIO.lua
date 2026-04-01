local _, ns = ...

---------------------------------------------------------------------------
-- Serialization
---------------------------------------------------------------------------
local function serializeValue(v)
    local t = type(v)
    if t == "string" then return string.format("%q", v)
    elseif t == "number" then return tostring(v)
    elseif t == "boolean" then return v and "true" or "false"
    elseif t == "table" then
        local parts = {}
        for k, sv in pairs(v) do
            local key
            if type(k) == "string" then
                key = k:match("^[%a_][%w_]*$") and k or ("[" .. string.format("%q", k) .. "]")
            else
                key = "[" .. tostring(k) .. "]"
            end
            local val = serializeValue(sv)
            if val then parts[#parts + 1] = key .. "=" .. val end
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
end

local function deserializeProfile(str)
    if not str or str:trim() == "" then return nil, "Empty string" end
    local fn, err = loadstring("return " .. str)
    if not fn then return nil, err end
    setfenv(fn, {})
    local ok, result = pcall(fn)
    if not ok then return nil, result end
    if type(result) ~= "table" then return nil, "Expected a table" end
    return result
end

---------------------------------------------------------------------------
-- Popup helper
---------------------------------------------------------------------------
local function createPopupFrame(name, titleText, w, h)
    local f = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    f:SetSize(w, h)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -10)
    title:SetText(titleText)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    local scroll = CreateFrame("ScrollFrame", name .. "Scroll", f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -32)
    scroll:SetPoint("BOTTOMRIGHT", -30, 40)

    local eb = CreateFrame("EditBox", name .. "Edit", scroll)
    eb:SetMultiLine(true)
    eb:SetAutoFocus(false)
    eb:SetFont(STANDARD_TEXT_FONT, 11)
    eb:SetWidth(scroll:GetWidth() or (w - 50))
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scroll:SetScrollChild(eb)
    f.editBox = eb

    f:Hide()
    return f
end

---------------------------------------------------------------------------
-- Export / Import
---------------------------------------------------------------------------
function ns.ShowProfileExport()
    if not ns._exportFrame then
        ns._exportFrame = createPopupFrame("WizardBuffExport", "Export Profile", 420, 300)
    end
    local data = serializeValue(ns.db) or "{}"
    local eb = ns._exportFrame.editBox
    eb:SetText(data)
    ns._exportFrame:Show()
    eb:HighlightText()
    eb:SetFocus()
end

function ns.ShowProfileImport()
    if not ns._importFrame then
        local f = createPopupFrame("WizardBuffImport", "Import Profile", 420, 300)
        local btn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        btn:SetSize(80, 22)
        btn:SetPoint("BOTTOM", 0, 10)
        btn:SetText("Apply")
        btn:SetScript("OnClick", function()
            local str = f.editBox:GetText()
            local tbl, err = deserializeProfile(str)
            if not tbl then
                ns.PrintError("Import failed — " .. tostring(err))
                return
            end
            local profile = ns.db
            for k, v in pairs(tbl) do
                if ns.defaults[k] ~= nil or k == "minimap" or k == "hudPos" then
                    profile[k] = v
                end
            end
            if ns.ScheduleUpdate then ns.ScheduleUpdate() end
            if ns.ApplyHudScale then ns.ApplyHudScale() end
            if ns.ApplyHudFade then ns.ApplyHudFade() end
            f:Hide()
            ns.Print("Profile imported.")
        end)
        ns._importFrame = f
    end
    local eb = ns._importFrame.editBox
    eb:SetText("")
    ns._importFrame:Show()
    eb:SetFocus()
end
