# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
adheres to [Semantic Versioning](https://semver.org/). See `VERSION.md` for
the release process.

## [Unreleased]

## [0.3.0] - 2026-10-15

### Added

- ide: VS Code modules also work with Antigravity IDE (#22). A new `ide_apps` helper detects both editors by bundle ID and prefers the focused one. `reset_vscode` (Alt+V), `relaunch_terminal` (Alt+F) and `vscode_window_manager` use it, and Antigravity IDE joins the keepalive and maximize lists.

## [0.2.1] - 2026-10-13

### Fixed

- passwords-hotkey: Return copies the masked password through its copy menu (#19). Clicking the field only revealed it, so the clipboard was never set.

## [0.2.0] - 2026-10-13

### Added

- passwords-hotkey: navigate the Passwords popover with the keyboard after Option+P (#18). Up/Down highlight a row, Right opens the item, Left goes back, Return copies the password and closes the popover, Escape closes it.

## [0.1.2] - 2026-10-13

### Fixed

- passwords-hotkey: retry on launch and add a Secure Input fallback (#17).

## [0.1.1] - 2026-10-12

### Fixed

- security: harden AppleScript and shell calls, pin CI dependencies and add gitleaks (#16).

## [0.1.0] - 2026-10-10

### Added

- Test suite for the modules (#2).
- reset_vscode module with the Option+V hotkey (#6).
- relaunch_terminal module with the Option+F hotkey (#7, #9).
- lid_audio_mute: mute audio on lid close, unmute on lid open (#8).
- google_meet_window_manager: enforce a single Meet window (#11).
- refresh_hotkey: clear browser storage before reload (#14).
- passwords_hotkey: open Passwords quick access with Alt+P (#15).
- Improved lid-close behavior and keepalive coordination (#3).

### Changed

- Unneeded modules commented out in `init.lua` (#1).
- Reduced energy use in background modules (#5).

### Fixed

- relaunch_terminal: correct the keybinding and use the native command palette action (#10, #12).
- google_meet_window_manager: do not close the Meet window on screen share (#13).
- Restored a green test-and-lint run after #3 (#4).

[Unreleased]: https://github.com/orenatobr/.hammerspoon/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/orenatobr/.hammerspoon/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/orenatobr/.hammerspoon/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/orenatobr/.hammerspoon/compare/v0.1.2...v0.2.0
[0.1.2]: https://github.com/orenatobr/.hammerspoon/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/orenatobr/.hammerspoon/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/orenatobr/.hammerspoon/releases/tag/v0.1.0
