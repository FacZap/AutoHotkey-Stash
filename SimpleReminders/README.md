# SimpleReminders

Plain-text reminders with a quiet pop-up. AutoHotkey v2, standalone — it does
not depend on the unified master and can run next to it.

```powershell
AutoHotkey.exe .\SimpleReminders\SimpleReminders.ahk
```

## Hotkey

| Key | Action |
|---|---|
| `Win+Alt+Z` | Open the manager GUI |

`Win+Alt+Z` was free in `^^AHK_Unified_Master.ahk` (which uses `Win+Z` and
`Win+Ctrl+Shift+Z`) and in `MacroRecorder.ahk` (whose `#!` prefix only covers
F1–F12).

## Manager GUI

A list of every reminder — when it is due, how far away that is, the text and
its status — plus buttons:

- **New / Edit** — opens the editor (double-clicking a row also edits it)
- **Delete** — asks for confirmation, then removes the row from the CSV
- **Mark done** — toggles pending ↔ done
- **Clear completed** — drops all done reminders from the CSV
- **Show completed** — completed reminders are hidden unless this is ticked

Escape or Close hides the window; the script keeps running in the tray.

## Editor

Reminder text is capped at 100 characters (the field enforces it and shows a
counter). The date comes from a calendar control and the time from a spinner,
with quick-set buttons for *in 15 m*, *in 1 h*, *in 3 h* and *tomorrow 9:00*.
Saving a time that has already passed asks for confirmation first — it will pop
up on the next check. Re-scheduling a completed reminder makes it pending again.

## Pop-up

When a reminder comes due, a small window appears on the **center-right of the
primary monitor**, 20 px from the right edge. No sound, no alarm, and it is
shown with `NoActivate` so it never steals focus from what you are typing in.
If several are due at once they stack downwards.

- **Snooze** — pushes the due time out by the amount in the dropdown
  (5/10/15/30 minutes, 1/2/4 hours, or tomorrow 09:00)
- **Dismiss** — marks the reminder done

Closing the pop-up with the X or Escape snoozes it, so it cannot fall into a
loop of reappearing every 15 seconds.

Due dates are polled every 15 seconds, and once at start-up — anything that
came due while the script was not running pops up as soon as it starts.

## Database

`reminders.csv`, next to the script. It is rewritten in full on every create,
edit, delete, snooze, dismiss and mark-done, so the file always matches the GUI.
It is created on the first save and is written UTF-8 with a BOM so Excel opens
accented text correctly.

```csv
id,text,due,status,created
1,"Call the bank, ask about the fee",2026-09-01 15:30:00,pending,2026-09-01 08:12:04
```

| Column | Notes |
|---|---|
| `id` | integer, unique |
| `text` | up to 100 chars; quoted when it contains a comma, quote or newline |
| `due` | `yyyy-MM-dd HH:mm:ss` — fixed width, so it sorts chronologically |
| `status` | `pending` or `done` |
| `created` | `yyyy-MM-dd HH:mm:ss` |

The file can be edited by hand in Excel or a text editor; use **Reload from
CSV** in the tray menu afterwards to pick the changes up.

## Tray menu

Reminders (same as `Win+Alt+Z`) · Reload from CSV · Open CSV · Reload script ·
Exit.
