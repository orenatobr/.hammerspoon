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
├── init.lua                          # Main entry point that loads all modules
├── modules/
│   ├── auto_brightness.lua           # Adjusts screen brightness automatically
│   ├── auto_lock.lua                 # Locks screen when lid is closed or screen is lowered
│   ├── filezilla_caffeinate.lua      # Keeps system awake when FileZilla is running
│   ├── teams_mouse.lua               # Moves mouse if Microsoft Teams is active
│   ├── window_cycle.lua              # Cycles through app windows
│   ├── teams_focus_restore.lua       # Restores last focused Teams window on reactivation
│   ├── launchpad_hotkey.lua          # Keyboard shortcut for Launchpad
│   ├── refresh_hotkey.lua            # Keyboard shortcut for full page refresh
│   ├── aws_tab_monitor.lua           # Detects AWS account in Safari tabs
│   ├── safari_window_manager.lua     # Sends Safari to the left half of the second screen
│   └── vscode_window_manager.lua     # Sends VSCode to the right half of the second screen
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

## ✨ Features Overview

| Feature                        | Description                                                   |
| ------------------------------ | ------------------------------------------------------------- |
| 🔁 Window cycling              | Quickly switch between visible windows of the active app      |
| ⌨️ Launchpad hotkey            | Opens macOS Launchpad with a shortcut                         |
| 🔄 Refresh page hotkey         | Full browser page refresh (empty cache)                       |
| 💡 Auto-brightness             | Dynamically adjusts screen brightness                         |
| 🔒 Auto-lock                   | Locks screen when lid is closed or screen is lowered          |
| 🖱️ Teams anti-idle             | Prevents Teams from marking you away by auto-moving the mouse |
| ☕ FileZilla keep-awake        | Keeps system awake when FileZilla is running                  |
| 🧭 Teams focus restore         | Brings back last useful Teams window when app is reactivated  |
| 🧭 AWS tab detection in Safari | Alerts when an AWS account is detected in open Safari tabs    |
| 🪟 Multi-monitor window layout | Safari and VSCode auto-positioning on external displays       |

---

## ⌨️ Default Hotkeys

| Action                                         | Shortcut                 |
| ---------------------------------------------- | ------------------------ |
| Cycle app windows                              | `Alt + C` / `Option + C` |
| Launchpad                                      | `Alt + A` / `Option + A` |
| Refresh page                                   | `Alt + R` / `Option + R` |
| _(Other hotkeys are configurable in the code)_ |                          |

---

## 📜 License

This project is licensed under the **MIT License**.

---

Crafted for personal productivity and Mac automation fun ✨  
Feel free to fork and adapt to your workflow!
