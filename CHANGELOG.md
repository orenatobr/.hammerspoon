# Changelog

All notable changes to this fork are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versions are
`<upstream version>-rf.<n>`: the Hammerspoon version this fork is based on,
plus the fork's own revision. The latest release notes are generated from the
top section of this file.

## [1.1.1-rf.2] - 2026-11-20

### Changed

- Release asset is now `Hammerspoon-macos-universal.zip`, with a `.sha256` file next to it.
- `install.sh` verifies the checksum before installing.
- README: removed upstream badges, added a first launch section.
- Inherited upstream CI and label checker workflows only run on `Hammerspoon/hammerspoon`.

### Notes

- `v1.1.1-rf.2` and `v1.1.1-rf.3` from the first iteration were deleted and the sequence restarted at `rf.1`. Releases only go upward from here.

## [1.1.1-rf.1] - 2026-11-20

### Added

- Fork of [Hammerspoon/hammerspoon](https://github.com/Hammerspoon/hammerspoon) 1.1.1.
- Personal Lua config under `config/` (window management, hotkeys, lock screen,
  brightness, VS Code and Antigravity IDE helpers) with its test suite.
- One-line installer: `scripts/fork/install.sh`.
- `Fork release` workflow: builds an ad-hoc signed `Hammerspoon.app` and
  publishes it as the latest release, built from `main`.
- `main` protected by a ruleset: pull request with one approval, only the
  owner can bypass.
