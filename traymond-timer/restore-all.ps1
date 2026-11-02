<#
    restore-all.ps1

    Restores every window Traymond has hidden - no AutoHotkey required.
    Use this if you want the timer handled entirely by Windows Task Scheduler
    and would rather not have another program resident in memory.

    Schedule it for 17:30 daily:
      schtasks /create /tn "Traymond restore all" /sc daily /st 17:30 ^
        /tr "powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%CD%\restore-all.ps1\""

    How it works: Traymond's tray menu has a "Restore all windows" command
    (id 0x98). Posting that WM_COMMAND to Traymond's window makes Traymond do
    the work itself, so the tray icons are cleaned up properly. Its window is
    message-only, so it has to be found with FindWindowEx(HWND_MESSAGE, ...) -
    a normal FindWindow / Get-Process MainWindowHandle will never see it.
#>

[CmdletBinding()]
param()

Add-Type -Namespace Traymond -Name Native -MemberDefinition @'
    [DllImport("user32.dll", CharSet = CharSet.Ansi, SetLastError = true)]
    public static extern IntPtr FindWindowExA(IntPtr parent, IntPtr after, string className, string windowName);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
'@

$HWND_MESSAGE = [IntPtr](-3)
$WM_COMMAND   = 0x0111
$SHOW_ALL_ID  = 0x98

$traymond = [Traymond.Native]::FindWindowExA($HWND_MESSAGE, [IntPtr]::Zero, 'Traymond', $null)

if ($traymond -eq [IntPtr]::Zero) {
    Write-Error 'Traymond does not appear to be running - nothing to restore.'
    exit 1
}

if (-not [Traymond.Native]::PostMessage($traymond, $WM_COMMAND, [IntPtr]$SHOW_ALL_ID, [IntPtr]::Zero)) {
    Write-Error "PostMessage to Traymond failed (Win32 error $([ComponentModel.Win32Exception]::new().NativeErrorCode))."
    exit 1
}

Write-Verbose ('Restore-all sent to Traymond (hwnd 0x{0:X}).' -f $traymond.ToInt64())
exit 0
