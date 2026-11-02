# AutoHotkey-Stash

Colección de scripts de AutoHotkey que uso o he usado, o en los que estoy trabajando. Windows, casi todo en AHK v2.

## Uso rápido

1. Instalar [AutoHotkey v2](https://www.autohotkey.com/). Los scripts en v1 (`traymond-timer/`) necesitan además AHK v1.1; el launcher elige la versión según el `#Requires` de cada script.
2. Clonar en `C:\autohotkey` (varios scripts asumen esa ruta).
3. Ejecutar `^^AHK_Unified_Master.ahk`: un solo proceso que reemplaza a más de 20 scripts sueltos.
4. `Ctrl+Alt+R` abre el AHK Manager (recargar, suspender, pausar o cerrar scripts).

## 📖 Guía de hotkeys

> **Todos los hotkeys, hotstrings y lo que hace cada uno están en la guía:
> [`AHK_Unified_Master_Referencia.pdf`](AHK_Unified_Master_Referencia.pdf)
> (o la versión HTML, [`AHK_Unified_Master_Referencia.html`](AHK_Unified_Master_Referencia.html), para abrir en el navegador).
> Empezá por ahí para ver qué contiene el repo.**
>
> Con el master corriendo, `Win+Shift+?` abre la misma guía en una ventana flotante, con buscador.

## Qué hay

| | |
|---|---|
| `^^AHK_Unified_Master.ahk` | Script principal: remapeos, fechas (`k+ddd`…), ventanas y pestañas, brillo, volumen, conversor de mayúsculas, timers. |
| Scripts auxiliares | `ClipboardOCR`, `SimpleReminders/`, `KillBrowsers/`, `GreenshotSlowMouse`, `ColdTurkeyActivado`, `traymond-timer/`, `RhythmGame`. Corren en procesos aparte; el master ofrece lanzarlos al iniciar. |
| `MacroRecorder.ahk`, `SimpleMacroRecorder.ahk` | Grabación y reproducción de macros. |
| Otros sueltos | `Sleep_Timer`, `AutoClicker_CtrlAltJ`, `prevent-AFK`, `AltTab_Button` y algunos más chicos. |

## Datos personales

No están en el repo (están en `.gitignore`). Son opcionales: sin ellos todo lo demás funciona igual, solo esos atajos no hacen nada. Hay que crear dos archivos junto al master:

1. **`personal.ahk`**: tus emails, que se escriben solos al tipear una abreviatura.
   - `kfz` escribe el email laboral.
   - `kzf` escribe el email personal.
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

Incluye [RBTray](https://github.com/benbuck/rbtray) (GPL), Hotkey Detective, y `UIA.ahk` / `OCR.ahk` de [Descolada](https://github.com/Descolada), cada uno con su licencia.
