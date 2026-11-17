# Wizard Buff

Who in your group has Arcane Intellect, for mages on **WoW Forever**. Click a name to buff that person. Your armor is on the first line.

Two layouts. You pick one the first time you log in, and can switch in settings.

**List** (default)

```
 Wizard Buff      1 missing    ← Alt-drag to move, right-click for settings
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

In a raid the frames layout has one row per group; the list just gets longer.

## Reading it

| Looks like | Means |
|---|---|
| Red | No Intellect, in range |
| Orange | Runs out soon (if "Rebuff early" is on) |
| A time (list) or a green line (frames) | Has it |
| Dim name | No mana (warriors, rogues) |
| Faded, "far" or "gone" | Out of range, dead or offline |

Names are in class colour. Hover for details.

## Clicks

- **Left-click a name**: Arcane Intellect on that person, right rank for their level.
- **Right-click a name**: Arcane Brilliance (raid-wide on Forever).
- **Armor**: left-click recasts the armor you used last, right-click swaps to another. It turns red when your armor is down.

## Keybind

Options → Keybindings → AddOns → Wizard Buff → **Buff next**. Armor first if it's down, then the next person missing Intellect: you, your group, the rest. With 3+ missing it casts Brilliance.

## Settings

Right-click the title bar, left-click the minimap button, `/wb config`, or Esc → Options → AddOns.

| Setting | What it does |
|---|---|
| Show | Same as `/wb` |
| Layout | List or Frames |
| Only when needed | Hide while nobody needs a buff |
| Hide in cities | Hide while resting |
| Size | 50–200% |
| Rebuff early | Ask for a rebuff N minutes before it runs out |
| Auto Brilliance / Brilliance at | Whether **Buff next** may cast Brilliance, and at how many missing |
| Ready check alert | List who has no Intellect on a ready check |
| Minimap button | Show the button on the minimap; drag it along the rim |

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
| `grid/` | How it is drawn: holder, cell, the two layouts (list, frames), handle, colours, tooltips, EllesmereUI unlock mode |
| `settings/` | Saved settings, options screen, first-login layout prompt, minimap button, addon list entry, `/wb`, debug |
| `client/` | Everything that asks the game something: hidden values, spellbook, buffs, range, pixel size |
| `app/` | Wiring: startup, events, the refresh pass, the keybind |

Load order is in `WizardBuff.toc`. Pushing to `master` tags the next patch version and [BigWigsMods/packager](https://github.com/BigWigsMods/packager) releases it.

## License

All Rights Reserved © kWAYTV
