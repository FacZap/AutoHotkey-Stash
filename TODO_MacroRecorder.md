# Macro Recorder — Plan & TODO

Status: **implemented** in [`MacroRecorder.ahk`](MacroRecorder.ahk).
Usage docs: [README_MacroRecorder.md](README_MacroRecorder.md).

---

## 1. What the old script did

| Aspect | How it worked |
|---|---|
| Files | `Macro.Recorder.ahk` and `.v2.ahk` were **byte-identical** except 2 lines (default log file `~Record1/2.ahk`, default key `F1`/`F2`) |
| Multi-macro | Possible but undiscoverable: `A_Args[1]`=filename, `A_Args[2]`=hotkey, one process per macro |
| Storage | `Stop()` generated a **complete standalone .ahk script** into `%TEMP%\~RecordN.ahk`, overwritten every record |
| Playback | `Run(A_AhkPath, LogFile)` — separate process, `Loop(1){...}` then `ExitApp()` |
| Settings | Parsed out of the generated file's own header comments. No UI |
| Pauses | **Already recorded** as `Sleep(Delay // 2)` for gaps >200 ms — but commented out unless `RecordSleep=true`, and halved |
| Mouse | Every click logged 3 variants (screen/window/relative); 2 commented per `MouseMode` |
| UX | One modal key: tap=play, hold 0.4–2.5 s=record, hold >2.5 s="CANCEL" (actually called `EditKeyAction`) |
| Entry point | Manager GUI button ran `Macro.Recorder.exe` — **the compiled binary, not the source** |

---

## 2. Phase 0 — Consolidate & fix

- [x] Create `MacroRecorder.ahk`; move `Macro.Recorder.ahk`, `.v2.ahk`, `.exe`
      and `run-macro_recorder.ahk` to `not in use/`
- [x] Drop the spin-wait hold-detection loop entirely — play and record are now
      separate hotkeys, so no timing discrimination is needed
- [x] Fix the CANCEL/Edit mismatch: `Ctrl+Alt+Esc` genuinely discards the
      recording; "edit in VS Code" moved to the GUI's **Edit file** button
- [x] Remove `ErrorLevel :=` v1 leftovers
- [x] Make `Playing` real: capture the playback PID via `Run(..., , , &pid)`
- [x] Panic hotkey `ProcessClose`s a running macro
- [x] Recording no longer logs the stop chord's modifiers (`TrimPendingChord`)
- [x] `OnExit` handler so a mid-playback exit can't leave the master suspended

## 3. Phase 1 — Persistent macro library

- [x] Macros live in `C:\autohotkey\macros\` instead of `%TEMP%`
- [x] `macros\macros.ini` index: `[General]` settings + `[SlotN]` file/name/speed/repeat/lastrun/steps
- [x] One-time migration of `%TEMP%\~Record1.ahk` / `~Record2.ahk`
- [x] `UpgradeMacroFile()` converts legacy macros to the current format on
      import so speed/repeat work on them
- [x] Load / Save As / Rename / Duplicate / Clear-slot
- [x] Recording into an occupied slot confirms first

## 4. Phase 2 — Multiple macros / slots

- [x] One process manages 12 slots
- [x] Per-slot play + record hotkeys from the ini
- [x] Play hotkeys bound only for filled slots; record hotkeys always bound
- [x] Only one recording at a time
- [x] Slot hotkeys released during recording (except the active stop key) so
      slot keys can be captured as macro content
- [x] `ShowTip` shows the active slot ("REC 3")

## 5. Phase 3 — Pauses & timing

- [x] `RecordSleep` defaults to **true**
- [x] Dropped the `// 2` halving — real delays are recorded
- [x] `SPEED` variable in each macro; sleeps emit `Sleep(Round(<ms> / SPEED))`
- [x] Per-slot speed multiplier (GUI + ini), applied in place without re-recording
- [x] Manual pause insertion while recording (`Win+Alt+P`), capture suspended
      during the prompt
- [x] Post-hoc delay editing in the step editor
- [x] Configurable minimum gap (was hardcoded 200 ms)
- [x] `Loop(1)` → `Loop(REPEAT)` with a per-slot repeat count
- [x] Optional "suspend the master script during playback"
- [x] Keystroke merging no longer swallows deliberate pauses: the merge window
      is the min-gap when sleeps are recorded, 1 s when they aren't

## 6. Phase 4 — GUI

- [x] `Alt+F1` toggles the window; `ShowGuiOnStart` setting; tray menu
- [x] Slot list: # / Name / Play / Record / Steps / Time / Speed / Repeat / Last run
- [x] Transport + library buttons (see README for the full table)
- [x] Step editor: edit delay, insert pause, enable/disable, delete step
- [x] Settings window for every preference and hotkey
- [x] Status line reflects recording / playing state

## 7. Phase 5 — Integration & cleanup

- [x] `OpenMacroRecorder()` in `^^AHK_Unified_Master.ahk` now launches
      `MacroRecorder.ahk`, and focuses the window if it's already running
- [x] Registered in `_Check_Starters.ahk`
- [x] `README_MacroRecorder.md` written
- [x] `CLAUDE.md` updated
- [ ] Add the new hotkeys to `AHK_Unified_Master_Referencia.html`
- [ ] Decide whether `macros\` should be committed or gitignored
- [ ] Optional: auto-start via `^RUN_starters.ahk` (one line, see README)

---

## 7b. Fixed after the first real use

- [x] **Stop chord leaked into recordings.** `StopRecording` set
      `Recording := false`, ran `SetCapture(false)` (254 `Hotkey()` calls), and
      only then called `TrimPendingChord()`. Releasing Win/Alt/Shift during
      `SetCapture` woke the parked `KeyWait` threads, which cleared
      `PendingMods` — so the trim found nothing and `{LWin Down}{Alt Down}` was
      saved as macro content. Now `Critical()` + trim first, before anything
      that can yield.
- [x] **Playback corrupted by held modifiers.** Keystrokes are sent with
      `{Blind}`, which preserves physically-held modifiers, and the play hotkey
      is a chord — so macros started typing as `Win+Alt+key`. Generated macros
      now wait (bounded, 3 s) for the launch modifiers to be released.
- [x] **Stuck modifiers after playback.** A macro containing an unmatched
      `{X Down}` wedged the keyboard. Macros now release any modifier they left
      held.
- [x] **"SAVED n" reported meaningless numbers.** Partly the leaked chord,
      partly that `CountSteps` counted commented-out window markers. Now counts
      only steps that will run; the step-editor title shows active/disabled.
- [x] **Preamble `Sleep(20)` appeared as an editable step.** `ParseMacro` now
      only scans between `Loop(...)` and its closing brace.
- [x] **Duplicating twice aliased two slots to one file.** `UniqueMacroFile()`
      for new files, `DeAliasSlots()` to split existing ones.
- [x] **Stale step counts** in `macros.ini` refreshed on startup.

---

## 8. Notes discovered along the way

- **Default prefixes are `Win+Alt` / `Win+Alt+Shift`, not `Ctrl+Alt`.** The
  master already binds `Ctrl+Alt+F7`, `Ctrl+Alt+F9` and `Ctrl+Alt+F10`
  (`!^F7`, `!^F9`, `!^F10`), so a `Ctrl+Alt+F1..F12` slot range would collide.
- **`Gui.Show()` sizes are physical pixels, but control coordinates are
  DPI-scaled.** On this machine (`A_ScreenDPI` = 120, i.e. 125%) a `w700`
  ListView is really 875 px, so `Show("w720 …")` clips it. `AutoSize` has the
  same blind spot and under-sizes the window. `MacroRecorder.ahk` works around
  it with a `GuiSize()` helper. **`^^AHK_Unified_Master.ahk` uses a bare
  `MyGui.Show("w375 h365")` and is likely clipped the same way** — worth
  checking.
- `_Check_Starters.ahk` is an AHK **v1** script, so it can't be validated with
  the v2 binary.
- `AutoHotkey.exe /validate` **hangs on a warning** (e.g. unreachable code) —
  it puts up a dialog even with `/ErrorStdOut`. Cap the wait when scripting it.
- `Log` is a built-in function in v2 (natural logarithm). `MacroRecorder.ahk`
  shadows it with its own `Log()`, which is fine, but a bare `log := ...` in
  any other script is a load-time error.
