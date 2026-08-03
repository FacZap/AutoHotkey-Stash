# Macro Recorder

Records keyboard and mouse input, stores it as a reusable macro, and replays it
on a hotkey. Up to 12 macros are held at once, each on its own slot.

**Script:** [`MacroRecorder.ahk`](MacroRecorder.ahk) (AutoHotkey v2)
**Macros:** `C:\autohotkey\macros\`
**Settings:** `C:\autohotkey\macros\macros.ini`

---

## Starting it

```bash
"C:\Users\fzapata\AppData\Local\Programs\AutoHotkey\v2\AutoHotkey64.exe" "C:\autohotkey\MacroRecorder.ahk"
```

Or press `Ctrl+Alt+R` for the AHK Manager and click **Macro Recorder** — if it's
already running, that button just brings its window up.

It runs as its own process, separate from `^^AHK_Unified_Master.ahk`. That is
deliberate: while recording it grabs a hotkey for *every* key on the keyboard,
which would collide with the master's own bindings if they shared a process.

To start it automatically at login, add this line to `^RUN_starters.ahk`:

```
Run "C:\autohotkey\MacroRecorder.ahk"
```

---

## Hotkeys

| Hotkey | Action |
|---|---|
| `Win+Alt+F1` … `Win+Alt+F12` | Play the macro in slot 1–12 |
| `Win+Alt+Shift+F1` … `F12` | Start recording into slot 1–12 — **press again to stop and save** |
| `Win+Alt+P` | Insert a pause (only while recording) |
| `Alt+F1` | Show / hide the macro window |
| `Ctrl+Alt+Esc` | Stop everything — kills a running macro, **cancels** a recording without saving |

Play hotkeys only exist for slots that actually hold a macro, so `Win+Alt+F7`
stays free for other apps until slot 7 is filled. Record hotkeys are always
active.

All of these are configurable — see [Settings](#settings).

> **Note:** the master script uses `Ctrl+Alt+F7/F9/F10`, which is why the
> defaults here are `Win+Alt` rather than `Ctrl+Alt`. If you change the prefixes,
> check `AHK_Unified_Master_Referencia.html` for conflicts first.

---

## Recording a macro

1. Press `Win+Alt+Shift+F3` (for slot 3). A flashing **REC 3** appears top-centre.
2. Do the thing — type, click, drag, switch windows.
3. Press `Win+Alt+Shift+F3` again. It flashes **SAVED 14** (14 steps) and writes
   the file.
4. Press `Win+Alt+F3` to replay it.

If the slot already holds a macro you'll be asked before it's overwritten.

**To abandon a recording**, press `Ctrl+Alt+Esc` instead — nothing is saved.

### Pauses

Real delays between your actions are recorded by default. Any gap longer than
200 ms becomes a `Sleep` in the macro, so the playback has the same rhythm as
the original. Bursts of fast typing are still merged into a single keystroke
send, so the macro stays readable.

To add a longer wait on purpose — waiting for a dialog, a page load, a slow save
— press `Win+Alt+P` while recording and type the number of milliseconds.
Recording is paused while the prompt is up, so the typing isn't captured.

Turn recorded pauses off in Settings if you'd rather have macros run flat out.

---

## The macro window (`Alt+F1`)

Lists all 12 slots with their name, hotkeys, step count, total wait time, speed,
repeat count and last run. Double-click a row to play it.

| Button | What it does |
|---|---|
| **Record** | Start recording into the selected slot |
| **Play** | Run the selected macro |
| **Stop/Cancel** | Kill a running macro, or abandon a recording |
| **Steps…** | Open the step editor (see below) |
| **Speed…** | Playback rate — `2.0` runs twice as fast, `0.5` half speed |
| **Repeat…** | How many times the macro runs per trigger |
| **Rename…** | Rename the macro (renames the file too) |
| **Save As…** | Export a copy anywhere on disk |
| **Load…** | Import an `.ahk` macro into the selected slot |
| **Duplicate** | Copy the macro into the first free slot |
| **Clear slot** | Free the slot, optionally deleting the file |
| **Edit file** | Open the macro's source in VS Code (or Notepad) |
| **Settings…** | Preferences — see below |
| **Folder** | Open `C:\autohotkey\macros\` in Explorer |

### Step editor

Lists every recorded action — key sends, mouse clicks, window activations and
waits — and lets you fix a recording without redoing it:

- **Edit delay…** — change how long a wait lasts
- **Insert pause…** — add a new wait before the selected step
- **Enable/Disable** — comment a step out without deleting it
- **Delete step** — remove it (multi-line window steps are removed as a unit)

Changes are written to the macro file immediately.

---

## Settings

`Alt+F1` → **Settings…**, or edit `macros\macros.ini` directly. Changing
settings in the GUI reloads the script so new hotkeys take effect.

| Setting | Default | Meaning |
|---|---|---|
| Mouse coordinate mode | `screen` | `screen` = absolute desktop coordinates. `window` = relative to the active window, and the macro will activate the right window first — use this when the target window moves. `relative` = offsets from the previous cursor position. |
| Minimum gap to record | `200` ms | Delays shorter than this aren't recorded as waits |
| Default manual pause | `1000` ms | Prefilled value for `Win+Alt+P` |
| Number of slots | `12` | How many slots to bind (1–12) |
| Record pauses between actions | on | Turn off to make macros run with no waiting |
| Suspend the master script during playback | off | Stops replayed keys from re-triggering the master's own remaps. Turn this on if a macro that contains e.g. `Ctrl+Alt+W` behaves oddly on playback. |
| Show this window on launch | off | Open the macro window at startup |

Hotkeys use AHK notation: `#` Win, `!` Alt, `^` Ctrl, `+` Shift. The play and
record fields are *prefixes* — the slot key (`F1`…`F12`) is appended to them.

---

## How macros are stored

Each macro is a **complete, standalone AutoHotkey v2 script** in
`C:\autohotkey\macros\`. Playing one launches it in its own process; it runs and
exits. That means you can read, hand-edit, version, or share a macro like any
other script — and run it directly without the recorder.

```ahk
SPEED := 1.00          ; playback rate
REPEAT := 1            ; how many times to run

; wait for the launch hotkey's modifiers to be released
__deadline := A_TickCount + 3000
while (A_TickCount < __deadline && (GetKeyState("LWin", "P") || ...))
    Sleep(20)

Loop(REPEAT)
{
Send "{Blind}{Ctrl Down}s{Ctrl Up}"

Sleep(Round(570 / SPEED))

MouseClick("L", 1204, 388) ;screen
}
; release any modifier this macro left held down
for __k in ["LWin", "RWin", "Ctrl", "Alt", "Shift"]
    if GetKeyState(__k)
        Send("{" __k " Up}")
ExitApp()

^!Esc::ExitApp()       ; abort while it runs
```

The two guards around the body are boilerplate, not macro content — the step
editor skips them. The opening one matters: keystrokes are sent with `{Blind}`,
which preserves whatever modifiers you're physically holding, and the play
hotkey is a chord. Without the wait, a macro launched with `Win+Alt+F2` starts
typing while Win and Alt are still down and every keystroke comes out as
`Win+Alt+key`. It adds no delay once your fingers are off the keys, and gives up
after 3 seconds so a stuck key can't hang playback.

Every mouse click is recorded three times — screen, window and relative
coordinates — with two of them commented out. To switch a macro to a different
coordinate mode after the fact, move the `;` between those lines.

`macros.ini` holds which file is in which slot, plus each macro's name, speed
and repeat count. Deleting it resets the slots; the macro files survive.

---

## Notes and limits

- **Step counts are the steps that will actually run.** Disabled (commented-out)
  lines aren't counted, which is why a recording of "type, pause, type" reports
  4 rather than 5 — the window-activation marker that screen mode leaves behind
  is inert. The step editor shows the inert ones too, with an `Enabled` column.
- **The library self-repairs on startup.** Macros written by an older version
  get the modifier guards added, and two slots that ended up sharing one file
  are split into separate copies. Both are one-time and idempotent.
- **Old recordings were imported automatically.** On first run, any
  `%TEMP%\~Record1.ahk` / `~Record2.ahk` from the previous recorder was copied
  into slots 1 and 2 and upgraded to the current format. Their `Sleep` lines
  arrive **disabled**, because the old recorder defaulted to not recording
  pauses — enable them in the step editor if you want the original timing.
- **Loading an old macro** through **Load…** upgrades it the same way.
- Macros are replayed with `SendMode("Event")` and `SetKeyDelay(30)`. Some
  applications (games, remote desktop clients, elevated windows) ignore
  synthetic input regardless.
- A macro recorded against screen coordinates breaks if the target window moves.
  Use `window` mouse mode for anything that isn't always in the same place.
- Recording captures the modifier keys of the stop hotkey too; they're stripped
  automatically, so recordings don't end with a stuck `{Shift Down}`.
- The recorder must be running for the hotkeys to work. Check with
  `_Check_Starters.ahk`, which now lists it.

## Replaced files

`Macro.Recorder.ahk`, `Macro.Recorder.v2.ahk`, `Macro.Recorder.exe` and
`run-macro_recorder.ahk` moved to `not in use/`. The first two were identical
apart from their default slot; the launcher was AHK v1 and could not run.
