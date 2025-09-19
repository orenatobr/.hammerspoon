# Hammerspoon Productivity Toolkit

Automations and hotkeys for macOS using [Hammerspoon](https://www.hammerspoon.org/).
This config provides advanced window management, app-aware automations, presence helpers, and productivity shortcuts for common macOS workflows.

> On load you should see: `✅ Hammerspoon Productivity Toolkit initialized.` and an alert “🎉 All automations active”.

## Contents

- [Features](#features)
- [Requirements and Environment Preparation](#requirements-and-environment-preparation)
- [Hotkeys](#hotkeys)
- [Modules](#modules)
- [Configuration and Troubleshooting](#configuration-and-troubleshooting)
- [Repository Structure](#repository-structure)
- [Optional CLI Integration](#optional-cli-integration)

## Features

### Window & App Automation

- **Auto brightness**: Adjusts display brightness based on power source (AC vs Battery).
- **Window cycle (per app)**: Cycle through the current app’s windows with a hotkey.
- **Launchpad shortcut**: Quick open Launchpad.
- **Browser refresh macro**: Clear cache then reload (Safari/Chrome dev workflows).
- **Safari tab switcher**: Fuzzy-pick any open Safari tab via chooser.
- **App switcher (chooser)**: Fuzzy-pick any running app to focus.
- **AWS Console account detector (Safari)**: Detects the current AWS account from the tab URL and shows a mapped label (e.g., `🔴 fsm-prod`).
- **Safari & VS Code window placement**: Auto-move new/focused windows to a secondary display when available.

### Presence & Power Helpers

- **Teams presence keep-alive**: Gentle mouse “jiggle” while Microsoft Teams is running to prevent away status.
- **Teams focus restore**: When Teams activates, re-focus the last useful Teams window (not the empty/splash window).
- **FileZilla caffeinate**: Prevents display sleep while FileZilla is running; reverts when it closes.
- **Lid/Bluetooth automation (Shortcuts)**: Reacts to lid state changes and triggers named Shortcuts to toggle Bluetooth (uses Apple Shortcuts via AppleScript/CLI/URL as fallbacks).

### Extensibility & Customization

- Modular design: Each feature is a separate Lua module for easy customization.
- Hotkeys and app lists are easily configurable.

## Requirements and Environment Preparation

### System

- **macOS** (latest recommended)
- **Hammerspoon** (latest from [hammerspoon.org](https://www.hammerspoon.org/))

### Permissions

- **Accessibility**: Required for window control, key events, and mouse automation.
  - Go to **System Settings → Privacy & Security → Accessibility** and enable **Hammerspoon**.
- **Automation**: May prompt when Hammerspoon uses AppleScript/Shortcuts.

### Apps

- **Safari** (for tab switcher, AWS detector)
- **Visual Studio Code** (for window placement)
- **Microsoft Teams** (for presence keep-alive, focus restore)
- **FileZilla** (for caffeinate)
- **Apple Shortcuts** (optional, for Bluetooth automation)
  - Create Shortcuts named **“Bluetooth On”** and **“Bluetooth Off”**

### Recommended Preparation Steps

1. **Install Hammerspoon** and open it once to grant permissions.
2. **Clone this repo** into your Hammerspoon directory:

   ```bash
   git clone git@github.com:orenatobr/.hammerspoon.git
   ```

   _(Or copy the files there.)_
3. **Reload the config**:
   - Hammerspoon menu → **Reload Config**, or
   - `hs.reload()` from the Hammerspoon console.
4. **Grant Accessibility permissions** (see above).
5. **(Optional) Prepare Apple Shortcuts** for Bluetooth automation.
6. **(Optional) Install recommended apps** for full feature coverage.

## Hotkeys

| Hotkey    | Module                 | Action                                                               |
| --------- | ---------------------- | -------------------------------------------------------------------- |
| `Alt + C` | `window_cycle.lua`     | Cycle through the current app’s standard/visible windows.            |
| `Alt + A` | `launchpad_hotkey.lua` | Open Launchpad.                                                      |
| `Alt + R` | `refresh_hotkey.lua`   | Clear browser cache (`⌥⌘E`), then reload (`⌘R`) after 1s.            |
| `Alt + S` | `tab_navigation.lua`   | Open chooser of **Safari** tabs (title + URL) and jump to selection. |
| `Alt + Z` | `app_navigation.lua`   | Open chooser of **running apps** with icons; activate selection.     |

> You can change any hotkey inside each module’s `hs.hotkey.bind({...}, "KEY", ...)`.

## Modules

Each feature is implemented as a separate Lua module in the `modules/` directory. Here’s a summary:

- **`auto_brightness.lua`**: Uses battery watcher to set brightness based on power source.
- **`window_cycle.lua`**: Cycles through current app’s windows.
- **`launchpad_hotkey.lua`**: Hotkey to open Launchpad.
- **`refresh_hotkey.lua`**: Hotkey to clear browser cache and reload.
- **`tab_navigation.lua`**: Chooser for Safari tabs.
- **`app_navigation.lua`**: Chooser for running apps.
- **`aws_tab_monitor.lua`**: Detects AWS account in Safari tab and shows mapped label.
- **`safari_window_manager.lua`**: Moves Safari windows to secondary display.
- **`vscode_window_manager.lua`**: Moves VS Code windows to secondary display.
- **`teams_focus_restore.lua`**: Restores focus to last useful Teams window.
- **`teams_mouse.lua`**: Keeps Teams presence active with mouse jiggle.
- **`filezilla_caffeinate.lua`**: Prevents display sleep while FileZilla is running.
- **`auto_lock.lua`**: Triggers Bluetooth Shortcuts on lid state changes.
- **`init.lua`**: Loads all modules and binds hotkeys.

## Configuration and Troubleshooting

- **Change hotkeys**: Edit the `hs.hotkey.bind` calls inside each module.
- **AWS account mapping** (`modules/aws_tab_monitor.lua`): Update the `accountMap` table.
- **Teams app name** (`modules/teams_focus_restore.lua`): Adjust the `appName` variable if you use a Teams variant.
- **Bluetooth Shortcuts** (`modules/auto_lock.lua`): Ensure Shortcuts are named **“Bluetooth On”** and **“Bluetooth Off”**.
- **Window placement**: Tweak display logic in Safari/VS Code managers as needed.
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

## Repository Structure

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

## Optional CLI Integration

Set up a global terminal command to reload Hammerspoon from anywhere:

### Create an `hs` command

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
