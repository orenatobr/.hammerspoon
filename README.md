# 🍎 Hammerspoon Configuration

This repository contains a **modular configuration for [Hammerspoon](https://www.hammerspoon.org/)** — a powerful automation tool for macOS using Lua scripting.

It includes practical automations such as:

- Auto-lock when screen/lid closes
- Smart window focus restore for Microsoft Teams
- Auto-brightness control
- Safari and VSCode window positioning
- Hotkeys for Launchpad and hard-refresh
- App-specific keep-awake mechanisms

---

## 📁 Folder Structure

```text
.hammerspoon/
├── init.lua                          # Main entry that loads all modules
├── modules/
│   ├── auto_brightness.lua           # Adjusts screen brightness automatically
│   ├── auto_lock.lua                 # Locks screen when screen is lowered
│   ├── filezilla_caffeinate.lua      # Keeps system awake if FileZilla is running
│   ├── teams_mouse.lua               # Moves mouse if Microsoft Teams is active
│   ├── window_cycle.lua              # Cycles windows within the current app
│   ├── teams_focus_restore.lua       # Refocuses last meaningful window when app is reactivated
│   ├── launchpad_hotkey.lua          # Keyboard shortcut for lauchpad
│   ├── refresh_hotkey.lua            # Keyboard shortcut for refresh page
│   ├── aws_tab_monitor.lua           # Notifications for AWS account
│   ├── safari_window_manager.lua     # Sends Safari to the left half of the second screen
│   ├── vscode_window_manager.lua     # Sends VSCode to the right half of the second screen
│   ├── app_switcher.lua              # Custom app switcher with chooser
│   ├── safari_tab_switcher.lua       # Custom Safari tab switcher with chooser
```

---

## ⚙️ Requirements

- macOS (Apple Silicon compatible)
- [Hammerspoon](https://www.hammerspoon.org/) installed
- Accessibility permissions granted:
  - **System Settings → Privacy & Security → Accessibility**

---

## 🚀 Installation

1. **Install Hammerspoon via Homebrew:**

   ```bash
   brew install --cask hammerspoon
   ```

2. **Sync with remote if you already have the folder:**

   ```bash
   cd ~/.hammerspoon
   git init
   git remote add origin git@github.com:orenatobr/.hammerspoon.git
   git fetch origin
   git reset --hard origin/main
   ```

3. **Open Hammerspoon** and click **"Reload Config"** in the menu.

4. **Grant Accessibility Permissions**  
   You'll be prompted automatically if not already granted.

---

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

---

## 💻 VSCode Integration

Use a custom launch configuration to reload Hammerspoon directly from the **Run & Debug panel**.

### `.vscode/launch.json`

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "🔁 Reload Hammerspoon via CLI",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/noop.js",
      "preLaunchTask": "Reload Hammerspoon Config",
      "console": "integratedTerminal",
      "internalConsoleOptions": "neverOpen"
    }
  ]
}
```

> You can also create a shell task named `"Reload Hammerspoon Config"` in `.vscode/tasks.json`.

---

## 🧠 Features

- 🔁 **Window cycling**: Quickly switch between visible windows of the active app.
- ⌨️ **Launch Pad Shortcut**: Keyboard shortcut for Launch Pad.
- ⌨️ **Refresh page**: Keyboard shortcut for refresh page (empty cache + reload page).
- 💡 **Auto-brightness**: Adapts screen brightness based on conditions.
- 🔒 **Auto-lock**: Locks screen when the lid or screen is lowered.
- 🖱️ **Mouse movement for Teams**: Prevents idle status while in Teams meetings.
- ☕ **FileZilla detection**: Keeps display awake if FileZilla is running.
- 🧭 **Restore last focused Teams window**: When an app is reactivated (e.g., via Dock or Cmd+Tab), this module restores the last meaningful, non-empty window previously used — ideal for apps like Microsoft Teams that default to a less useful window.
- 🧭 **AWS Tab Monitor**: Add AWS account detection in Safari tabs with custom alerts.
- 🪟 **Auto-window positioning (multi-monitor)**:
  - Safari → moves to the **left half** of the second monitor
  - VSCode → moves to the **right half** of the second monitor
- 🔀 **App Switcher**: `Option + Z` opens a custom app switcher with keyboard navigation and chooser UI.
- 📑 **Safari Tab Switcher**: `Option + S` opens a searchable chooser for all open Safari tabs.

---

## ⌨️ Example Hotkeys

| Action                | Shortcut                |
|-----------------------|-------------------------|
| Cycle app windows     | `Alt + C` / `option + C`|
| Launchpad             | `Alt + A` / `option + A`|
| Refresh page          | `Alt + R` / `option + R`|
| App Switcher          | `Alt + Z` / `option + Z`|
| Safari Tab Switcher   | `Alt + S` / `option + S`|

---

## 📜 License

This project is licensed under the **MIT License**.

---

Crafted for personal productivity and Mac automation fun ✨  
Feel free to fork and adapt to your workflow!
