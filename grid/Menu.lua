local _, ns = ...

-- Right-click menu of the title bar and the minimap button.

function ns.grid.openMenu(owner)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then return ns.openSettings() end
    MenuUtil.CreateContextMenu(owner, function(_, root)
        root:CreateTitle("Wizard Buff")
        root:CreateButton("Settings", ns.openSettings)
        root:CreateButton(ns.db.layout == "list" and "Switch to frames" or "Switch to list", function()
            ns.db.layout = ns.db.layout == "list" and "frames" or "list"
            ns.lookAgain()
        end)
        root:CreateButton("Report missing to group", ns.intellect.report)
        root:CreateButton(ns.intellect.testing() and "Test: next" or "Test with a fake group", ns.intellect.nextTest)
        root:CreateButton(ns.db.shown and "Hide" or "Show", ns.toggleShown)
    end)
end
