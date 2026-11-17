# Wizard Buff

Who in your group has Arcane Intellect, for mages on **WoW Forever**. Click a name to buff that person. Your armor is on the first line.

Three layouts. You pick one the first time you log in, and can switch in settings or from the title bar menu.

**List** (default)

```
 Wizard Buff          3/4      ← Alt-drag to move, right-click for a menu
 Frost Armor            28m
 Kway                   54m
 Anduin             missing
 Hamuul                 24m
 Rexxar                 far
```

**Frames**

```
 ▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬
[Frost 28m][Kway  ][Anduin][Hamuul]
```

**Compact**

```
 ▬▬▬▬▬▬▬▬▬▬▬▬▬▬
[■] [■][■][■][■][■]     ← small squares, no text: the fill is the state,
    [■][■][■][■][■]       the strip along the bottom the class colour
```

The first square is your armor. Hover a square for the name. Best for raids.

In a raid, frames and compact have one row per group; the list just gets longer.

## Reading it

| Looks like | Means |
|---|---|
| Red | No Intellect, in range |
| Orange | Runs out soon (if "Rebuff early" is on) |
| A time (list), a green line (frames) or a green square (compact) | Has it |
| Dim name | No mana (warriors, rogues) |
| Faded, "far" or "gone" | Out of range, dead or offline |
| Faded, "skip" | You ignored them (middle-click) |

Names are in class colour. Hover for details.

The title bar shows how many of the people in range have it (`3/4`). When Arcane Powder runs low it shows the count in red.

## Clicks

- **Left-click a name**: Arcane Intellect on that person, right rank for their level.
- **Right-click a name**: Arcane Brilliance (raid-wide on Forever).
- **Middle-click a name**: ignore that person until your next loading screen. Again to undo.
- **Armor**: left-click recasts the armor you used last, right-click swaps to another. It turns red when your armor is down.

## Keybind

Options → Keybindings → AddOns → Wizard Buff → **Buff next**. Armor first if it's down, then the next person missing Intellect: you, your group, the rest. With 3+ missing it casts Brilliance.

## Settings

Right-click the title bar and pick Settings, left-click the minimap button, `/wb config`, or Esc → Options → AddOns.

| Setting | What it does |
|---|---|
| Show | Same as `/wb` |
| Layout | List, Frames or Compact |
| Only when needed | Hide while nobody needs a buff |
| Hide in cities | Hide while resting |
| Fade when idle | Dim while nobody needs a buff; full again on mouseover |
| Size | 50–200% |
| Rebuff early | Ask for a rebuff N minutes before it runs out |
| Auto Brilliance / Brilliance at | Whether **Buff next** may cast Brilliance, and at how many missing |
| Ready check alert | List who has no Intellect on a ready check |
| Sound | A sound when someone newly needs Intellect |
| Minimap button | Show the button on the minimap; drag it along the rim |

With EllesmereUI installed, the grid also shows up in its Unlock mode.

## Commands

`/wb` show / hide · `/wb config` · `/wb report` (post who is missing to group chat) · `/wb test` (fake group, to see the layout solo) · `/wb scale 1.2` · `/wb reset` · `/wb version` · `/wb debug`

It hides by itself while you are dead, in a vehicle, flying or on a flight path.

## Combat

Forever can hide buffs from addons in combat. When it does, cells keep their last look. Cells can't appear, move or change spell mid-fight; they catch up when it ends. Clicking still works.

## Install

[CurseForge](https://www.curseforge.com/wow/addons/wizard-buff), or drop the `WizardBuff` folder in `World of Warcraft\_forever_\Interface\AddOns\`.

## Code

One folder per thing the addon is about. Files are small and do one job.

| Folder | What's in it |
|---|---|
| `intellect/` | Spell data, who's in the group, who's missing it, what Buff next casts, the member cells, ignore, test group, sound, group report, powder count, ready check alert |
| `armor/` | Spell data, which armor is up and which to cast, the armor bar |
| `grid/` | How it is drawn: holder, cell, the three layouts (list, frames, compact), handle and its menu, idle fade, colours, tooltips, EllesmereUI unlock mode |
| `settings/` | Saved settings, options screen, first-login layout prompt, minimap button, addon list entry, `/wb`, debug |
| `client/` | Everything that asks the game something: hidden values, names, spellbook, buffs, range, pixel size |
| `app/` | Wiring: startup, events, the refresh pass, the keybind |

Load order is in `WizardBuff.toc`. Pushing to `master` tags the next patch version and [BigWigsMods/packager](https://github.com/BigWigsMods/packager) releases it.

## License

All Rights Reserved © kWAYTV
