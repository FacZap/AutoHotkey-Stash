#Requires AutoHotkey v2.0
#Include Audio.ahk

spotifyProc   := "Spotify.exe"
otherApps     := ["chrome.exe", "msedge.exe", "firefox.exe"]
checkInterval := 200       ; ms

SetTimer(checkAudio, checkInterval)

checkAudio() {
    global spotifyProc, otherApps

    sessEnum := IMMDeviceEnumerator()
        .GetDefaultAudioEndpoint()
        .Activate(IAudioSessionManager2)
        .GetSessionEnumerator()

    spotifyPlaying     := false
    otherAppNowPlaying := false

    silenceFloor := 0.07   ; tweak: 0.05–0.12 works well in practice

    loop sessEnum.GetCount() {
        sess := sessEnum.GetSession(A_Index - 1)

        ctl2  := sess.QueryInterface(IAudioSessionControl2)
        state := ctl2.GetState()          ; 0 = inactive, 1 = active, 2 = expired

        ; Only care about active sessions
        if (state != 1)
            continue

        pid := ctl2.GetProcessId()
        if !pid || !ProcessExist(pid)
            continue

        procName := ProcessGetName(pid)

        meter := sess.QueryInterface(IAudioMeterInformation)
        peak  := meter.GetPeakValue()     ; 0.0 – 1.0

        ; Ignore tiny background noise
        if (peak < silenceFloor)
            continue

        ; Debug (optional): see what AHK thinks is “playing”
        ; ToolTip(procName " peak=" Round(peak, 3))

        if (procName = spotifyProc) {
            spotifyPlaying := true
        } else if (otherApps.Has(procName)) {
            otherAppNowPlaying := true
        }
    }

    ; Edge detector: only trigger when "other app" starts playing
    static wasOtherPlaying := false

    if spotifyPlaying && otherAppNowPlaying && !wasOtherPlaying {
        PauseSpotify()
    }

    wasOtherPlaying := otherAppNowPlaying
}

PauseSpotify() {
    Send "{Media_Play_Pause}"
}
