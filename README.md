# 🍎 Hammerspoon Configuration

This repository contains a modular configuration for [Hammerspoon](https://www.hammerspoon.org/) — a powerful automation tool for macOS, using Lua scripting. The goal is to provide practical automations like auto-lock, brightness control, app-based mouse keep-alive, smart window focus restore, and more.

---

## 📁 Structure

```
.hammerspoon/
├── init.lua                     # Main entry that loads all modules
├── modules/
│   ├── auto_brightness.lua      # Adjusts screen brightness automatically
│   ├── auto_lock.lua            # Locks screen when screen is lowered
│   ├── filezilla_caffeinate.lua # Keeps system awake if FileZilla is running
│   ├── teams_mouse.lua          # Moves mouse if Microsoft Teams is active
│   ├── window_cycle.lua         # Cycles windows within the current app
│   └── teams_focus_restore.lua  # Refocuses last meaningful window when app is reactivated
```

---

## ⚙️ Requirements

- macOS
- [Hammerspoon](https://www.hammerspoon.org/) installed
- Accessibility permissions granted to Hammerspoon (via System Settings > Privacy & Security)

---

## 🚀 Installation

1. **Clone this repository:**

   ```bash
   git clone https://github.com/orenatobr/.hammerspoon ~/.hammerspoon
   ```

2. **Open Hammerspoon and click “Reload Config”**

3. **Ensure Accessibility permissions are enabled**  
   - You will be prompted on first use if not already granted.

---

## 🧠 Features

- 🔁 **Window cycling**: Quickly switch between visible windows of the active app.
- 💡 **Auto-brightness**: Adapts screen brightness based on conditions.
- 🔒 **Auto-lock**: Locks screen when the lid or screen is lowered.
- 🖱️ **Mouse movement for Teams**: Prevents idle status while in Teams meetings.
- ☕ **FileZilla detection**: Keeps display awake if FileZilla is running.
- 🧭 **Restore last focused teams window**: When an app is reactivated (e.g., via Dock or Cmd+Tab), this module restores the last meaningful, non-empty window previously used — ideal for apps like Microsoft Teams that default to a less useful window.

---

## ⌨️ Example Hotkeys

| Action                | Shortcut                |
|-----------------------|-------------------------|
| Cycle app windows     | `Alt + A` / `option + A`|
| *(Other hotkeys configurable in code)*          |

---

## 📄 License

This project is MIT licensed.

---

Made for personal productivity and Mac automation fun ✨