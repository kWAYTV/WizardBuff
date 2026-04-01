# Wizard Buff

A lightweight mage buff HUD for WoW Classic (TBC Anniversary). Shows what needs casting at a glance — armor, Intellect, Arcane Brilliance, and emergency shields — then lets you apply them with a single click or keybind.

## Features

- **Two-button HUD** — left button handles self-buffs (armor, emergency shield). Right button handles group buffs (Intellect / Arcane Brilliance for party, pets, and friendly target).
- **Glow alerts** — bright pulsing gold border on any button that needs attention.
- **Buff timers** — remaining duration overlaid on each icon. Color shifts to orange when time is low.
- **Sound reminders** — optional distinct sounds for missing self-buffs vs group buffs (toggleable).
- **Need counter** — small "2 need Int" line below the icons so you know how many group members are unbuffed.
- **Class rows** — expandable per-class roster with individual cast buttons for each player and pet.
- **Smart targeting** — prioritizes self (armor first), then players in range, then pets. Skips units that already have a stronger Brilliance from another mage. Falls back to friendly target when group is fully buffed.
- **Minimap button** — via LibDataBroker / LibDBIcon. Left-click toggles, Shift-click locks, right-click opens settings. Hover shows a LibQTip tooltip with status.
- **Keybinds** — bind both buttons from the standard Key Bindings menu.
- **Profile support** — AceDB profiles with import/export via the settings panel.
- **Position memory** — drag the HUD anywhere; position persists across reloads and relogs.
- **Auto-lock** — when you unlock to reposition, the HUD re-locks automatically after 30 seconds.
- **Drag handle toggle** — the top-edge drag handle can be hidden via settings if you prefer a cleaner look.
- **Buff duration guard** — prevents wasting reagents by skipping rebuffs when the remaining duration exceeds a configurable floor (default 2 minutes).
- **Report to chat** — `/wbuff report` sends a buff status summary to party/raid chat (or local chat when solo).
- **Combat-aware** — fades in combat, prevents taint by skipping secure frame changes during lockdown.

## Installation

Copy the `WizardBuff` folder into:

```
World of Warcraft\_anniversary_\Interface\AddOns\
```

All libraries are embedded — no external dependencies required.

> **Note:** Do *not* add `Bindings.xml` to the `.toc` file. The WoW client loads it automatically from the addon root.

## Usage

The HUD appears automatically for Mage characters. Drag it where you like, then `/wbuff lock` to pin it.

| Button | What it does |
|--------|-------------|
| **Left icon (Self)** | Casts the highest-priority missing self-buff: armor → emergency shield (if HP below threshold) |
| **Right icon (Group)** | Casts Intellect or Arcane Brilliance on the next unbuffed party/raid member or pet. When everyone is buffed, falls back to friendly target |

Hover over the drag handle at the top edge for quick actions:
- **Right-click** — open settings
- **Shift+click** — unlock/lock position (auto-locks after 30 seconds)

## Slash Commands

`/wbuff` or `/wizardbuff` followed by:

| Command | Action |
|---------|--------|
| *(none)* or `toggle` | Enable / disable the HUD |
| `config` | Open the settings panel |
| `lock` | Lock / unlock position (auto-locks after 30s) |
| `rows` | Toggle class rows |
| `armor` | Toggle armor buffing |
| `bubble` | Toggle emergency shield |
| `int` | Toggle Intellect buffing |
| `brilliance` | Toggle Arcane Brilliance preference |
| `pets` | Toggle pet buffing |
| `report` | Print buff status to party/raid chat |
| `macro` | Show `/click` macro syntax for keybind addons |

## Macros

You can bind the HUD buttons to custom macros or action bars:

```
/click WizardBuffAutoBuffButton
```

Triggers the **Self** button (armor / shield).

```
/click WizardBuffBrillianceButton
```

Triggers the **Group** button (Intellect / Brilliance on next target).

## Settings

Open with `/wbuff config` or right-click the HUD.

- **General** — master toggle, lock, show solo, need count, buff timers, glow alerts, sound alerts (self / group), class rows, minimap icon visibility.
- **Appearance** — HUD scale, idle/hover opacity, combat fade, drag handle toggle, position reset.
- **Buffs** — armor type (auto/ice/mage/frost), Intellect, Brilliance preference, pet buffing, emergency shield type and HP% threshold, buff duration guard (min remaining seconds).
- **Profiles** — AceDB profile management with import/export.

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
