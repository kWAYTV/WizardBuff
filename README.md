# Wizard Buff

A lightweight mage buff HUD for WoW Classic (TBC Anniversary). Shows what needs casting at a glance — armor, Intellect, Arcane Brilliance, and emergency shields — then lets you apply them with a single click or keybind.

## Features

- **Two-button HUD** — left button is **Auto Buff** (cascades: armor → self Intellect → group Intellect → pets → shield). Right button is dedicated **Group** (Brilliance / Intellect on next unbuffed member).
- **Glow alerts** — bright pulsing gold border on any button that needs attention.
- **Buff timers** — live countdown overlaid on each icon. Color shifts to orange when time is low.
- **Sound reminders** — optional distinct sounds for missing self-buffs vs group buffs (toggleable).
- **Need counter** — small "2 need" line below the icons so you know how many group members are unbuffed.
- **Buff grid** — per-player/pet cast buttons grouped by class (enabled by default). Click any cell to buff or rebuff that unit.
- **Smart targeting** — prioritizes self (armor first), then players in range, then pets. Skips units that already have a stronger Brilliance from another mage. Falls back to friendly target when group is fully buffed.
- **Minimap button** — via LibDataBroker / LibDBIcon. Left-click toggles, Shift-click locks, right-click opens settings.
- **Keybinds** — bind both buttons from the standard Key Bindings menu.
- **Profile support** — AceDB profiles with import/export via the settings panel.
- **Position memory** — drag the HUD anywhere; position persists across reloads and relogs.
- **Auto-lock** — when you unlock to reposition, the HUD re-locks automatically after 30 seconds.
- **Drag handle** — small handle above the HUD for dragging and quick actions (can be hidden in settings).
- **Buff duration guard** — prevents wasting reagents by skipping rebuffs when the remaining duration exceeds a configurable floor (default 2 minutes).
- **Report to chat** — `/wbuff report` sends a buff status summary to party/raid chat (or local chat when solo).
- **Combat-aware** — fades in combat, prevents taint by skipping secure frame changes during lockdown.

## Installation

Install from [CurseForge](https://www.curseforge.com/wow/addons/wizard-buff) or copy the `WizardBuff` folder into:

```
World of Warcraft\_anniversary_\Interface\AddOns\
```

> **Note:** Do *not* add `Bindings.xml` to the `.toc` file. The WoW client loads it automatically from the addon root.

## Usage

The HUD appears automatically for Mage characters. Drag it where you like, then `/wbuff lock` to pin it.

| Button | What it does |
|--------|-------------|
| **Left icon (Auto Buff)** | Cascading priority: armor → self Intellect → next group member → pets → emergency shield |
| **Right icon (Group)** | Casts Intellect or Arcane Brilliance on the next unbuffed party/raid member or pet. Falls back to friendly target when everyone is buffed |

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
| `grid` | Toggle buff grid |
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

Triggers the **Auto Buff** button (armor → intellect → pets).

```
/click WizardBuffBrillianceButton
```

Triggers the **Group** button (Intellect / Brilliance on next target).

## Settings

Open with `/wbuff config` or right-click the drag handle.

- **General** — master toggle, lock, show solo, need count, buff timers, glow alerts, sound alerts, buff grid, drag handle, minimap icon.
- **Appearance** — HUD scale, idle/hover opacity, combat fade, position reset.
- **Buffs** — armor type (auto/ice/mage/frost), Intellect, Brilliance preference, pet buffing, emergency shield type and HP% threshold, buff duration guard.
- **Profiles** — AceDB profile management with import/export.

## Saved Variables

- `WizardBuffDB` — AceDB profile data.
- Performs a one-time migration from `MagePowerDB` if a legacy install is detected.

## Libraries

Fetched automatically at build time via `.pkgmeta` externals:

Ace3 (AceAddon, AceConfig, AceConfigDialog, AceConsole, AceDB, AceDBOptions, AceEvent, AceGUI, AceLocale) · LibStub · CallbackHandler · LibDataBroker-1.1 · LibDBIcon-1.0

## Packaging

Releases are built automatically via [BigWigsMods/packager](https://github.com/BigWigsMods/packager) GitHub Action:

- **Push a tag** (e.g. `1.3`) → builds a **Release** on CurseForge and GitHub
- **Push to master** (no tag) → builds an **Alpha** on CurseForge

The `@project-version@` token in the `.toc` is replaced with the tag name or commit hash automatically.

## Interface Version

`20505` — TBC Anniversary (2025/2026). Bump `## Interface` in `WizardBuff.toc` when targeting a different client build.

## License

All Rights Reserved © kWAYTV
