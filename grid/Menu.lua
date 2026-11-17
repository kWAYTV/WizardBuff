local _, ns = ...

-- Right-click menu of the title bar and the minimap button.

local LAYOUTS = { { "list", "List" }, { "frames", "Frames" }, { "compact", "Compact" } }

function ns.grid.openMenu(owner)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then return ns.openSettings() end
    MenuUtil.CreateContextMenu(owner, function(_, root)
        root:CreateTitle("Wizard Buff")
        root:CreateButton("Settings", ns.openSettings)
        for _, layout in ipairs(LAYOUTS) do
            if layout[1] ~= ns.db.layout then
                root:CreateButton("Layout: " .. layout[2], function()
                    ns.db.layout = layout[1]
                    ns.lookAgain()
                end)
            end
        end
        root:CreateButton("Report missing to group", ns.intellect.report)
        root:CreateButton(ns.intellect.testing() and "Test: next" or "Test with a fake group", ns.intellect.nextTest)
        root:CreateButton(ns.db.shown and "Hide" or "Show", ns.toggleShown)
    end)
end
