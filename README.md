# Hammerspoon Productivity Toolkit

Automations and hotkeys for macOS using [Hammerspoon](https://www.hammerspoon.org/).

> On load you should see: `✅ Hammerspoon Productivity Toolkit initialized.` and an alert “🎉 All automations active”.

## How to Install Hammerspoon

1. Go to the official website: [hammerspoon.org](https://www.hammerspoon.org/)
2. Download the latest release for macOS.
3. Open the downloaded `.zip` file and drag **Hammerspoon.app** to your **Applications** folder.
4. Launch Hammerspoon from Applications.
5. Grant Accessibility permissions when prompted (System Settings → Privacy & Security → Accessibility → enable Hammerspoon).
6. (Optional) Add Hammerspoon to your Dock or set it to launch at login for convenience.

For more details, see the [Getting Started guide](https://www.hammerspoon.org/go/).

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
- **Google Meet single-window enforcement**: Automatically closes duplicate Google Meet (Chrome App) windows, keeping only the one you just opened or focused.

### Presence & Power Helpers

- **Teams presence keep-alive**: Gentle mouse “jiggle” while Microsoft Teams is running to prevent away status.
- **Teams focus restore**: When Teams activates, re-focus the last useful Teams window (not the empty/splash window).
- **FileZilla caffeinate**: Prevents display sleep while FileZilla is running; reverts when it closes.
- **Lid/Bluetooth automation (Shortcuts)**: Reacts to lid state changes and triggers named Shortcuts to toggle Bluetooth (uses Apple Shortcuts via AppleScript/CLI/URL as fallbacks).

### Extensibility & Customization

- Modular design: Each feature is a separate Lua module for easy customization.
- Hotkeys and app lists are easily configurable.

## Hotkeys

| Hotkey    | Module                  | Action                                                               |
| --------- | ----------------------- | -------------------------------------------------------------------- |
| `Alt + C` | `window_cycle.lua`      | Cycle through the current app’s standard/visible windows.            |
| `Alt + A` | `launchpad_hotkey.lua`  | Open Launchpad.                                                      |
| `Alt + R` | `refresh_hotkey.lua`    | Clear browser cache (`⌥⌘E`), then reload (`⌘R`) after 1s.            |
| `Alt + S` | `tab_navigation.lua`    | Open chooser of **Safari** tabs (title + URL) and jump to selection. |
| `Alt + Z` | `app_navigation.lua`    | Open chooser of **running apps** with icons; activate selection.     |
| `Alt + F` | `relaunch_terminal.lua` | Relaunch the active integrated terminal in VS Code.                  |

> You can change any hotkey inside each module’s `hs.hotkey.bind({...}, "KEY", ...)`.

## Modules

Each feature is implemented as a separate Lua module in the `modules/` directory. Here’s a summary:

- **`auto_brightness.lua`**: Uses battery watcher to set brightness based on power source.
- **`window_cycle.lua`**: Cycles through current app’s windows.
- **`launchpad_hotkey.lua`**: Hotkey to open Launchpad.
- **`refresh_hotkey.lua`**: Hotkey to clear browser cache and reload.
- **`tab_navigation.lua`**: Chooser for Safari tabs.
- **`app_navigation.lua`**: Chooser for running apps.
- **`safari_window_manager.lua`**: Moves Safari windows to secondary display.
- **`vscode_window_manager.lua`**: Moves VS Code windows to secondary display.
- **`google_meet_window_manager.lua`**: Closes duplicate Google Meet (Chrome App) windows, keeping only the most recently opened/focused one.
- **`teams_focus_restore.lua`**: Restores focus to last useful Teams window.
- **`teams_mouse.lua`**: Keeps Teams presence active with mouse jiggle.
- **`filezilla_caffeinate.lua`**: Prevents display sleep while FileZilla is running.
- **`auto_lock.lua`**: Triggers Bluetooth Shortcuts on lid state changes.
- **`safari_pip_detector.lua`**: Detects Safari Picture-in-Picture (PIP) window and automatically moves it to the bottom-left of the internal screen. Continuously monitors for the PIP window and repositions it for optimal visibility. Useful for keeping Safari PIP out of the way and always in a predictable location. Integrates with the main config and requires Accessibility permissions.
- **`reset_vscode.lua`**: Reloads the VS Code window and resets sidebar/panel sizes.
- **`relaunch_terminal.lua`**: Relaunches the active integrated terminal in VS Code via its built-in Command Palette action ("Relaunch Active Terminal") — no custom `keybindings.json` required.
- **`init.lua`**: Loads all modules and binds hotkeys.

## Configuration and Troubleshooting

- **Change hotkeys**: Edit the `hs.hotkey.bind` calls inside each module.
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
│   ├── filezilla_caffeinate.lua
│   ├── google_meet_window_manager.lua
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

sudo chmod +x /opt/homebrew/bin/hs

### Create an `hs` command

```bash
sudo tee /opt/homebrew/bin/hs > /dev/null <<'EOF'
#!/bin/bash
open -g -a "Hammerspoon" --args -r
EOF
```

sudo chmod +x /opt/homebrew/bin/hs

```bash

> This works on Apple Silicon. If you're on Intel, use `/usr/local/bin/hs`.

Now you can run:

```bash
hs
```

To reload the Hammerspoon configuration from the terminal.

## Development & Pre-commit Environment Setup

To run all pre-commit hooks (lint, tests, markdown checks) locally:

1. **Install dependencies**
   - Install [Homebrew](https://brew.sh/) (if not already installed)
   - Install Python (for pre-commit):

     ```bash
     brew install python
     ```

   - Install Node.js (for markdownlint):

     ```bash
     brew install node
     ```

   - Install Lua and LuaRocks:

     ```bash
     brew install lua luarocks
     luarocks install busted
     luarocks install luacheck
     luarocks install luacov
     ```

   - Install pre-commit:

     ```bash
     pip3 install pre-commit
     ```

2. **Install pre-commit hooks**
   - In your repo root:

     ```bash
     pre-commit install
     ```

   - This will enable automatic linting, testing, and markdown checks on every commit.

3. **Run all hooks manually**
   - You can test all hooks before committing:

     ```bash
     pre-commit run --all-files
     ```

4. **What gets checked**
   - **Lua lint**: `luacheck modules`
   - **Lua tests**: `busted tests/ --pattern='test_.*.lua'`
   - **Markdown lint**: `npx markdownlint-cli '**/*.md'`

5. **Troubleshooting**
   - If you see errors about missing commands, ensure you installed all dependencies above.
   - For markdownlint line length errors, see `.markdownlint.json` to adjust rules.
