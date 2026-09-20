# Merge notes: `workMacroRecorder` → `personal_v2_merged`

Base: rama `personal` (a308b75). Fuente: rama `workMacroRecorder` (9cbd117),
idéntica a la carpeta `AutoHotkey-Stash-workMacroRecorder` usada para el merge.
Regla general: se trae todo lo de work; donde un mismo atajo chocaba, gana work;
se respetan las excepciones de abajo.

## Excepciones personales

| Tema | Qué se hizo |
|---|---|
| Navegador | Firefox en vez de Chrome: `Ctrl+Alt+G` / `Ctrl+Alt+Shift+G`, `kill_all` también saltea Firefox, `find_google_calendar.ini` = Firefox, `kill_preferences.ini` con Firefox primero, `Ctrl+Shift+A` (`@tabs`) en Firefox, `_Check_Starters` mira `url_firefox.ahk`. |
| Brillo | `RAlt & PgDn` +10 / `RAlt & PgUp` −10 (mismo sentido que el `Brightness.ahk` personal), vía WMI. Se mantienen `Win+,` / `Win+.`. |
| Macro Recorder | Se mantiene el simple (`Macro.Recorder.exe` / `.ahk`, tecla F1). `Win+F3` y el botón del Manager lo lanzan. **No** se trajeron `MacroRecorder.ahk`, `README_MacroRecorder.md`, `TODO_MacroRecorder*.md`, `macros/`. |
| Periféricos | Intactos: battery limiter, auto_coolboost*, coolbooster, tabby*, vlc, AutoClicker, ScrollBoost, emoji, etc. Tampoco se trajeron las copias viejas de work en `not in use/` (`Macro.Recorder*`, `run-macro_recorder.ahk`, `auto_coolboost*.ahk`). |
| Datos personales | `kfz`/`kzf` salen del master; el master incluye `ahk_STARTUP/!_personal.ahk`. |
| Show_Time | `Win+C` con 7 flechas (layout de la barra de la laptop); `Show_Time.ahk` suelto queda en su versión personal. |
| Arranque | No se lanza RBTray ni Wise Reminder. |
| Rutas | Manager `Open Folder` y macro → `A_ScriptDir` (no `C:\autohotkey`). |

## Portado del viejo `ahk_STARTUP/!_STARTUP.ahk` (v1 → v2)

AltGr+Numpad 2/8/3/4/6 (vol−/vol+/mute/prev/next) · `Ctrl+Alt+.`/`,` (`>`/`<`)
· `AltGr+{` maximizar · `AltGr+-` minimizar · `Alt+F9` Matlab · `Ctrl+Alt+D`
fix PDF · `Ctrl+Shift+CapsLock` · `Win+|` Wise Reminder · `Win+Shift+|`
Hourglass · `Win+F3` macro · hotstrings `k6ini k6fin kuser kapp kdd1 kd1d skkk
kss1 ks1s kmmd kjj1 kzzz khdx`.

## Descartado del viejo `!_STARTUP.ahk` (choca o ya está en el master)

| Personal | Queda |
|---|---|
| `RCtrl+Numpad.` → `,` | work: `Ctrl+Numpad.` → `;` |
| `Ctrl+Numpad-` guion corto / `Alt+Numpad-` guion largo | work: al revés (`Ctrl` = —, `Alt` = –) |
| `knnn` con mayúscula inicial | work: `knnn` en minúscula |
| `kxxx` = `yyMMddHHmmss` | work: `yyMMdd_HHmm` |
| `Ctrl+F2` espacios→`_`, `Ctrl+Shift+F2`, `Ctrl(+Shift)+F3/F4` | work: `Ctrl+F2` = ConvertCase (25 estilos) |
| `LWin+Rueda` | work: `Win+Rueda` (igual) |
| Calendario, contador, timer Win+Alt+S, resize, macros Instagram, Win+Z… | versiones de work (superset) |

## Archivos con el mismo nombre en ambas ramas

- Se quedó la versión personal: `Show_Time.ahk`, `find_google_calendar.ini`,
  `KillBrowsers/kill_preferences.ini`.
- Se tomó la de work (diferencias de espacios/comentarios o work más completo):
  `AltTab_Button.ahk`, `dashes.ahk`, `selectcellcontent.ahk`, `kill_all.ahk`,
  `logger.ahk`, `^RUN_starters.ahk`, `^CLOSE_starters.ahk`.
- Fusionados a mano: `.gitignore`, `CLAUDE.md`.

## Ojo al correr periféricos junto al master

- `coolbooster.ahk` usa `Ctrl+Alt+W` (el master lo usa para Flecha Arriba).
- `FF_ctrlA.ahk` usa `Ctrl+Alt+A` (el master: Play/Pausa).
- `ahk_STARTUP/AltWindowsControl.ahk`, `ahk_STARTUP/Cycler-Window-v3.ahk`,
  `ahk_STARTUP/!_STARTUP.ahk`: duplican funciones del master.

## Deploy (manual)

1. Cerrar el `!_STARTUP.ahk` v1 que corre hoy.
2. Traer esta rama a `C:\Users\fzpat\Desktop\ahk` (o apuntar a esta carpeta).
3. Lanzar `^^AHK_Unified_Master.ahk` y, si se quiere al inicio, poner un acceso
   directo a él en `shell:startup`.
