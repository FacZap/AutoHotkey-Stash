# traymond-timer

Bring windows hidden by [Traymond](https://github.com/fcFn/traymond) back on a timer.

Short answer to "is it possible?": **yes**, and AutoHotkey is a good fit. A plain
`.bat` file can't do it alone (batch has no way to send a window message), but a
one-line batch wrapper around either script here works fine for Task Scheduler.

## How it works

Traymond hides windows with `ShowWindow(SW_HIDE)` and tracks them inside its own
process. So you can't just re-show a hidden window from outside — Traymond would
still think it's hidden and you'd be left with a dead tray icon.

Instead, these scripts ask Traymond to do the restoring, by posting the exact
messages its own window procedure already handles:

| Action | Message | Traymond handler |
|---|---|---|
| Hide foreground window | `WM_HOTKEY` `0x0312` | `minimizeToTray()` |
| Restore **one** window | `WM_ICON` `0x1C0A`, `lParam = MAKELPARAM(WM_LBUTTONDBLCLK, LOWORD(hwnd))` | `showWindow()` |
| Restore **all** windows | `WM_COMMAND` `0x0111`, `wParam = 0x98` | `showAllWindows()` |

Traymond does its own bookkeeping — the tray icon is removed and its
crash-recovery file rewritten — exactly as if you'd double-clicked the icon or
picked "Restore all windows" from its menu.

One wrinkle worth knowing: Traymond's window is **message-only** (created with
`HWND_MESSAGE` as parent), so `EnumWindows` can't see it. That means AHK's
`WinExist()` and PowerShell's `MainWindowHandle` both come up empty. You have to
use `FindWindowEx(HWND_MESSAGE, ...)`.

## Files

| File | What it's for |
|---|---|
| `traymond-timer.ahk` | The main script. Resident timer + one-shot CLI. |
| `restore-at-1640.ahk` | Auxiliary resident script. Restores everything at 16:40 daily — and nothing else. |
| `restore-all.bat` | Fire-and-forget "restore everything" for Task Scheduler. |
| `restore-all.ps1` | Same thing with **no AutoHotkey needed** at all. |

## Resident use

Run `traymond-timer.ahk`. Edit the CONFIG block at the top to pick a mode:

- **`PerWindow`** (default) — every window you hide comes back on its own
  countdown, chosen at the prompt when you hide it. Hide three things at
  different times and each returns on its own schedule.
- **`Interval`** — restore *all* hidden windows every `IntervalMinutes`.
- **`DailyTime`** — restore *all* hidden windows once a day at `DailyTime`.

`RestoreAfterMinutes` is what the prompt starts pre-filled with. The individual
countdown works in every mode, so you can run `DailyTime` for the general case
and still say "but bring *this* one back in 10 minutes".

Hotkeys (all configurable, set to `""` to disable):

| Key | Action |
|---|---|
| `Win+Shift+Z` | Hide window and **ask** how long — see below |
| `Win+Alt+Shift+Z` | Hide window with **no countdown** — plain Traymond |
| `Win+Shift+R` | Restore everything now |
| `Win+Shift+C` | Cancel pending countdowns, leave windows hidden |

`Win+Alt+Shift+Z` is the escape hatch: it hides the window and leaves it hidden,
exactly as Traymond does on its own, for things you want out of the way with no
timer attached. (`Interval` and `DailyTime` modes still sweep those up on their
schedule — only the individual countdown is skipped.)

There is also an optional third key, unbound by default: set `HotkeyDefaultHide`
to something like `"^#+z"` to hide and silently apply `RestoreAfterMinutes`
without being asked.

### Setting a time by hand

`Win+Shift+Z` hides the window and then opens a small prompt for the time,
pre-filled with `RestoreAfterMinutes` and selected, so you can just type over it
and press Enter — or press Enter straight away to accept the default. It accepts:

| Typed | Means |
|---|---|
| `25` or `25m` | 25 minutes |
| `2h` | 2 hours |
| `1h30` or `1h30m` | 90 minutes |
| `@17:45` | at 17:45 — tomorrow if that time already went by |
| `0` | bring it back immediately |
| `1,5` | 1.5 minutes (comma decimals work too) |

Anything it can't read gets a "try again" message rather than a silently wrong
countdown. **Cancel un-hides the window straight away**, so the prompt is never a
trap — nothing is stranded in the tray if you change your mind.

The window is hidden *before* the prompt appears, deliberately. Traymond can only
hide whatever is in the foreground, so if the prompt took the foreground first,
handing it back to the target window afterwards would be at the mercy of Windows'
foreground-lock rules — which really do refuse sometimes. Hiding first avoids
that entirely, and Cancel makes it free to change your mind.

The tray icon menu also has *Restore all now*, *Pending countdowns...* (shows
what's queued and how long is left), and *Cancel all countdowns*.

### About Win+Shift+Z

A countdown needs to know *which* window was hidden and *when*, so the script
deliberately shadows Traymond's own `Win+Shift+Z`: it sees the keypress first
(via a keyboard hook, which takes precedence over Traymond's `RegisterHotKey`),
notes the foreground window, then forwards the hide to Traymond. Hiding behaves
exactly as before — you just get asked for a time as well.

If you'd rather leave Traymond's hotkey alone, set `HotkeyPromptHide := "#+x"`
(or anything else). Windows hidden with Traymond's own `Win+Shift+Z` then won't
get an individual countdown — but `Interval` and `DailyTime` modes still catch
them, since those restore everything regardless of how it was hidden.

### Start with Windows

Press `Win+R`, run `shell:startup`, and drop a shortcut to `traymond-timer.ahk`
in the folder that opens. (Traymond itself needs to be started too — the script
will tell you if it isn't running.)

## Auxiliary script: daily restore at 16:40

`restore-at-1640.ahk` is a deliberately tiny companion. Its **only** function is
to ask Traymond to restore every hidden window at **16:40**, every day. The time
is hardcoded — it's the `RestoreAt` line at the top of the file.

It registers **no hotkeys at all**, so it cannot collide with
`traymond-timer.ahk`, with `^^AHK_Unified_Master.ahk`, or with Traymond's own
`Win+Shift+Z`. Run it either way:

- **Alongside `traymond-timer.ahk`** — keep the main script in `PerWindow` mode
  for individual countdowns, and let this one guarantee a daily sweep of
  anything you hid without a timer, or hid and forgot about.
- **On its own** — if one daily sweep is all you want, this is a much smaller
  thing to keep resident than the full script. (Smaller still: `restore-all.bat`
  or `restore-all.ps1` on a Task Scheduler trigger, below, which keeps nothing
  resident at all.)

Two behaviours worth knowing:

- It compares **timestamps** rather than matching `HH:mm` exactly, so a PC that
  was asleep or suspended through 16:40 still gets its sweep on the next check
  after waking — within 20 seconds — instead of silently missing the day. (The
  main script's `DailyTime` mode matches the clock string, so it can miss.)
- Starting the script *after* 16:40 does **not** trigger a sweep on the spot —
  that moment belonged to a day this instance wasn't around for. It arms for
  tomorrow and says so in a tray balloon.

Hovering its tray icon shows `Traymond restore-all daily at 16:40`, which is how
you tell it apart from the main script's icon. Drop a shortcut in
`shell:startup` (see above) to have it running every day.

## Scheduled use, no resident script

If you'd rather not have another program in memory, schedule a one-shot restore:

```bat
schtasks /create /tn "Traymond restore all" /tr "\"D:\CLAUDE\traymond-timer\restore-all.bat\"" /sc daily /st 17:30
```

Every 30 minutes instead:

```bat
schtasks /create /tn "Traymond restore all" /tr "\"D:\CLAUDE\traymond-timer\restore-all.bat\"" /sc minute /mo 30
```

Remove it:

```bat
schtasks /delete /tn "Traymond restore all" /f
```

`restore-all.ps1` does the same job without AutoHotkey, if you prefer:

```bat
powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "D:\CLAUDE\traymond-timer\restore-all.ps1"
```

## Command line

```
AutoHotkey.exe traymond-timer.ahk /restore-all      # restore everything
AutoHotkey.exe traymond-timer.ahk /hide [hwnd]      # hide foreground, or a specific window
AutoHotkey.exe traymond-timer.ahk /restore <hwnd>   # restore one specific window
```

These one-shot calls don't disturb a resident copy of the script.

Note that `/hide <hwnd>` has to bring the target window to the foreground first
(Traymond only hides the foreground window), and Windows' foreground-lock rules
can refuse that when the call comes from a background process. The script
detects this and reports failure rather than hiding the wrong window. Plain
`/hide` with no argument has no such problem.

## Requirements

- AutoHotkey **v1.1** (tested on 1.1.37.02) — the script is v1 syntax, it will
  not run under AHK v2. `restore-all.ps1` needs no AutoHotkey.
- Traymond running.
