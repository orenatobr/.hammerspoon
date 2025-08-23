# Hammerspoon Productivity Toolkit

Automations and hotkeys for macOS using [Hammerspoon](https://www.hammerspoon.org/).  
This config focuses on window management, app-aware behaviors (Safari, VS Code, Teams, FileZilla), presence helpers, and a few quality-of-life shortcuts.

> On load you should see: `✅ Hammerspoon Productivity Toolkit initialized.` and an alert “🎉 All automations active”.

## Contents

- [Features](#features)
- [Requirements](#requirements)
- [Install](#install)
- [Permissions](#permissions)
- [Hotkeys](#hotkeys)
- [How it works (modules)](#how-it-works-modules)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Repository structure](#repository-structure)

## Features

- **Auto brightness**: adjusts brightness based on power source (AC vs Battery).
- **Window cycle (per app)**: cycle through the current app’s windows.
- **Launchpad shortcut**: quick open.
- **Browser refresh macro**: clear cache then reload (helpful for web dev).
- **Safari tab switcher**: fuzzy-pick any open Safari tab via chooser.
- **App switcher (chooser)**: fuzzy-pick any running app to focus.
- **AWS Console account detector (Safari)**: detects the current AWS account from the tab URL and shows a mapped label (e.g., `🔴 fsm-prod`).
- **Safari & VS Code window placement**: auto-move new/focused windows to a secondary display when available.
- **Teams presence keep-alive**: gentle mouse “jiggle” while Microsoft Teams is running to prevent away status.
- **Teams focus restore**: when Teams activates, re-focus the last useful Teams window (not the empty/splash window).
- **FileZilla caffeinate**: prevents display sleep while FileZilla is running; reverts when it closes.
- **Lid/Bluetooth automation (Shortcuts)**: reacts to lid state changes and triggers named Shortcuts to toggle Bluetooth (uses Apple Shortcuts via AppleScript/CLI/URL as fallbacks).

## Requirements

- **macOS**
- **Hammerspoon** (latest)
- **Accessibility** permissions for Hammerspoon (window control, key events)
- **Apple Shortcuts** (optional, for Bluetooth automation)
  - Shortcuts with exact names: **“Bluetooth On”** and **“Bluetooth Off”**
- Apps: Safari, Visual Studio Code, Microsoft Teams, FileZilla (features adapt if an app isn’t installed)

## Install

1. Install Hammerspoon and open it once.
2. Clone this repo into your Hammerspoon directory:

   ```bash
   git clone git@github.com:orenatobr/.hammerspoon.git
   ```

   _(Or copy the files there.)_

3. Reload the config:
   - Hammerspoon menu → **Reload Config**, or
   - `hs.reload()` from the Hammerspoon console.
4. You should see the startup alert confirming all automations are active.

## Permissions

Go to **System Settings → Privacy & Security**:

- **Accessibility** → enable **Hammerspoon**
- (Optional) **Automation** may prompt when Hammerspoon uses AppleScript/Shortcuts
- If using multi-display placement, ensure Hammerspoon can control windows (Accessibility is enough)

## Hotkeys

| Hotkey    | Module                 | Action                                                               |
| --------- | ---------------------- | -------------------------------------------------------------------- |
| `Alt + C` | `window_cycle.lua`     | Cycle through the current app’s standard/visible windows.            |
| `Alt + A` | `launchpad_hotkey.lua` | Open Launchpad.                                                      |
| `Alt + R` | `refresh_hotkey.lua`   | Clear browser cache (`⌥⌘E`), then reload (`⌘R`) after 1s.            |
| `Alt + S` | `tab_navigation.lua`   | Open chooser of **Safari** tabs (title + URL) and jump to selection. |
| `Alt + Z` | `app_navigation.lua`   | Open chooser of **running apps** with icons; activate selection.     |

> You can change any hotkey inside each module’s `hs.hotkey.bind({...}, "KEY", ...)`.

## How it works (modules)

- **`modules/auto_brightness.lua`**  
  Uses `hs.battery.watcher` to detect power source transitions and sets brightness (e.g., AC → 100%, Battery → 50%). Displays a small alert with the current power source.

- **`modules/window_cycle.lua`**  
  Binds `Alt+C`. Collects current app’s standard & visible windows, sorts them by id, and focuses the “next” window in a loop.

- **`modules/launchpad_hotkey.lua`**  
  Binds `Alt+A`. Runs `open -a Launchpad`.

- **`modules/refresh_hotkey.lua`**  
  Binds `Alt+R`. Sends `⌥⌘E` (Empty Cache) then, after 1s, `⌘R` (Reload). Useful for Safari/Chrome dev workflows.

- **`modules/tab_navigation.lua` (Safari)**  
  Binds `Alt+S`. AppleScript grabs the front window’s tab titles & URLs; a `hs.chooser` lists them for quick jump.

- **`modules/app_navigation.lua`**  
  Binds `Alt+Z`. Enumerates running apps (non-hidden, with valid names) and shows a `hs.chooser` with app icon thumbnails; activates selected app.

- **`modules/aws_tab_monitor.lua` (Safari)**  
  Watches Safari activation/clicks; parses the active tab URL to extract an AWS account id and maps it to a friendly label (e.g., `🔵 fsm-preprod`). Shows alerts when the account changes. Mapping is in `accountMap`.

- **`modules/safari_window_manager.lua` & `modules/vscode_window_manager.lua`**  
  Use `hs.window.filter` to detect new/focused windows and move them to a **secondary display** when multiple screens are present (helpful external-monitor workflow).

- **`modules/teams_mouse.lua`**  
  Watches Microsoft Teams launch/terminate. While running, a timer posts tiny, natural mouse move events to keep presence active; stops when Teams quits.

- **`modules/teams_focus_restore.lua`**  
  Tracks the **last useful** Teams window (standard window with non-empty title). On Teams activation, re-focuses that window so you don’t land on an empty/splash window.

- **`modules/filezilla_caffeinate.lua`**  
  Watches FileZilla. When launched, enables `hs.caffeinate.set("displayIdle", true)` and shows a toast (“Display won’t sleep”). On quit, disables and clears the alert.

- **`modules/auto_lock.lua`**  
  Monitors **lid state** and triggers Apple Shortcuts to toggle Bluetooth accordingly (tries Shortcuts Events via AppleScript → CLI → URL scheme). Includes polling logic, helpful if system events don’t fire reliably.

- **`init.lua`**  
  Requires all modules, starts watchers (Auto Brightness, AWS, Safari/VSCode managers, Teams watchers, FileZilla caffeinate, Auto-Lock), and binds hotkeys.

## Configuration

- **Change hotkeys**  
  Edit the `hs.hotkey.bind` calls inside each module.

- **AWS account mapping** (`modules/aws_tab_monitor.lua`)  
  Update the `accountMap` table:

  ```lua
  local accountMap = {
    ["376714490571"] = "🔵 fsm-preprod",
    ["074882943170"] = "🟡 fsm-int",
    ["075373948405"] = "🟣 fsm-tooling",
    ["885460024040"] = "🧪 fsm-e2e",
    ["816634016139"] = "🔴 fsm-prod"
  }
  ```

- **Teams app name** (`modules/teams_focus_restore.lua`)  
  If you use a variant (e.g., “Microsoft Teams (work or school)”), adjust:

  ```lua
  local appName = "Microsoft Teams"
  ```

- **Bluetooth Shortcuts** (`modules/auto_lock.lua`)  
  Make sure you have Apple Shortcuts named exactly **“Bluetooth On”** and **“Bluetooth Off”**, or change the module to match your shortcut names.

- **Window placement**  
  The Safari/VS Code managers act only when at least two displays exist. If you prefer a specific display or geometry, tweak those modules (use `hs.screen.allScreens()` and `hs.geometry` helpers).

## Troubleshooting

- **Nothing happens on hotkeys**

  - Reload Hammerspoon config and check the console for prints.
  - Ensure Hammerspoon has **Accessibility** permission.

- **Bluetooth automation doesn’t run**

  - Confirm the Shortcuts exist and are named correctly.
  - The module falls back OSA → CLI → URL; ensure “Shortcuts” app is installed and allowed to run.

- **AWS account shows “Unknown”**

  - The module currently parses **Safari** tab URLs. Ensure you’re on an AWS Console URL and add your account id to `accountMap`.

- **Windows don’t move to the secondary display**
  - The managers only run when multiple screens are available and windows are **standard** and **visible**.

## Repository structure

```text
.hammerspoon/
├── init.lua
├── modules/
│   ├── app_navigation.lua
│   ├── auto_brightness.lua
│   ├── auto_lock.lua
│   ├── aws_tab_monitor.lua
│   ├── filezilla_caffeinate.lua
│   ├── launchpad_hotkey.lua
│   ├── refresh_hotkey.lua
│   ├── safari_window_manager.lua
│   ├── tab_navigation.lua
│   ├── teams_focus_restore.lua
│   ├── teams_mouse.lua
│   └── vscode_window_manager.lua
├── .vscode/
│   ├── launch.json
│   └── tasks.json
└── .github/CODEOWNERS
```

## 🧪 Optional CLI Integration

Set up a global terminal command to reload Hammerspoon from anywhere:

### ✅ Create an `hs` command

```bash
sudo tee /opt/homebrew/bin/hs > /dev/null <<'EOF'
#!/bin/bash
open -g -a "Hammerspoon" --args -r
EOF

sudo chmod +x /opt/homebrew/bin/hs
```

> This works on Apple Silicon. If you're on Intel, use `/usr/local/bin/hs`.

Now you can run:

```bash
hs
```

To reload the Hammerspoon configuration from the terminal.
