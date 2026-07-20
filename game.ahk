; script made by u/ArrasDesmos
; if you're ever using this please credit me
; thy script stealers are not welcome here
; enjoy this year long work of hell

#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

file := "The Board.txt"
shop := {}

shop["Cloth Armor"] := {price:100, DEF:3, DEFpercent:15}
shop["Chainmail Armor"] := {price:250, DEF:7, DEFpercent:25}
shop["Iron Armor"] := {price:400, DEF:10, DEFpercent:40}
shop["Diamond Armor"] := {price:700, DEF:15, DEFpercent:60}
shop["Armor of the Void"] := {price:1100, DEF:20, DEFpercent:80}

shop["Wood Sword"] := {price:90, DMG:1.5}
shop["Silver Sword"] := {price:180, DMG:3}
shop["Diamond Sword"] := {price:270, DMG:4.5}
shop["Sword of the Void"] := {price:450, DMG:6}
shop["TNT"] := {price:250, DMG:20}
shop["Snowball"] := {price:2, DMG:0.1}
shop["Bow"] := {price:300, DMG:1.5}
shop["Arrow"] := {price:30, DMG:0}
shop["Buns"] := {price:10, Heal:2}
shop["Glass Cannon"] := {price:1500, DMG:100}
shop["Mutton"] := {price:100, Heal:10}

shovelTiers := ["Wooden Shovel", "Plastic Shovel", "Rake", "Military Shovel", "Mechanical Shovel", "Golden Shovel", "Flaming Shovel", "Shovel of the Void", "Light Shovel"]
shovelPrices := [0, 100, 200, 300, 600, 900, 1800, 2500, 3250]
shovelDigValues := [1, 3, 4, 5, 7, 10, 15, 20, 25]

gems := ["Iron", "Gold", "Diamond", "Ruby", "Emerald"]
gemPrices := [10, 20, 30, 40, 50] ; example prices for gems by index

global players := []
LoadPlayers()

F1::Dig()
F2::Sell()
F3::Attack()
F4::Buy()
F5::UpgradeShovel()
F6::AddPlayer()
F7::EatFood()
F8::ShowHelp()
return

LoadPlayers() { ; LOAD THE DAMN PLAYERS RAHHHHHHHHH
global players, file
players := []
if !FileExist(file)
FileAppend,, %file%
FileRead, content, %file%
Loop, Parse, content, `n, `r
{
line := A_LoopField
if (line = "")
continue
if !RegExMatch(line, "^(.*?) \((\d+)\) - (\d+)\$ - \((.*?)\) - (.*?) - (\d+) - (.*) - (\d+)/(\d+) HP - (\d+)/(\d+)", m)
continue

p := {}
p.name := m1
p.id := m2 + 0
p.cash := m3 + 0
p.gems := ParseGems(m4)
p.shovel := m5
p.score := m6 + 0

p.items := []
if (m7 != "") {
itemsRaw := StrSplit(m7, ", ")
for _, itemStr in itemsRaw {
if RegExMatch(itemStr, "^(.*?) x(\d+)$", match) {
p.items.Push({name: match1, qty: match2 + 0})
} else {
p.items.Push({name: itemStr, qty: 1})
}
}
}
; skibidi signma 😂
p.currentHP := m8 + 0
p.maxHP := m9 + 0
p.currentLives := m10 + 0
p.maxLives := m11 + 0
players.Push(p)
}
}

ParseGems(str) {
arr := []
Loop, Parse, str, `,
{
val := Trim(A_LoopField)
arr.Push(val + 0)
}
while arr.Length() < 5
arr.Push(0)
return arr
}

SavePlayers() { ; SAVE THE PLAYERS SO THAT IT DOESN'T OVERWRITE RAHHHHHHHH
global players, file
text := ""
for index, p in players
text .= BuildPlayerLine(p) . "`n"
FileDelete, %file%
FileAppend, %text%, %file%
}

BuildPlayerLine(p) {
gemsStr := "(" . StrJoin(", ", p.gems) . ")"
itemsStr := ""
for _, item in p.items {
if (item.qty > 1)
itemsStr .= (itemsStr = "" ? "" : ", ") . item.name . " x" . item.qty
else
itemsStr .= (itemsStr = "" ? "" : ", ") . item.name
}
return p.name . " (" . p.id . ") - " . p.cash . "$ - " . gemsStr . " - " . p.shovel . " - " . p.score . " - " . itemsStr . " - " . p.currentHP . "/" . p.maxHP . " HP - " . p.currentLives . "/" . p.maxLives
}

StrJoin(sep, arr) {
str := ""
for i, v in arr
str .= (i > 1 ? sep : "") . v
return str
}

ArrayContains(arr, val) {
for _, v in arr
if (v = val)
return true
return false
}

FindPlayerIndex(name) {
global players
StringLower, lname, name
for i, p in players {
pname := p["name"]
StringLower, pnameLower, pname
if (pnameLower = lname)
return i
}
return 0
}

GetPlayer(name, ByRef idx) {
idx := FindPlayerIndex(name)
if (idx)
return players[idx]
return ""
}

GetShovelTierIndex(name) {
global shovelTiers
for i, v in shovelTiers
if (v = name)
return i
return 1
}

FindItemIndex(items, name) {
for i, item in items
if (item.name = name)
return i
return 0
}


Dig() {
global players, gems, shovelDigValues
InputBox, pname, Dig, Enter player name:
if ErrorLevel
return
idx := FindPlayerIndex(pname)
if (!idx) {
MsgBox, Player not found.
return
}
p := players[idx]
tier := GetShovelTierIndex(p.shovel)
totalGems := shovelDigValues[tier]


gemsFound := []
Loop, % gems.Length()
gemsFound.Push(0)

treasureChestCount := 0
treasureChestValue := 40

Loop, % totalGems {
Random, gemTypeIndex, 1, gems.Length() + 1
if (gemTypeIndex = gems.Length() + 1) {
treasureChestCount++
} else {
gemsFound[gemTypeIndex]++
}
}

; Add gems to player's inventory OBVIOUSLY (when digging)
for i, count in gemsFound {
if (count > 0)
p.gems[i] += count  ; p.gems is 1-based
}

; give the kiddo money when find the treasure chest arrr
if (treasureChestCount > 0) {
p.cash += treasureChestCount * treasureChestValue
}

Msg := p.name . " dug up:"
for i, count in gemsFound
if (count > 0)
Msg .= "`n" . count . " " . gems[i]

if (treasureChestCount > 0)
Msg .= "`n" . treasureChestCount . " Treasure Chest(s) for $" . (treasureChestCount * treasureChestValue)

MsgBox, % Msg
players[idx] := p
SavePlayers() ; save the players to prevent overwriting
}


Sell() {
global players, gemPrices
InputBox, pname, Sell, Enter player name:
if ErrorLevel
return
idx := FindPlayerIndex(pname)
if (!idx) {
MsgBox, Player not found. ; return an error when the player is nonexistant
return
}
p := players[idx]
gain := 0
for i, val in p.gems {
gain += val * gemPrices[i]
p.gems[i] := 0
}
p.cash += gain
p.score += gain
players[idx] := p
MsgBox, % p.name . " sold all gemstones for $" . gain ; tells the player that they sold all the gemstones for a certain amount of cash
SavePlayers()
}

Attack() {
global players, shop
InputBox, attacker, Attack, Who is attacking?
if ErrorLevel
return
idx1 := FindPlayerIndex(attacker)
if (!idx1) {
MsgBox, Attacker not found. ; tell the player that the attacker doesn't exist (like your dad)
return
}
p1 := players[idx1]

InputBox, target, Attack, Who is attacked?
if ErrorLevel
return
idx2 := FindPlayerIndex(target)
if (!idx2) {
MsgBox, Target not found. ; you already know what this does
return
}
p2 := players[idx2]

InputBox, weapon, Attack, Which weapon?
if ErrorLevel
return
if !shop.HasKey(weapon) || !shop[weapon].HasKey("DMG") {
MsgBox, Invalid weapon. ; why do i have to explain
return
}
    
; check if attacker has the weapon, except for snowballs (if you handle them differently)
if (weapon != "Snowball" && !ArrayContains(p1.items, weapon)) {
MsgBox, You do not have that weapon.
return
}
    
dmg := shop[weapon].DMG
defense := 0
for item, props in shop {
if (ArrayContains(p2.items, item) && props.HasKey("DEF"))
defense += props.DEF
}
net := Max(dmg - defense, 0)
p2.currentHP -= net
result := p1.name . " dealt " . net . " damage to " . p2.name . "!"

if (p2.currentHP <= 0) {
p2.currentLives -= 1
if (p2.currentLives > 0) {
p2.currentHP := p2.maxHP
result .= "`n" . p2.name . " lost a life! (" . p2.currentLives . " lives left)"
} else {
result .= "`n" . p2.name . " has no lives left!"
}
}
    
; glass cannon breaking mechanism
if (weapon = "Glass Cannon") {
RemoveOneItem(p1.items, "Glass Cannon")
}

players[idx1] := p1
players[idx2] := p2
MsgBox, % result
SavePlayers()
}

RemoveOneItem(ByRef itemsArray, itemToRemove) {
for i, item in itemsArray {
if (item = itemToRemove) {
itemsArray.RemoveAt(i)
return
}
}
}

Buy() { ; call the buying function on f4 obviously
global players, shop
InputBox, pname, Buy, Enter player name:
if ErrorLevel
return
idx := FindPlayerIndex(pname)
if (!idx) {
MsgBox, Player not found. ; what
return
}
p := players[idx]
InputBox, item, Buy, Enter item to buy:
if ErrorLevel
return
if !shop.HasKey(item) {
MsgBox, Invalid item. ; when you write something stupid. you can't deal damage with a "aiofnhiondf" ofcourse
return
}

; use hasitem to check if player already owns the item (except snowball(s))
if (item != "Snowball" && HasItem(p.items, item)) {
MsgBox, You already own %item%.
return
}

cost := shop[item].price
if (p.cash < cost) {
MsgBox, Not enough cash. ; when you're broke so you cant buy the thing without ummmmmm cash i guess
return
}

; armor replacing mechanism (ignore if buggy i was sleepy af at the time)
if (shop[item].HasKey("DEF")) {
newItems := []
for _, invItem in p.items {
if (!shop.HasKey(invItem.name) || !shop[invItem.name].HasKey("DEF")) {
newItems.Push(invItem)
}
}
p.items := newItems
}

p.cash -= cost

if (item = "Snowball") { 
Loop, 16 ; so you buy 16 snowballs instead of 1 at a time (note that the original amount was supposed to be 30)
p.items.Push({name: item, qty: 1})
} else {
p.items.Push({name: item, qty: 1})
}

players[idx] := p
MsgBox, % p.name . " bought " . item
SavePlayers()
}

HasItem(items, name) {
for _, item in items
if (item.name = name && item.qty > 0)
return true
return false
}

UpgradeShovel() {
global players, shovelTiers, shovelPrices
InputBox, pname, Upgrade, Enter player name:
if ErrorLevel
return
idx := FindPlayerIndex(pname)
if (!idx) {
MsgBox, Player not found. ; do i have to explain this? unless you're 5 you can understand this whether you can code or not
return
}
p := players[idx]

tier := GetShovelTierIndex(p.shovel) ; this checks whether your shovel is max tier or not
if (tier >= shovelTiers.Length()) {
MsgBox, Already max shovel.
return
}

nextTier := tier + 1
price := shovelPrices[nextTier]

if (p.cash < price) {
MsgBox, Lack of cash.
return
}

p.cash -= price
p.shovel := shovelTiers[nextTier]
MsgBox, % p.name . " upgraded shovel to " . p.shovel ; upgrades your shovel
players[idx] := p
SavePlayers()
}

AddPlayer() { ; calls the f6 add player function
global players
InputBox, pname, New Player, Enter new player name:
if ErrorLevel
return
if FindPlayerIndex(pname) {
MsgBox, Player already exists. ; no duplicate players
return
}
; adds player data
p := {}
p.name := pname
p.id := players.Length() + 1
p.cash := 0
p.gems := [0,0,0,0,0]
p.shovel := "Wooden Shovel"
p.score := 0
p.items := []
p.currentHP := 20
p.maxHP := 20
p.currentLives := 3
p.maxLives := 3
players.Push(p)
MsgBox, Player %pname% added.
SavePlayers()
}

EatFood() { ; calls the f7 eat food function :DDD
global players, shop
InputBox, pname, Eat, Enter player name:
if ErrorLevel
return
idx := FindPlayerIndex(pname)
if (!idx) {
MsgBox, Player not found.
return
}
p := players[idx]
; making this is hell
; find food items in inventory (items with heal property in shop of course)
foods := []
for _, item in p.items {
if (shop.HasKey(item.name) && shop[item.name].HasKey("Heal") && item.qty > 0)
foods.Push(item.name)
}
if (foods.Length() = 0) {
MsgBox, No food items found.
return
}
; i am sorry that food isn't stackable. but that adds balancing cause you can't just heal mid battle instantly (unless you can cause i forgot)

InputBox, food, Eat, Choose food to eat:`n %foodslist%
if ErrorLevel
return
if !ArrayContains(foods, food) {
MsgBox, Invalid food.
return
}

; remove the food item
i := FindItemIndex(p.items, food)
if (i) {
p.items[i].qty -= 1
if (p.items[i].qty <= 0)
p.items.RemoveAt(i)
}

heal := shop[food].Heal
p.currentHP += heal
if (p.currentHP > p.maxHP)
p.currentHP := p.maxHP

MsgBox, % p.name . " healed for " . heal . " HP."
players[idx] := p
SavePlayers() ; prevent overwriting
}

ShowHelp() { ; this one is simple to understand
MsgBox,
(
F1 - Dig gems
F2 - Sell gems
F3 - Attack
F4 - Buy items (Snowballs come in 16)
F5 - Upgrade shovel
F6 - Add player
F7 - Eat food
F8 - Show help
) ; i know i could've used newline (`n) but this works too i guess
}