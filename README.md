# Wizard Buff

Two icons for mages on **WoW Forever**: one for Arcane Intellect, one for your armor. They glow when something's missing. Click to fix it.

## Intellect icon

- Corner number = people near you without Intellect.
- **Left-click** buffs the next one: you, your group, then the rest. Right rank for their level.
- With 3+ missing it casts Arcane Brilliance instead (raid-wide on Forever). **Right-click** always casts it.
- Everyone buffed? The timer shows when the first one runs out, and a click refreshes that person.
- Warriors, rogues, pets, the dead and the offline are skipped. People out of range show up in the tooltip, not in the count.

## Armor icon

- **Left-click** recasts the armor you used last.
- **Right-click** swaps to another one.

**Alt-drag** either icon to move them.

## Settings

Esc → Options → AddOns → Wizard Buff, `/wb config`, or the minimap addon list.

| Setting | What it does |
|---|---|
| Show icons | Same as `/wb` |
| Only when needed | Hide an icon while its buff is up |
| Hide in cities | Hide while resting |
| Timers | Time left under each icon |
| Size | 50–200% |
| Rebuff early | Ask for a rebuff N minutes before it runs out |
| Auto Brilliance / Brilliance at | Whether left-click may cast Brilliance, and at how many missing |
| Ready check alert | List who has no Intellect on a ready check |

## Keybind

Options → Keybindings → AddOns → Wizard Buff → **Buff next**. Armor first if it's down, then Intellect.

## Commands

`/wb` show / hide · `/wb config` · `/wb scale 1.2` · `/wb reset` · `/wb debug`

## Combat

Forever can hide buffs from addons in combat. When it does, the icons go grey and keep their last reading. Buttons can't change target or show/hide mid-fight; they catch up when it ends.

## Install

[CurseForge](https://www.curseforge.com/wow/addons/wizard-buff), or drop the `WizardBuff` folder in `World of Warcraft\_forever_\Interface\AddOns\`.

## Code

One folder per thing the addon is about. Files are small and do one job.

| Folder | What's in it |
|---|---|
| `intellect/` | Spell data, who's in the group, who's missing it, what to cast, its icon, the ready check alert |
| `armor/` | Spell data, which armor is up and which to cast, its icon |
| `icons/` | How an icon looks: holder frame, button, glow, text |
| `settings/` | Saved settings, the options screen, addon list entry, `/wb`, debug |
| `client/` | Everything that asks the game something: hidden values, spellbook, buffs, range, pixel size |
| `app/` | Wiring: startup, events, the refresh pass, the keybind |

Load order is in `WizardBuff.toc`. Pushing to `master` tags the next patch version and [BigWigsMods/packager](https://github.com/BigWigsMods/packager) releases it.

## License

All Rights Reserved © kWAYTV
