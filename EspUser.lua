local LIB="https://raw.githubusercontent.com/78589wlg/baby-script/main/esp-lib.lua"
local SRC="https://raw.githubusercontent.com/78589wlg/baby-script/main/MSESP.luau"
local COL=Color3.fromRGB(60,255,120)
local EXTRA={}
local function split(p)
local t={}
for w in p:gmatch("[^,，%s]+")do
if w~=""then t[#t+1]=w end
end
return t
end
local function isL(pl)
local a=pl.Name:lower()
local b=pl.DisplayName:lower()
if a=="123456wlg"or a=="zhumilizhutou"then return true end
for _,src in ipairs({getgenv().BabyExtra,getgenv().BabyExtra2})do
if type(src)=="string"and src~=""then
for _,w in ipairs(split(src))do
local lw=w:lower()
if lw==a or lw==b then return true end
end
end
end
return false
end
local function tagOf(pl)
if pl.Name:lower()=="123456wlg"then return "脚本作者"end
return "婴儿脚本"
end
local lib=nil
local mode=""
local ok1,r1=pcall(function()
if not getgenv().esplibLoaded then
getgenv().esplibLoaded=true
return loadstring(game:HttpGet(LIB))()
else
return getgenv().esplib
end
end)
if ok1 and type(r1)=="table"and r1.add_box then
lib=r1
mode="tul"
end
if not lib then
local ok2,r2=pcall(function()
return loadstring(game:HttpGet(SRC))()
end)
if ok2 and type(r2)=="table"then
lib=r2
mode="mb"
end
end
if not lib then return end
getgenv().BabyMode=mode
local function addTul(ch)
if not ch or ch:GetAttribute("BabyEspDone")then return end
ch:SetAttribute("BabyEspDone",true)
pcall(function()
lib.box.enabled=true
lib.box.type="normal"
lib.box.padding=1.15
lib.box.fill=COL
lib.box.outline=COL
lib.name.enabled=true
lib.name.fill=COL
lib.name.size=14
lib.healthbar.enabled=false
lib.distance.enabled=false
lib.tracer.enabled=false
lib.add_box(ch)
lib.add_name(ch)
end)
end
local function addMB(ch,pl)
pcall(function()
local s={}
s.Name=tagOf(pl)
s.Model=ch
s.ESPType="Highlight"
s.Color=COL
s.FillColor=COL
s.OutlineColor=COL
s.FillTransparency=0.55
s.OutlineTransparency=0
s.MaxDistance=10000
s.TextSize=14
s.Box2D={Enabled=true,Color=COL,Thickness=1,Transparency=0}
lib:Add(s)
end)
end
local function scan()
local P=game:GetService("Players")
for _,pl in ipairs(P:GetPlayers())do
if pl~=P.LocalPlayer and isL(pl)then
local ch=pl.Character
if ch then
if mode=="tul"then
addTul(ch)
else
if not ch:GetAttribute("BabyEspDone")then
ch:SetAttribute("BabyEspDone",true)
addMB(ch,pl)
end
end
end
end
end
end
getgenv().BabyScan=scan
getgenv().BabyClear=function()
getgenv().BabyOn=false
local P=game:GetService("Players")
for _,pl in ipairs(P:GetPlayers())do
local ch=pl.Character
if ch then pcall(function()ch:SetAttribute("BabyEspDone",nil)end)end
end
end
getgenv().BabyRescan=function()pcall(scan)end
getgenv().BabyOn=true
if not getgenv().BabyLoop then
getgenv().BabyLoop=true
game:GetService("RunService").Heartbeat:Connect(function()
if getgenv().BabyOn then pcall(scan)end
end)
end
pcall(scan)
