# AutoHotkey-Stash

Colección de scripts de AutoHotkey que uso o he usado, o en los que estoy trabajando. Windows, casi todo en AHK v2.

## Uso rápido

1. Instalar [AutoHotkey v2](https://www.autohotkey.com/). Los scripts en v1 (`traymond-timer/`) necesitan además AHK v1.1; el launcher elige la versión según el `#Requires` de cada script.
2. Clonar en `C:\autohotkey` (varios scripts asumen esa ruta).
3. Ejecutar `^^AHK_Unified_Master.ahk`: un solo proceso que reemplaza a más de 20 scripts sueltos.
4. `Ctrl+Alt+R` abre el AHK Manager (recargar, suspender, pausar o cerrar scripts).

## Guía de hotkeys
**Todos los hotkeys, hotstrings y lo que hace cada uno están en la guía:
[`AHK_Unified_Master_Referencia.pdf`](AHK_Unified_Master_Referencia.pdf)
(o la versión HTML, [`AHK_Unified_Master_Referencia.html`](AHK_Unified_Master_Referencia.html), para abrir en el navegador).
Recomiendo empezar por ahí para ver qué contiene el repo.**
Con el master (^^AHK_Unified_Master.ahk) corriendo, `Win+Shift+?` abre la misma guía en una ventana flotante, con buscador.

## Qué hay

| | |
|---|---|
| `^^AHK_Unified_Master.ahk` | Script principal: remapeos, comandos, ventanas y pestañas, brillo, volumen, conversor de mayúsculas, timers, etc |
| Scripts auxiliares | `ClipboardOCR`, `SimpleReminders/`, `KillBrowsers/`, `GreenshotSlowMouse`, `ColdTurkeyActivado`, `traymond-timer/`, `RhythmGame`. Corren en procesos aparte; el master ofrece lanzarlos al iniciar. |
| `MacroRecorder.ahk`, `SimpleMacroRecorder.ahk` | Grabación y reproducción de macros. |
| Otros sueltos | `Sleep_Timer`, `AutoClicker_CtrlAltJ`, `prevent-AFK`, `AltTab_Button` y algunos más chicos. |

## Datos personales

No están en el repo (están en `.gitignore`). Son opcionales: sin ellos todo lo demás funciona igual, solo esos atajos no hacen nada. Hay que crear dos archivos junto al master:

1. **`personal.ahk`**: emails que se escriben al tipear una abreviatura. Se pueden modificar y editar libremente. Por ejemplo, yo utilizaba:
   - `kfz` para escribir el email laboral.
   - `kzf` para escribir el email personal.
   ```autohotkey
   ::kfz::tu.nombre@empresa.com
   ::kzf::tu.nombre@gmail.com
   ```
2. **`url_chrome.ini`**: la planilla de Google Sheets que abre `Ctrl+Alt+G` (ventana nueva) y `Ctrl+Alt+Shift+G` (pestaña nueva).
   ```ini
   [Settings]
   Url=https://docs.google.com/spreadsheets/d/...
   ```

Los demás archivos locales (`aux-scripts.ini`, `macros/`, `RhythmGame.ini`) los crean los scripts solos al usarlos.

<!-- TODO: Features más útiles -->

## Terceros

He encontrado algunas herramientas de terceros en el camino que me ayudan a trabajar más eficientemente y/o debuggear funciones de mis scripts.
Este repo incluye [Traymond](https://github.com/fcFn/traymond), [RBTray](https://github.com/benbuck/rbtray) (GPL), Hotkey Detective, y `UIA.ahk` / `OCR.ahk` de [Descolada](https://github.com/Descolada), cada uno con su licencia.
Antiguamente también utilizaba [Hourglass Timer](https://chris.dziemborowicz.com/apps/hourglass/) y [WiseReminder](https://wise-reminder.en.softonic.com/). Ya no los utilizo demasiado pero por cuestiones 'legacy' los mantengo.
