local WindUI=loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua"))()
local P=game:GetService("Players")
local LP=P.LocalPlayer
local RS=game:GetService("ReplicatedStorage")
local WS=game:GetService("Workspace")
local UIS=game:GetService("UserInputService")
local HS=game:GetService("HttpService")
local Win=WindUI:CreateWindow({Title="在末日中生存下来"})
local cfg={AutoSprint=true,NoSlow=true,Fly=false,FlySpeed=25,Noclip=false,AutoPickup=false,PickupRange=15,AutoEat=false,EatHP=40,SpeedHack=false,SpeedVal=27,KillAura=false,AuraRange=16,AttackZ=true,AttackB=true,MobESP=false,ItemESP=false,Fullbright=false}
local function ch()return LP.Character end
local function root()
local c=ch()
return c and(c:FindFirstChild("HumanoidRootPart")or c.PrimaryPart)
end
local function hum()
local c=ch()
return c and c:FindFirstChildOfClass("Humanoid")
end
local function alive()
local c=ch()
local h=hum()
return c and h and h.Health>0
end
local function rem(path)
local cur=RS
for _,n in ipairs(path)do
cur=cur and cur:FindFirstChild(n)
end
return cur
end
local R={
Pick=rem({"Remotes","Interaction","PickUpItem"}),
Fog=rem({"Remotes","Misc","FogTouched"}),
Craft=rem({"Remotes","Crafting","Craft"}),
}
local function fire(r,a,b)
if not r then return false end
local ok=pcall(function()
if r:IsA("RemoteFunction")then r:InvokeServer(a,b)else r:FireServer(a,b)end
end)
return ok
end
local function triggerPrompt(pr)
if not pr then return end
pcall(function()
pr.HoldDuration=0
pr.RequiresLineOfSight=false
if pr.MaxActivationDistance<35 then pr.MaxActivationDistance=35 end
end)
if fireproximityprompt then
pcall(function()fireproximityprompt(pr)end)
else
pcall(function()
pr:InputHoldBegin()
task.wait(0.03)
pr:InputHoldEnd()
end)
end
end
local function inRange(p,r)
local rt=root()
if not(rt and p)then return false end
local ok,pos=pcall(function()return p.Position end)
if not ok or not pos then
pcall(function()pos=p:GetPivot().Position end)
end
if not pos then return false end
return(pos-rt.Position).Magnitude<=r
end
local function isFood(it)
local n=string.lower(it.Name)
return string.find(n,"food")or string.find(n,"beans")or string.find(n,"chips")or string.find(n,"carrot")or string.find(n,"cola")or string.find(n,"water")or string.find(n,"apple")or string.find(n,"can")or string.find(n,"meat")~=nil
end
local function hungerPct()
local h=hum()
if not h then return 100 end
local c=ch()
local hv=c and c:FindFirstChild("Hunger")
if hv and hv:IsA("NumberValue")and hv.MaxValue>0 then
return hv.Value/hv.MaxValue*100
end
return 100
end
local function isHostile(m)
if not m or not m.Parent then return false end
if m==ch()then return false end
if P:GetPlayerFromCharacter(m)then return false end
if m:GetAttribute("Player")==true or m:GetAttribute("Ally")==true then return false end
if m:GetAttribute("Team")=="Players"then return false end
if m:GetAttribute("Dead")==true or m:GetAttribute("Untouchable")==true or m:GetAttribute("Untargetable")==true then return false end
local mh=m:FindFirstChildOfClass("Humanoid")
if mh and mh.Health<=0 then return false end
return true
end
local function meleeTool()
local c=ch()
local t=c and c:FindFirstChildOfClass("Tool")
if not t then return nil end
if t:FindFirstChild("HitTargets")or string.find(string.lower(t.Name),"knife")or string.find(string.lower(t.Name),"axe")or string.find(string.lower(t.Name),"bat")or string.find(string.lower(t.Name),"machete")then
return t
end
return nil
end
local T1=Win:Tab({Title="生存",Icon="heart"})
T1:Section({Title="移动"})
T1:Toggle({Title="自动冲刺",Value=true,Callback=function(v)cfg.AutoSprint=v end})
T1:Toggle({Title="无视减速",Value=true,Callback=function(v)cfg.NoSlow=v end})
T1:Slider({Title="移动速度",Value={Min=16,Max=60,Default=27},Callback=function(v)
cfg.SpeedHack=true
cfg.SpeedVal=math.min(v,27)
local h=hum()
if h then h.WalkSpeed=cfg.SpeedVal end
end})
T1:Toggle({Title="飞行",Value=false,Callback=function(v)
cfg.Fly=v
local rt=root()
if not v and rt then
rt.AssemblyLinearVelocity=Vector3.zero
end
end})
T1:Toggle({Title="穿墙",Value=false,Callback=function(v)
cfg.Noclip=v
if not v then
local c=ch()
for _,p in pairs(c and c:GetChildren()or{})do
if p:IsA("BasePart")then p.CanCollide=true end
end
end
end})
T1:Section({Title="自动拾取"})
T1:Toggle({Title="自动拾取",Value=false,Callback=function(v)cfg.AutoPickup=v end})
T1:Slider({Title="拾取范围",Value={Min=5,Max=30,Default=15},Callback=function(v)cfg.PickupRange=v end})
T1:Toggle({Title="自动进食",Value=false,Callback=function(v)cfg.AutoEat=v end})
T1:Slider({Title="饥饿低于多少吃",Value={Min=10,Max=90,Default=40},Callback=function(v)cfg.EatHP=v end})
T1:Button({Title="一键开全图",Callback=function()
local n=0
for _,o in pairs(WS:GetChildren())do
local pr=o:FindFirstChildWhichIsA("ProximityPrompt",true)
if pr and string.find(string.lower(pr.ObjectText or""),"fog")then
triggerPrompt(pr)
n=n+1
end
end
fire(R.Fog,true)
WindUI:Notify({Title="地图",Content="已尝试点亮 "..n.." 处迷雾",Duration=3})
end})
local T2=Win:Tab({Title="战斗",Icon="sword"})
T2:Section({Title="近战"})
T2:Toggle({Title="击杀光环",Value=false,Callback=function(v)cfg.KillAura=v end})
T2:Slider({Title="攻击范围",Value={Min=8,Max=40,Default=16},Callback=function(v)cfg.AuraRange=v end})
T2:Toggle({Title="攻击僵尸",Value=true,Callback=function(v)cfg.AttackZ=v end})
T2:Toggle({Title="攻击土匪",Value=true,Callback=function(v)cfg.AttackB=v end})
T2:Button({Title="劈砍全部（一次性）",Callback=function()
local t=meleeTool()
if not t then
WindUI:Notify({Title="战斗",Content="手上不是近战武器",Duration=3})
return
end
local rt=root()
if not rt then return end
local list={}
local f=WS:FindFirstChild("Characters")
for _,m in pairs(f and f:GetChildren()or{})do
if isHostile(m)then
local z=m:GetAttribute("Zombie")==true
local b=m:GetAttribute("Bandit")==true
if(not z and not b)or(z and cfg.AttackZ)or(b and cfg.AttackB)then
local p=m:FindFirstChild("HumanoidRootPart")or m:FindFirstChild("Torso")or m.PrimaryPart
if p and inRange(p,cfg.AuraRange)then
table.insert(list,m)
end
end
end
end
local s=WS:FindFirstChild("Structures")
for _,o in pairs(s and s:GetChildren()or{})do
if o:GetAttribute("Health")~=nil and inRange(o,cfg.AuraRange)then
table.insert(list,o)
end
end
if#list==0 then
WindUI:Notify({Title="战斗",Content="附近没有目标",Duration=2})
return
end
pcall(function()
local sw=t:FindFirstChild("Swing")
if sw then sw:FireServer()end
t:Activate()
end)
task.wait(0.08)
pcall(function()
local ht=t:FindFirstChild("HitTargets")
if ht then ht:FireServer(list)end
end)
WindUI:Notify({Title="战斗",Content="已劈砍 "..#list.." 个目标",Duration=2})
end})
local T3=Win:Tab({Title="透视",Icon="eye"})
T3:Section({Title="视觉"})
local hl={}
local function clearHL()
for k,v in pairs(hl)do
pcall(function()v:Destroy()end)
hl[k]=nil
end
end
local function mkHL(obj,suffix,color)
if hl[suffix]then return end
local h=Instance.new("Highlight")
h.FillColor=color
h.FillTransparency=0.55
h.OutlineColor=color
h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
h.Adornee=obj
h.Parent=game:GetService("CoreGui")
hl[suffix]=h
end
T3:Toggle({Title="怪物透视",Value=false,Callback=function(v)
cfg.MobESP=v
if not v then clearHL()end
end})
T3:Toggle({Title="物品透视",Value=false,Callback=function(v)
cfg.ItemESP=v
if not v then clearHL()end
end})
T3:Toggle({Title="全亮",Value=false,Callback=function(v)
cfg.Fullbright=v
game:GetService("Lighting").Brightness=v and 3 or 1
game:GetService("Lighting").Ambient=v and Color3.fromRGB(180,180,180)or Color3.fromRGB(70,70,70)
end})
T3:Button({Title="关闭全部透视",Callback=function()
cfg.MobESP=false
cfg.ItemESP=false
clearHL()
end})
local T4=Win:Tab({Title="其他",Icon="settings"})
T4:Section({Title="工具"})
T4:Button({Title="重置角色",Callback=function()
local r=rem({"Remotes","Misc","Reset"})
if not fire(r)then
local h=hum()
if h then h.Health=0 end
end
end})
T4:Button({Title="重新连接",Callback=function()
pcall(function()
game:GetService("TeleportService"):Teleport(game.PlaceId,LP)
end)
end})
T4:Toggle({Title="自动防踢",Value=true,Callback=function(v)
getgenv().STA_AntiAFK=v
end})
task.spawn(function()
while task.wait(1)do
if cfg.MobESP or cfg.ItemESP then
pcall(function()
local rt=root()
if not rt then return end
if cfg.MobESP then
local f=WS:FindFirstChild("Characters")
for _,m in pairs(f and f:GetChildren()or{})do
if isHostile(m)and inRange(m,600)then
local isZ=m:GetAttribute("Zombie")==true
mkHL(m,"m"..m:GetDebugId(),isZ and Color3.fromRGB(255,60,60)or Color3.fromRGB(255,180,0))
else
local k="m"..m:GetDebugId()
if hl[k]then pcall(function()hl[k]:Destroy()end)hl[k]=nil end
end
end
end
if cfg.ItemESP then
local f=WS:FindFirstChild("DroppedItems")
for _,o in pairs(f and f:GetChildren()or{})do
local nm=string.lower(o.Name)
local col=nil
if isFood(o)then col=Color3.fromRGB(80,255,120)
elseif string.find(nm,"fuel")or string.find(nm,"gas")then col=Color3.fromRGB(255,120,0)
elseif string.find(nm,"scrap")or string.find(nm,"battery")then col=Color3.fromRGB(120,200,255)
elseif string.find(nm,"gun")or string.find(nm,"rifle")or string.find(nm,"pistol")or string.find(nm,"ammo")then col=Color3.fromRGB(255,80,255)
else col=Color3.fromRGB(255,255,255)end
mkHL(o,"i"..o:GetDebugId(),col)
end
end
end)
end
end
end)
task.spawn(function()
while task.wait(0.1)do
pcall(function()
local h=hum()
local c=ch()
local rt=root()
if not(h and c and rt)then return end
if cfg.AutoSprint then
c:SetAttribute("SprintingClient",true)
local ws=c:FindFirstChild("WalkSpeedClient")
local sp=ws and ws:FindFirstChild("Sprint")
if sp and h.MoveDirection.Magnitude>0.1 then
fire(sp,true)
end
end
if cfg.NoSlow then
pcall(function()
_G.inBlizzard=false
if c:GetAttribute("UsingMedical")then c:SetAttribute("UsingMedical",false)end
if c:GetAttribute("CrawlerSlow")then c:SetAttribute("CrawlerSlow",nil)end
end)
end
if cfg.SpeedHack then
if math.abs(h.WalkSpeed-cfg.SpeedVal)>0.5 then h.WalkSpeed=cfg.SpeedVal end
end
if cfg.Noclip then
for _,p in pairs(c:GetDescendants())do
if p:IsA("BasePart")and p.CanCollide then p.CanCollide=false end
end
end
if cfg.Fly then
local cam=WS.CurrentCamera
local dir=Vector3.zero
if cam then
local cf=cam.CFrame
if UIS:IsKeyDown(Enum.KeyCode.W)then dir=dir+cf.LookVector end
if UIS:IsKeyDown(Enum.KeyCode.S)then dir=dir-cf.LookVector end
if UIS:IsKeyDown(Enum.KeyCode.D)then dir=dir+cf.RightVector end
if UIS:IsKeyDown(Enum.KeyCode.A)then dir=dir-cf.RightVector end
if UIS:IsKeyDown(Enum.KeyCode.Space)then dir=dir+Vector3.new(0,1,0)end
if UIS:IsKeyDown(Enum.KeyCode.LeftControl)then dir=dir-Vector3.new(0,1,0)end
end
local spd=math.min(cfg.FlySpeed,27)
if dir.Magnitude>0 then
rt.AssemblyLinearVelocity=dir.Unit*spd
else
rt.AssemblyLinearVelocity=Vector3.zero
end
end
end)
end
end)
task.spawn(function()
while task.wait(0.35)do
pcall(function()
if not alive()then return end
if cfg.AutoPickup then
local f=WS:FindFirstChild("DroppedItems")
for _,it in pairs(f and f:GetChildren()or{})do
if inRange(it,cfg.PickupRange)then
fire(R.Pick,it)
local pr=it:FindFirstChildWhichIsA("ProximityPrompt",true)
if pr then triggerPrompt(pr)end
end
end
end
if cfg.AutoEat and hungerPct()<cfg.EatHP then
local f=WS:FindFirstChild("DroppedItems")
for _,it in pairs(f and f:GetChildren()or{})do
if isFood(it)and inRange(it,cfg.PickupRange)then
fire(R.Pick,it)
local pr=it:FindFirstChildWhichIsA("ProximityPrompt",true)
if pr then triggerPrompt(pr)end
task.wait(1.5)
break
end
end
end
end)
end
end)
task.spawn(function()
local last=0
while task.wait(0.05)do
local ok,err=pcall(function()
if not cfg.KillAura then return end
if not alive()then return end
local t=meleeTool()
if not t then return end
local rt=root()
if not rt then return end
if os.clock()-last<0.2 then return end
local list={}
local f=WS:FindFirstChild("Characters")
for _,m in pairs(f and f:GetChildren()or{})do
if isHostile(m)then
local z=m:GetAttribute("Zombie")==true
local b=m:GetAttribute("Bandit")==true
if(not z and not b)or(z and cfg.AttackZ)or(b and cfg.AttackB)then
local p=m:FindFirstChild("HumanoidRootPart")or m:FindFirstChild("Torso")or m.PrimaryPart
if p and inRange(p,cfg.AuraRange)then table.insert(list,m)end
end
end
end
if#list==0 then return end
last=os.clock()
local sw=t:FindFirstChild("Swing")
if sw then sw:FireServer()end
t:Activate()
task.wait(0.06)
local ht=t:FindFirstChild("HitTargets")
if ht then ht:FireServer(list)end
end)
end
end)
LP.CharacterAdded:Connect(function(c)
task.wait(1)
if cfg.AutoSprint then
pcall(function()c:SetAttribute("SprintingClient",true)end)
end
end)
