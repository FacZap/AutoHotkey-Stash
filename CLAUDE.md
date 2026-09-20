# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

This is the **personal-laptop** branch (`personal_v2_merged`) of
`FacZap/AutoHotkey-Stash`: the unified v2 master from the `workMacroRecorder`
branch, adapted to this machine, plus the personal laptop's own peripheral
scripts. What came from where and what was dropped is in `MERGE_NOTES.md`.
The live copy on the laptop lives at `C:\Users\fzpat\Desktop\ahk`.

Comments and UI strings are mostly in **Spanish**; match that when editing.

## Running Scripts

AutoHotkey scripts are run directly — there is no build step. The laptop has
AHK v1.1.37 and v2.0.19 installed side by side (the `.ahk` association goes
through the AutoHotkey UX launcher, which picks the version from `#Requires`).

```powershell
# Run the master (v2)
& "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe" ".\^^AHK_Unified_Master.ahk"

# Syntax-check without running (catches duplicate hotkeys, bad key names, includes)
& "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe" /ErrorStdOut /validate ".\^^AHK_Unified_Master.ahk"
```

To test a modified script: terminate the running instance, then launch the
updated file. `Ctrl+Alt+R` opens the Manager GUI embedded in the master
(Reload/Suspend/Pause/Kill for any running AHK process).

## AHK v1 vs v2 — check before editing

The repo mixes both versions, which have **incompatible syntax**. v2 files start
with `#Requires AutoHotkey v2...` (function-call syntax, `&ref`, fat arrows); v1
files have no `#Requires` and use command syntax (`Send, ...`, `%var%`,
`Gosub`). Never mix idioms — use the syntax the file already has. v1 and v2
cannot share a process, which is why the peripherals below stay separate.

## Architecture

### Primary entry point

`^^AHK_Unified_Master.ahk` (v2.0.18+) is the consolidated always-on script. It
replaces both the work starter chain and the personal
`ahk_STARTUP/!_STARTUP.ahk` (v1), which is kept only as a fallback — do not run
both at once, their hotkeys overlap.

It `#Include`s `ahk_STARTUP/!_personal.ahk` (optional, `*i`): private hotstrings
(`kfz`, `kdni`, `kcel`, …). Do not duplicate those hotstrings in the master
(v2 refuses to load with duplicates) and do not invent or print their contents.

### Personal-laptop adaptations inside the master

- **Firefox, not Chrome**: `Ctrl+Alt+G` / `Ctrl+Alt+Shift+G` open the sheet in
  Firefox; `kill_all` (`Ctrl+Shift+Alt+K`) also spares `firefox.exe`;
  `find_google_calendar.ini` and `KillBrowsers/kill_preferences.ini` default to
  Firefox; `Ctrl+Shift+A` inside Firefox types `@tabs `. Tab features that read
  titles via UIA need Firefox accessibility enabled.
- **Brightness**: `RAlt & PgDn` = +10, `RAlt & PgUp` = −10 (same direction as
  the old `ahk_STARTUP/Brightness.ahk`), plus work's `Win+,` / `Win+.` (±5).
  All go through `AdjustScreenBrightness()` (WMI).
- **Macro recorder**: the *simple* one. `Win+F3` and the Manager's
  `Macro Recorder` button launch `Macro.Recorder.exe` (source:
  `Macro.Recorder.ahk`, v2; `F1` records/stops/plays). Work's big
  `MacroRecorder.ahk` was intentionally not brought over.
- **Section "Atajos de la laptop personal"**: hotkeys ported from the old
  `!_STARTUP.ahk` that did not collide with work's (AltGr+Numpad media,
  `AltGr+{`/`AltGr+-` max/min, `Alt+F9` Matlab, `Ctrl+Alt+D` PDF fix,
  extra date hotstrings, …). `Win+|` / `Win+Shift+|` are aliases of the Wise
  Reminder / Hourglass launchers.
- `Win+C` (Show_Time) uses **7** Right presses (5 on the work PC).
- Nothing external is launched at startup (work launched RBTray + Wise Reminder).

### Hotkey registry and reference docs — keep in sync

`gHKSections` in the master lists every hotkey for the `Hotkeys…` toggle menu.
Every `hk` must match the real hotkey string exactly. Hotkeys defined inside a
`#HotIf` can't be toggled with `Hotkey()`, so they use `type: "flag"` and read
`HKEnabled("section.item")` in their `#HotIf` (e.g. `firefox.tabs`).

The same bindings are documented in:

| File | Role |
|---|---|
| `AHK_Unified_Master_Referencia_ie.html` | What `Win+Shift+?` opens. Plain CSS (IE engine). |
| `AHK_Unified_Master_Referencia.html` | Same content, modern CSS; source of the PDF. |
| `AHK_Unified_Master_Referencia.pdf` | Printed from the modern HTML. |

The two HTMLs must be edited together. Regenerate the PDF with:

```powershell
& "C:\Program Files\Google\Chrome\Application\chrome.exe" --headless=new --disable-gpu --no-pdf-header-footer --virtual-time-budget=8000 "--print-to-pdf=$PWD\AHK_Unified_Master_Referencia.pdf" "file:///$($PWD -replace '\\','/')/AHK_Unified_Master_Referencia.html"
```

### Auxiliary script launcher

On startup the master opens `ShowAuxScriptsGui()` to pick which separate
scripts to launch (also from the Manager's `Aux Scripts…`). `aux-scripts.ini`
(gitignored, per machine) stores the ticks and the startup mode (`ask` | `auto`
| `off`).

| Script | v | Notes |
|---|---|---|
| `traymond-timer/traymond-timer.ahk` | v1 | `Win+Shift+Z` hide + countdown. Needs `Traymond.exe` running (the laptop starts it from the Startup folder). |
| `traymond-timer/restore-at-fixed-time.ahk` | v1 | Daily 16:40 restore-all (work schedule; untick if unwanted). |
| `ClipboardOCR.ahk` | v2 | `Ctrl+Alt+O`; depends on vendored `OCR.ahk`. |
| `ColdTurkeyActivado.ahk` | v2 | No hotkeys. |
| `GreenshotSlowMouse.ahk` | v2 | No hotkeys. |
| `KillBrowsers/KillBrowsers.ahk` | v2 | `Ctrl+Alt+K`. |
| `SimpleReminders/SimpleReminders.ahk` | v2 | `Win+Alt+Z`. |
| `RhythmGame.ahk` | v2 | Window-scoped keys only. |

Launching goes through the UX launcher with `/Launch` (see `AuxLaunchCmd()`);
`A_AhkPath` can't be used because it is the v2 exe running the master.

### Window cycler (windows + browser tabs)

One list for windows and tabs (`Win+F4` cycles, `Ctrl+Win+F4` filters). Tab
entries reuse the timed-tab UIA helpers (`GetActiveBrowserTabName`,
`NormalizeTabName`, `FindTimedTabTarget`, `ActivateTimedTab`); changing them
affects both features. `CleanClosedWindows()` prunes only window entries.

## Personal peripheral scripts (standalone, mostly v1)

Kept as-is at the root; they are **not** part of the master and are run by hand:
`batt-limit-alpha.ahk`, `auto_coolboost*.ahk`, `coolbooster.ahk`, `tabby*.ahk`,
`vlc.ahk`, `AutoClicker_CtrlAltJ.ahk`, `ScrollBoost.ahk`, `emoji.ahk`, etc.
Known collisions with the master (don't run them together):
`coolbooster.ahk` (`^!w` = master's Ctrl+Alt+W), `FF_ctrlA.ahk` (`^!a` =
Play/Pausa), `ahk_STARTUP/AltWindowsControl.ahk` and
`ahk_STARTUP/Cycler-Window-v3.ahk` (duplicate master features).

## Layout

- Root: the master, its aux scripts, work's individual scripts (reference
  copies of what the master contains), and the personal peripherals.
- `ahk_STARTUP/` — the old personal v1 startup set (`!_STARTUP.ahk`,
  `AHK_Manager.ahk`, `Brightness.ahk`, …) plus `!_personal.ahk`, which the
  master includes.
- `ahk_NO/`, `not in use/`, `semi-uso/`, `broken/`, `autohotkey 26-08-24 iea/`
  — archived / not active.
- Vendored (don't edit): `keypirinha-2.26-full-portable/`, `RBTray/`,
  `RBTray-4_3/`, `ahk2_lib/`, `UIA.ahk`, `OCR.ahk`, `Traymond.exe`,
  `Macro.Recorder.exe`, `emoji.exe`.
- `^RUN_starters.ahk` / `^CLOSE_starters.ahk` / `^RUN_MANAGER.ahk` — legacy
  launchers with `C:\autohotkey\...` paths (work PC); superseded by the master.

## Hardcoded paths

- Firefox: `C:\Program Files\Mozilla Firefox\firefox.exe`
- VS Code: `C:\Users\<user>\AppData\Local\Programs\Microsoft VS Code\Code.exe`
- Wise Reminder: `C:\Program Files (x86)\Wise\Wise Reminder\WiseReminder.exe`
- Hourglass: Start-menu shortcut under `C:\ProgramData\...\Hourglass\`
- `open-program-GUI.ini` overrides per-program paths (OBS and Pointofix are not
  installed on the laptop; edit their path from the GUI if needed).
