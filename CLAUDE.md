# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Running Scripts

AutoHotkey scripts are run directly — there is no build step.

```powershell
# Run a script (requires AutoHotkey installed)
AutoHotkey.exe .\^^AHK_Unified_Master.ahk

# Reload a running script from within AHK (send Reload message via AHK_Manager GUI)
# Ctrl+Alt+R opens the AHK Manager GUI for managing all running scripts
```

To test a modified script: terminate the running instance, then launch the updated file. The AHK_Manager GUI (AHK_Manager.ahk) provides Reload/Suspend/Pause/Kill controls for any running AHK process.

## Architecture

### Primary entry point

`^^AHK_Unified_Master.ahk` is the consolidated master script (~1000 lines, AHK v2.0.18+). It replaces 23+ individual scripts and is the preferred way to run all automation in a single process. Individual `.ahk` files still exist alongside it for reference, development, or standalone use.

### Why two forms exist (individual scripts + unified master)

AHK v1 and v2 cannot run in the same process. The master was created to consolidate everything into one v2 executable. Individual scripts are a mix of v1 and v2 — those still being maintained individually are v2; v1 ones are candidates for migration into the master.

### Script categories

| Category | Example scripts |
|---|---|
| Keyboard/input remapping | `arrows-keystrokes`, `dashes`, `backwards-slash`, `right_tab`, `checkmark` |
| Text automation | `autodate` (hotstrings like `k+ddd`), `ConvertCase`, `createTXT`, `logger`, `ClipboardOCR` |
| Window management | `Cycler_Windows_v3`, `move_resize`, `resize`, `kill_all` |
| System control | `brightness` (WMI), `volume`, `mute`, `pauseplay` |
| App launchers | `find_wise_reminder`, `open_hourglass`, `url_chrome` |
| Time utilities | `calendar`, `Sleep_Timer`, `Show_Time` |
| Meta / management | `AHK_Manager`, `_Check_Starters`, `^RUN_starters` |
| Auxiliary (separate processes) | `ClipboardOCR`, `ColdTurkeyActivado`, `GreenshotSlowMouse`, `KillBrowsers/`, `SimpleReminders/`, `traymond-timer/` |
| Macro recording | `MacroRecorder` |

### Management scripts

- `AHK_Manager.ahk` — GUI dashboard; lists running AHK processes with Reload/Suspend/Pause/Kill buttons. Triggered via `Ctrl+Alt+R`. Its `Aux Scripts…`
  button reopens the auxiliary-script launcher (below).
- `_Check_Starters.ahk` — status-checker GUI for 20+ configured scripts/programs.
- `^RUN_starters.ahk` — auto-launches RBTray.exe and Wise Reminder at startup.
- `^CLOSE_starters.ahk` — mass-terminates managed scripts.

### Auxiliary script launcher

On startup the master opens a GUI (`ShowAuxScriptsGui()`) that offers the seven
scripts that live outside it — tick any subset, or all, and launch them. The
same window is reachable from the Manager's `Aux Scripts…` button.

| Script | v | Notes |
|---|---|---|
| `traymond-timer/traymond-timer.ahk` | v1 | `Win+Shift+Z` hide + countdown. Needs Traymond.exe running or it exits with a MsgBox, so the launcher checks first. |
| `traymond-timer/restore-at-fixed-time.ahk` | v1 | No hotkeys; daily 16:40 restore-all sweep. |
| `ClipboardOCR.ahk` | v2 | `Ctrl+Alt+O` |
| `ColdTurkeyActivado.ahk` | v2 | No hotkeys; asks for its config on launch. |
| `GreenshotSlowMouse.ahk` | v2 | No hotkeys; polls for Greenshot's capture overlay and slows the pointer while it is up. Does not need Greenshot running to start. |
| `KillBrowsers/KillBrowsers.ahk` | v2 | `Ctrl+Alt+K` |
| `SimpleReminders/SimpleReminders.ahk` | v2 | `Win+Alt+Z` |

- None of these can be merged into the master: the two traymond scripts are
  AHK v1 (v1 and v2 cannot share a process) and the v2 ones carry their own
  hotkeys and state. They run as separate processes, like `MacroRecorder.ahk`.
- Launching goes through the `.ahk` file association, i.e. the AutoHotkey UX
  launcher, which reads each script's `#Requires` and picks v1 or v2.
  `A_AhkPath` cannot be used — it is the v2 exe running the master.
- Already-running scripts are detected by their (hidden) window title,
  `<full path> - AutoHotkey v<version>`, and skipped.
- `aux-scripts.ini` stores the ticked set (`[Selection]`) and what startup
  should do (`[Startup] Mode` = `ask` | `auto` | `off`, set from the same
  window). Stopping a script is the Manager's `Kill` button.

### Macro recorder

`MacroRecorder.ahk` (v2) records input into up to 12 slots. It must stay a
**separate process** from the master: while recording it registers a `~*vk`
hotkey for every virtual key, which would collide with the master's bindings.
The master's Manager GUI launches it via `OpenMacroRecorder()`.

- Macros are stored as standalone runnable `.ahk` scripts in `macros\`;
  playback launches one in its own process.
- `macros\macros.ini` is the slot index and settings file.
- Defaults: `Win+Alt+F1..F12` play, `Win+Alt+Shift+F1..F12` record, `Alt+F1` GUI,
  `Ctrl+Alt+Esc` panic stop. `Ctrl+Alt+F7/F9/F10` were unavailable — the master
  already uses them.
- Full usage: `README_MacroRecorder.md`. Remaining work: `TODO_MacroRecorder.md`.

### Clipboard OCR

`ClipboardOCR.ahk` (v2, standalone) OCRs the image in the clipboard with `Ctrl+Alt+O`
and shows the text in an editable GUI (copy / save .txt / save .png / discard).
Both save buttons write timestamped files to the Windows Downloads folder.

It depends on `OCR.ahk`, a vendored copy of Descolada's wrapper around the
Windows.Media.Ocr UWP API — no external OCR engine or install needed.

### External utilities (bundled)

- `RBTray-4_3/` — Minimize-to-tray utility (C++ binary + source). Launched by `^RUN_starters.ahk`.
- `tigerlilys-Screen-Dimmer-master/` — Multi-monitor screen dimmer (AHK v2, standalone).

### Archived scripts

- `not in use/` — 11 obsolete/replaced scripts, kept for reference.
- `broken/` — 2 non-functional scripts pending fix or deletion.
- `semi-uso/` — 4 partially-used scripts.

## Key Patterns

**Hotkey binding conventions:**
- `Win+Key` — primary utilities (brightness, calendar, window cycling)
- `Ctrl+Alt+Key` — secondary actions (text/keyboard nav, media control)
- `Win+Numpad` — quick media/numeric actions
- `k+xxx` hotstrings — auto-expand to dates/timestamps (`k+ddd`, `k+hhh`, `k+xxx`)
- `Alt+MouseButton` — window move/resize

**GUI pattern:** Scripts that need user interaction create AHK Gui objects inline (no external framework). Examples: calendar picker, file creator, conversation counter, window cycler list.

**WMI usage:** `brightness.ahk` controls monitor brightness via `WmiMonitorBrightness` / `wmiMonitorBrightNessMethods` COM queries — not via Windows API.

**Inter-process messaging:** `AHK_Manager.ahk` uses `PostMessage` to send control signals (Reload, Suspend, Pause) to other AHK processes by hwnd.

**Clipboard manipulation:** `ConvertCase.ahk` saves/restores clipboard to avoid clobbering user content during text transformations.

## Hardcoded Paths to Be Aware Of

Several scripts contain machine-specific absolute paths:
- VS Code: `C:\Users\fzapata\AppData\Local\Programs\Microsoft VS Code\Code.exe`
- Wise Reminder: `C:\Program Files (x86)\Wise\Wise Reminder\WiseReminder.exe`
- RBTray: `C:\autohotkey\RBTray-4_3\64bit\RBTray.exe`

When modifying scripts that launch external programs, verify these paths are still valid for the target machine.

## Reference Documentation

Three files, all describing the same thing — every hotkey and hotstring in the
unified master, in a dark-themed table — useful for checking conflicts before
adding a binding:

| File | Role |
|---|---|
| `AHK_Unified_Master_Referencia_ie.html` | What `Win+Shift+?` actually opens. Plain CSS (no `var()`) because the ActiveX control uses the IE engine. Also has the search box / filter chips. |
| `AHK_Unified_Master_Referencia.html` | Same content, modern CSS. The source the PDF is printed from. |
| `AHK_Unified_Master_Referencia.pdf` | Printed from the modern HTML. |

- **The two HTMLs must be edited together.** They drifted once and each ended up
  missing a section the other had; a section- and key-level diff of the two is the
  cheapest way to catch it.
- The appendix at the end covers the auxiliary scripts, marked with an `aux` pill.
  Those hotkeys only exist while the script in question is running, which the
  appendix's intro note says explicitly.
- Regenerate the PDF after editing the modern HTML:

```powershell
& "C:\Program Files\Google\Chrome\Application\chrome.exe" --headless=new --disable-gpu --no-pdf-header-footer --virtual-time-budget=8000 "--print-to-pdf=C:\autohotkey\AHK_Unified_Master_Referencia.pdf" "file:///C:/autohotkey/AHK_Unified_Master_Referencia.html"
```

  The `@media print` block in both HTMLs is what keeps the dark theme (via
  `print-color-adjust: exact`), hides the search bar and stops rows splitting
  across pages.
