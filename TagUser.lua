local COL=Color3.fromRGB(60,255,120)
local SG=nil
local MADE={}
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
local function getGui()
if SG and SG.Parent then return SG end
local pg=game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
if not pg then return nil end
SG=Instance.new("ScreenGui")
SG.Name="BabyTagGui"
SG.ResetOnSpawn=false
SG.IgnoreGuiInset=true
SG.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
SG.DisplayOrder=999999
SG.Parent=pg
getgenv().BabyTagGui=SG
return SG
end
local function build(ch)
local hd=ch:FindFirstChild("Head")
if not hd then return nil end
local g=getGui()
if not g then return nil end
local bb=Instance.new("BillboardGui")
bb.Name="BabyNameTag"
bb.Size=UDim2.new(0,200,0,32)
bb.StudsOffset=Vector3.new(0,2.6,0)
bb.AlwaysOnTop=true
bb.LightInfluence=0
bb.ResetOnSpawn=false
bb.MaxDistance=500
bb.Parent=hd
local lb=Instance.new("TextLabel")
lb.Size=UDim2.new(1,0,1,0)
lb.BackgroundTransparency=1
lb.Text=""
lb.TextColor3=COL
lb.TextStrokeTransparency=0.35
lb.TextStrokeColor3=Color3.new(0,0,0)
lb.TextSize=15
lb.Font=Enum.Font.GothamBold
lb.TextXAlignment=Enum.TextXAlignment.Center
lb.RichText=false
lb.Parent=bb
MADE[ch]={bb=bb,lb=lb}
return MADE[ch]
end
local function kill(ch)
local r=MADE[ch]
if r then
pcall(function()r.bb:Destroy()end)
MADE[ch]=nil
end
local hd=ch and ch:FindFirstChild("Head")
if hd then
local b=hd:FindFirstChild("BabyNameTag")
if b then pcall(function()b:Destroy()end)end
end
end
local function scan()
local P=game:GetService("Players")
local keep={}
for _,pl in ipairs(P:GetPlayers())do
if pl~=P.LocalPlayer and isL(pl)then
local ch=pl.Character
if ch then
keep[ch]=true
local r=MADE[ch]
local hd=ch:FindFirstChild("Head")
if not r or not r.bb or r.bb.Parent~=hd then
if r then kill(ch)end
local nr=build(ch)
if nr then nr.lb.Text=tagOf(pl)end
else
local tx=tagOf(pl)
if r.lb.Text~=tx then r.lb.Text=tx end
end
end
end
end
for ch in pairs(MADE)do
if not keep[ch]then kill(ch)end
end
return keep
end
local function clearAll()
getgenv().BabyOn=false
for ch in pairs(MADE)do kill(ch)end
MADE={}
if SG then pcall(function()SG.Enabled=false end)end
end
getgenv().BabyScan=scan
getgenv().BabyClear=clearAll
getgenv().BabyRescan=function()pcall(scan)end
getgenv().BabyTagOn=true
if not getgenv().BabyTagLoop then
getgenv().BabyTagLoop=true
game:GetService("RunService").RenderStepped:Connect(function()
if getgenv().BabyTagOn then pcall(scan)end
end)
end
pcall(scan)
