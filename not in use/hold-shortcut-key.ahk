#Persistent
#NoEnv
SendMode Input
SetTimer, ReleaseKeys, 100

; Dictionary to store the state of each modifier key
keys := {}
; Initialize all modifier keys with false state
keys["^"] := false
keys["+"] := false
keys["!"] := false
keys["#"] := false

ReleaseKeys:
    for key, value in keys
    {
        if (value && (A_TickCount - value >= 3000))
        {
            Send, {%key% up}
            keys[key] := false
        }
    }
return

; General key handler for modifier keys
~*^::
~*+::
~*!::
~*#::
    key := SubStr(A_ThisHotkey, 2)
    if (!keys[key])
    {
        keys[key] := A_TickCount
        Send, {%key% down}
    }
return

; Key handler for letters and numbers to send the key press if modifier is held
~*a::SendKey("a")
~*b::SendKey("b")
~*c::SendKey("c")
~*d::SendKey("d")
~*e::SendKey("e")
~*f::SendKey("f")
~*g::SendKey("g")
~*h::SendKey("h")
~*i::SendKey("i")
~*j::SendKey("j")
~*k::SendKey("k")
~*l::SendKey("l")
~*m::SendKey("m")
~*n::SendKey("n")
~*o::SendKey("o")
~*p::SendKey("p")
~*q::SendKey("q")
~*r::SendKey("r")
~*s::SendKey("s")
~*t::SendKey("t")
~*u::SendKey("u")
~*v::SendKey("v")
~*w::SendKey("w")
~*x::SendKey("x")
~*y::SendKey("y")
~*z::SendKey("z")
~*0::SendKey("0")
~*1::SendKey("1")
~*2::SendKey("2")
~*3::SendKey("3")
~*4::SendKey("4")
~*5::SendKey("5")
~*6::SendKey("6")
~*7::SendKey("7")
~*8::SendKey("8")
~*9::SendKey("9")

SendKey(key)
{
    global keys
    for mod, time in keys
    {
        if (time)
        {
            Send, {%mod%%key%}
            return
        }
    }
    Send, {%key%}
}

; Reset the state of modifier keys when they are released manually
^up::keys["^"] := false
+up::keys["+"] := false
!up::keys["!"] := false
#up::keys["#"] := false
