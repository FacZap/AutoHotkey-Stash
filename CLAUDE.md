# CLAUDE.md

Guidance for working in this repository.

## What this is

A personal collection of **AutoHotkey (AHK)** scripts for Windows productivity:
global hotkeys, hotstrings (autotext), media/volume/brightness control, window
management, auto-clicking, timers, and small GUIs. It is not an application —
each `.ahk` file is a standalone script run by the AutoHotkey interpreter. There
is no build step, no tests, and no git repository.

Comments and UI strings are mostly in **Spanish**; match that when editing
existing files.

## AHK v1 vs v2 — check before editing

The repo mixes both major AutoHotkey versions, which have **incompatible
syntax**. Always confirm a file's version before editing:

- **v2** files start with `#Requires AutoHotkey v2...`. They use function-call
  syntax (`Send("...")`, `MyGui := Gui()`, `WinGetTitle("ahk_id " id)`),
  `&ref` output params, and fat-arrow callbacks. Examples:
  `ahk_STARTUP/AHK_Manager.ahk`, `new_txt.ahk`, `url_firefox.ahk`,
  `Macro.Recorder.ahk`.
- **v1** files have no `#Requires` (or require v1) and use command syntax
  (`Send, ...`, `Gui, Add, ...`, `WinGetTitle, out, ...`), `%var%` expansion,
  and `Gosub`/labels. Most root scripts and `ahk_STARTUP/!_STARTUP.ahk` are v1.

Do not introduce v2 idioms into a v1 file or vice versa — pick the syntax the
file already uses.

## Layout

- **Root `*.ahk`** — individual standalone scripts (one feature each), e.g.
  `AutoClicker_CtrlAltJ.ahk`, `ScrollBoost.ahk`, `auto_coolboost*.ahk`,
  `tabby*.ahk` (tab-cycling variants), `ctrl_modifier*.ahk`.
- **`ahk_STARTUP/`** — scripts intended to run at login.
  - `!_STARTUP.ahk` is the **main always-on script**: media keys, date/time
    hotstrings (`SendNow()`), case-conversion clipboard helpers, the calendar
    GUI (`Win+Numpad5`), the conversation counter, and the `Win+Alt+S` timer.
    It `#Include`s `!_personal.ahk` (optional, gitignore-worthy: holds private
    data like emails/IDs — do not commit or invent its contents).
  - `AHK_Manager.ahk` (v2) — a GUI to reload/suspend/pause/kill running AHK
    scripts; launched via `run_Manager.ahk` (`Ctrl+Alt+R`).
  - `!_contained/` — smaller single-purpose scripts, some superseded by
    `!_STARTUP.ahk`.
- **`ahk_NO/`** — scripts currently **not in use** (disabled/archived). Don't
  assume these are active.
- **`autohotkey 26-08-24 iea/`** — an older snapshot of many small v1 scripts.
- **`^RUN_starters.ahk` / `^CLOSE_starters.ahk`** — batch launch/close helpers
  that reference scripts by hardcoded `C:\autohotkey\...` paths (an older
  location, not this folder).
- **Bundled third-party tools** (treat as vendored, do not edit):
  `keypirinha-2.26-full-portable/` (launcher), `RBTray/` (minimize-to-tray),
  `Macro.Recorder.exe`, `emoji.exe`.
- `relevamiento_ahk.txt` — the author's working notes / inventory of hotkeys.
- `Atajos_AHK_cheatsheet.html` — a generated cheat-sheet of shortcuts.

## Running / testing a script

There is no automated test harness — scripts are verified by running them and
pressing the hotkeys. To run one, the AutoHotkey interpreter must be installed;
launch a script by double-clicking it or via `Run "path\to\script.ahk"`. Use the
correct interpreter version for the file (v1 vs v2). `AHK_Manager.ahk` is the
quickest way to reload/kill running scripts during iteration.

## Conventions

- One concern per script in the root; `!_STARTUP.ahk` is the exception (an
  aggregation of many always-on hotkeys, organized into `; ===` comment
  sections — keep that sectioned structure when adding to it).
- v1 hotstrings here use prefixes like `k...` for dates and `:R*?:` / `:X*?:`
  option flags; follow the existing naming when adding autotext.
- User-facing feedback is shown with `ToolTip` plus a self-clearing timer
  (`QuitarTooltip`); reuse that pattern rather than `MsgBox` for transient notices.
- Hardcoded absolute paths under `C:\Users\fzpat\...` are common; preserve the
  user's actual paths when editing.
