# Wizard Buff

Small group frames for mages on **WoW Forever**: one cell per member showing who has Arcane Intellect. Click a cell to buff that person. A bar on top for your armor.

```
 ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬   ← Alt-drag to move, right-click for settings
[ Ice Armor              28m ]  ← your armor
[Kway  ][Anduin][Hamuul][Grom]  ← one cell per member, names in class colour
```

In a raid there's one row per group.

## Reading a cell

| Cell | Means |
|---|---|
| Red, with a red block | No Intellect, in range |
| Orange border | Runs out soon (if "Rebuff early" is on) |
| Green line under the name | Has it; the line shrinks as time runs out |
| Dim name | No mana (warriors, rogues) |
| Faded | Out of range, dead or offline |

Hover a cell for the time left.

## Clicks

- **Left-click a cell**: Arcane Intellect on that person, right rank for their level.
- **Right-click a cell**: Arcane Brilliance (raid-wide on Forever).
- **Armor bar**: left-click recasts the armor you used last, right-click swaps to another. It turns red when your armor is down.

## Keybind

Options → Keybindings → AddOns → Wizard Buff → **Buff next**. Armor first if it's down, then the next person missing Intellect: you, your group, the rest. With 3+ missing it casts Brilliance.

## Settings

Right-click the thin bar on top, `/wb config`, the minimap addon list, or Esc → Options → AddOns.

| Setting | What it does |
|---|---|
| Show | Same as `/wb` |
| Only when needed | Hide while nobody needs a buff |
| Hide in cities | Hide while resting |
| Size | 50–200% |
| Rebuff early | Ask for a rebuff N minutes before it runs out |
| Auto Brilliance / Brilliance at | Whether **Buff next** may cast Brilliance, and at how many missing |
| Ready check alert | List who has no Intellect on a ready check |

With EllesmereUI installed, the grid also shows up in its Unlock mode.

## Commands

`/wb` show / hide · `/wb config` · `/wb scale 1.2` · `/wb reset` · `/wb debug`

## Combat

Forever can hide buffs from addons in combat. When it does, cells keep their last look. Cells can't appear, move or change spell mid-fight; they catch up when it ends. Clicking still works.

## Install

[CurseForge](https://www.curseforge.com/wow/addons/wizard-buff), or drop the `WizardBuff` folder in `World of Warcraft\_forever_\Interface\AddOns\`.

## Code

One folder per thing the addon is about. Files are small and do one job.

| Folder | What's in it |
|---|---|
| `intellect/` | Spell data, who's in the group, who's missing it, what Buff next casts, the member cells, ready check alert |
| `armor/` | Spell data, which armor is up and which to cast, the armor bar |
| `grid/` | How cells look and where they go: holder, cell, handle, layout, colours, tooltips, EllesmereUI unlock mode |
| `settings/` | Saved settings, options screen, addon list entry, `/wb`, debug |
| `client/` | Everything that asks the game something: hidden values, spellbook, buffs, range, pixel size |
| `app/` | Wiring: startup, events, the refresh pass, the keybind |

Load order is in `WizardBuff.toc`. Pushing to `master` tags the next patch version and [BigWigsMods/packager](https://github.com/BigWigsMods/packager) releases it.

## License

All Rights Reserved © kWAYTV
