# 🛠️ Hammerspoon Configuration

This repository contains a custom [Hammerspoon](https://www.hammerspoon.org/) configuration script written in Lua, designed to automate and enhance macOS productivity. It includes automatic brightness control, smart window switching, application-aware "Caffeinate" management, and a Microsoft Teams activity simulator.

---

## 📋 Features

### 🔋 Auto Brightness Based on Power Source
- Monitors battery source every 5 seconds.
- Sets brightness to `100%` when on AC power, `50%` when on battery.

### 🪟 Smart Window Switching (`Alt + A`)
- Cycles through visible and standard windows of the currently focused application.
- Deterministic sorting ensures consistent behavior.

### ☕ Auto Caffeinate for FileZilla
- Keeps display awake (`caffeinate`) while FileZilla is running.
- Checks every 5 seconds and toggles display sleep prevention accordingly.
- Displays visual alerts and logs changes.

### 🖱️ Mouse Activity Simulator for Microsoft Teams
- Detects if Microsoft Teams is running.
- Every 60 seconds, moves the mouse cursor by ±10 pixels in a random direction.
- Ensures the movement stays within visible screens (multi-monitor safe).
- Prevents Teams from marking user as "Away".

---

## 🧠 How It Works

Each block of functionality is encapsulated in clearly documented Lua functions. Timers run periodic checks in the background, and actions are taken accordingly based on application state or system conditions.

---

## 🚀 Getting Started

### 1. Clone or symlink into your Hammerspoon config folder
```bash
git clone git@github.com:orenatobr/.hammerspoon.git ~/.hammerspoon
```

Or, if you're versioning locally:

```bash
ln -s /path/to/your/repo ~/.hammerspoon
```

### 2. Reload Hammerspoon
Click the Hammerspoon icon in the menu bar and select **"Reload Config"**.

---

## 📎 Dependencies

- macOS
- [Hammerspoon](https://www.hammerspoon.org/) installed
- Microsoft Teams and/or FileZilla installed (for app-specific behaviors)

---

## 📁 Structure

All logic is contained in a single `init.lua` file:

- `Power Source Monitor`: Adjusts brightness based on AC/Battery.
- `Window Cycler`: Hotkey to rotate visible windows of active app.
- `FileZilla Watchdog`: Keeps display awake when FileZilla is active.
- `Teams Mouse Jiggler`: Prevents idle status in Teams.

---

## 🧪 Customization

You can easily change:
- Brightness levels
- Hotkey combination (`Alt + A`)
- Monitored app (`FileZilla`, `Microsoft Teams`)
- Idle simulation interval (default 60s)

---

## 🔒 Privacy Note

No personal data is collected or sent anywhere. All monitoring and actions occur locally on your machine.

---

## 📄 License

MIT License — feel free to adapt this setup to your own workflow!

---

## ✨ Author

Renato F. Pereira  
Senior Data Scientist & Mac automation enthusiast  
🔗 [LinkedIn](https://www.linkedin.com/in/orenatobr)
