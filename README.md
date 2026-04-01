# Wizard Buff

A lightweight mage buff HUD for WoW Classic (TBC Anniversary). Shows what needs casting at a glance — armor, Intellect, Arcane Brilliance, and emergency shields — then lets you apply them with a single click or keybind.

## Features

- **Two-button HUD** — left button auto-cycles through self-armor → shield → next Intellect target. Right button handles Arcane Brilliance (or falls back to Intellect when out of Arcane Powder).
- **Glow alerts** — bright pulsing gold border on any button that needs attention.
- **Buff timers** — remaining duration overlaid on each icon. Color shifts to orange when time is low.
- **Sound reminder** — optional repeating alarm while buffs are missing (uses the WoW alarm clock sound, toggleable).
- **Need counter** — small "2 need Int" line below the icons so you know how many group members are unbuffed.
- **Class rows** — expandable per-class roster with individual cast buttons for each player and pet.
- **Smart targeting** — prioritizes self (armor first), then players in range, then pets. Skips units that already have a stronger Brilliance from another mage.
- **Minimap button** — via LibDataBroker / LibDBIcon. Left-click toggles, Shift-click locks, right-click opens settings. Hover shows a LibQTip tooltip with status.
- **Keybinds** — bind both buttons from the standard Key Bindings menu.
- **Profile support** — full AceDB profiles with import/export via the settings panel.
- **Position memory** — drag the HUD anywhere; position persists across reloads and relogs.
- **Combat-aware** — fades in combat, prevents taint by skipping secure frame changes during lockdown.

## Installation

Copy the `WizardBuff` folder into:

```
World of Warcraft\_anniversary_\Interface\AddOns\
```

All libraries are embedded — no external dependencies required.

> **Note:** Do *not* add `Bindings.xml` to the `.toc` file. The WoW client loads it automatically from the addon root.

## Usage

The HUD appears automatically for Mage characters. Drag it where you like, then `/wb lock` to pin it.

| Button | What it does |
|--------|-------------|
| **Left icon (Auto)** | Casts the highest-priority missing buff: self-armor → emergency shield (if HP below threshold) → next unbuffed player/pet |
| **Right icon (Group)** | Casts Arcane Brilliance on the same target. Falls back to single-target Intellect if you're out of Arcane Powder or haven't trained Brilliance yet |

Right-click the HUD to open settings.

## Slash Commands

`/wb` or `/wizardbuff` followed by:

| Command | Action |
|---------|--------|
| *(none)* or `toggle` | Enable / disable the HUD |
| `config` | Open the settings panel |
| `lock` | Lock / unlock position |
| `rows` | Toggle class rows |
| `armor` | Toggle armor buffing |
| `bubble` | Toggle emergency shield |
| `int` | Toggle Intellect buffing |
| `brilliance` | Toggle Arcane Brilliance preference |
| `pets` | Toggle pet buffing |

## Settings

Open with `/wb config` or right-click the HUD.

- **General** — master toggle, lock, show solo, need count, buff timers, glow alerts, sound alert, class rows, minimap icon visibility.
- **Appearance** — HUD scale, idle/hover opacity, combat fade, position reset.
- **Buffs** — armor type (auto/ice/mage/frost), Intellect, Brilliance preference, pet buffing, emergency shield type and HP% threshold.
- **Profiles** — standard AceDB profile management.

## Saved Variables

- `WizardBuffDB` — AceDB profile data.
- Performs a one-time migration from `MagePowerDB` if a legacy install is detected.

## Libraries

All bundled in `Libs/`:

Ace3 (AceAddon, AceConfig, AceConfigDialog, AceConsole, AceDB, AceDBOptions, AceEvent, AceGUI, AceLocale) · LibStub · CallbackHandler · LibDataBroker-1.1 · LibDBIcon-1.0 · LibQTip-1.0

## Packaging

Run `pack.bat` (or `pack.ps1` directly) to produce a `WizardBuff.zip` on your Desktop, structured with the correct root folder for CurseForge upload.

`.pkgmeta` is included for the CurseForge BigWigs packager if you prefer automated releases.

## Interface Version

`20505` — TBC Anniversary (2025/2026). Bump `## Interface` in `WizardBuff.toc` when targeting a different client build.

## License

All Rights Reserved © LazyLoafs
