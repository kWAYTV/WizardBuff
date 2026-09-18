local _, ns = ...

-- TBC Anniversary: both click directions required or casts silently fail.
function ns.RegisterSecureClicks(btn)
    btn:RegisterForClicks("AnyUp", "AnyDown")
end

-- PostClick fires on down and up. Feedback / recently-buffed only on release.
function ns.IsClickRelease(down)
    return down ~= true
end

function ns.StripSecureChrome(btn)
    local nt = btn.GetNormalTexture and btn:GetNormalTexture()
    if nt then nt:SetTexture(nil); nt:SetAlpha(0) end
    local pt = btn.GetPushedTexture and btn:GetPushedTexture()
    if pt then pt:SetTexture(nil) end
    local ht = btn.GetHighlightTexture and btn:GetHighlightTexture()
    if ht then ht:SetTexture(nil) end
end

function ns.ClearSecureSpell(btn)
    if not btn then return end
    btn:SetAttribute("type", nil)
    btn:SetAttribute("spell", nil)
    btn:SetAttribute("unit", nil)
    btn:SetAttribute("macrotext", nil)
end

function ns.BindSecureSpell(btn, spell, unit)
    btn:SetAttribute("type", "spell")
    btn:SetAttribute("spell", spell)
    btn:SetAttribute("unit", unit or "player")
    btn:SetAttribute("macrotext", nil)
end
