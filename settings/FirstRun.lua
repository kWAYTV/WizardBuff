local _, ns = ...

-- Asked once: which layout. Escape doesn't answer it, so it comes back next
-- login until a button is clicked.

local function choose(layout)
    ns.db.layout = layout
    ns.db.layoutChosen = true
    ns.lookAgain()
    ns.say("Change it any time: /wb config.")
end

StaticPopupDialogs.WIZARDBUFF_LAYOUT = {
    text = "Wizard Buff\n\nPick a layout.\n\n|cffffffffList|r: one line per person.\n"
        .. "|cffffffffFrames|r: small cells with names.\n|cffffffffCompact|r: small squares, best for raids.\n\n"
        .. "You can change it any time in settings.",
    button1 = "List",
    button2 = "Frames",
    button3 = "Compact",
    OnAccept = function() choose("list") end,
    OnAlt = function() choose("compact") end,
    OnCancel = function(_, _, reason)
        if reason == "clicked" then choose("frames") end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3,
}

function ns.askLayout()
    if ns.db.layoutChosen then return end
    StaticPopup_Show("WIZARDBUFF_LAYOUT")
end
