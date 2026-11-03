local WindUI=loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua"))()
local P=game:GetService("Players")
local LP=P.LocalPlayer
local WS=game:GetService("Workspace")
local RS=game:GetService("ReplicatedStorage")
local Win=WindUI:CreateWindow({Title="99 Nights in the Forest"})
local RE=RS:FindFirstChild("RemoteEvents")or RS:FindFirstChild("Remotes")
local cfg={God=false,Aura=false,AuraRange=30,Wood=false,WoodRange=60,Bring=false,Speed=false,SpeedVal=30,Noclip=false,InfJump=false,ESP=false,AntiAFK=true}
local function ch()return LP.Character end
local function rt()
local c=ch()
return c and(c:FindFirstChild("HumanoidRootPart")or c.PrimaryPart)
end
local function hu()
local c=ch()
return c and c:FindFirstChildOfClass("Humanoid")
end
local function dist(a,b)
return(a-b).Magnitude
end
local function findRE(n)
local e=RS:FindFirstChild("RemoteEvents")or RS:FindFirstChild("Remotes")
if not e then
for _,v in pairs(RS:GetChildren())do
if v:IsA("Folder")and v:FindFirstChild(n)then return v[n]end
end
return nil
end
return e:FindFirstChild(n)
end
local T1=Win:Tab({Title="生存",Icon="shield"})
T1:Section({Title="防护"})
T1:Toggle({Title="免伤",Value=false,Callback=function(v)
cfg.God=v
end})
T1:Toggle({Title="防踢",Value=true,Callback=function(v)
cfg.AntiAFK=v
end})
T1:Section({Title="移动"})
T1:Toggle({Title="加速",Value=false,Callback=function(v)
cfg.Speed=v
if not v then
local h=hu()
if h then h.WalkSpeed=16 end
end
end})
T1:Slider({Title="速度值",Value={Min=16,Max=200,Default=30},Callback=function(v)
cfg.SpeedVal=v
end})
T1:Toggle({Title="穿墙",Value=false,Callback=function(v)
cfg.Noclip=v
end})
T1:Toggle({Title="无限跳",Value=false,Callback=function(v)
cfg.InfJump=v
end})
local T2=Win:Tab({Title="刷取",Icon="pickaxe"})
T2:Section({Title="自动"})
T2:Toggle({Title="自动砍树",Value=false,Callback=function(v)
cfg.Wood=v
end})
T2:Slider({Title="砍树范围",Value={Min=10,Max=150,Default=60},Callback=function(v)
cfg.WoodRange=v
end})
T2:Toggle({Title="自动拾取",Value=false,Callback=function(v)
cfg.Bring=v
end})
local T3=Win:Tab({Title="战斗",Icon="sword"})
T3:Section({Title="攻击"})
T3:Toggle({Title="击杀光环",Value=false,Callback=function(v)
cfg.Aura=v
end})
T3:Slider({Title="光环范围",Value={Min=5,Max=80,Default=30},Callback=function(v)
cfg.AuraRange=v
end})
local T4=Win:Tab({Title="透视",Icon="eye"})
T4:Section({Title="显示"})
local espList={}
local function mkEsp(obj,col)
if obj:FindFirstChild("N99ESP")then return end
local hl=Instance.new("Highlight")
hl.Name="N99ESP"
hl.FillColor=col
hl.FillTransparency=0.45
hl.OutlineColor=col
hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
hl.Adornee=obj
hl.Parent=obj
table.insert(espList,hl)
end
local function clearEsp()
for _,v in pairs(espList)do
pcall(function()v:Destroy()end)
end
espList={}
end
T4:Toggle({Title="怪物透视",Value=false,Callback=function(v)
cfg.ESP=v
if not v then clearEsp()end
end})
task.spawn(function()
while task.wait(0.5)do
if cfg.God then
local h=hu()
if h and h.Health<h.MaxHealth then h.Health=h.MaxHealth end
end
if cfg.Speed then
local h=hu()
if h then h.WalkSpeed=cfg.SpeedVal end
end

end
end)
task.spawn(function()
while task.wait(0.12)do
if cfg.Noclip then
local c=ch()
if c then
for _,v in pairs(c:GetDescendants())do
if v:IsA("BasePart")and v.CanCollide then v.CanCollide=false end
end
end
end
end
end)
task.spawn(function()
while task.wait(0.2)do
if cfg.Aura then
local r=rt()
if r then
for _,v in pairs(WS:GetDescendants())do
if v:IsA("Humanoid")and v.Parent~=ch()and v.Health>0 then
local m=v.Parent
local hr=m:FindFirstChild("HumanoidRootPart")or m.PrimaryPart
if hr and dist(r.Position,hr.Position)<=cfg.AuraRange then
if m:FindFirstChildWhichIsA("Humanoid")and not P:GetPlayerFromCharacter(m)then
pcall(function()v.Health=0 end)
local de=findRE("DamageEnemy")or findRE("DealDamage")
if de then pcall(function()de:FireServer(m)end)end
end
end
end
end
end
end
end
end)
task.spawn(function()
while task.wait(0.25)do
if cfg.Wood then
local r=rt()
if r then
for _,v in pairs(WS:GetDescendants())do
if v:IsA("Model")and(v.Name:lower():find("tree")or v.Name:lower():find("log"))then
local pp=v:FindFirstChildWhichIsA("ProximityPrompt",true)
if pp then
local hr=v:FindFirstChild("HumanoidRootPart")or v.PrimaryPart
if not hr or dist(r.Position,hr.Position)<=cfg.WoodRange then
pcall(function()pp.HoldDuration=0 end)
pcall(function()
if fireproximityprompt then
fireproximityprompt(pp)
else
pp:InputHoldBegin()
task.wait()
pp:InputHoldEnd()
end
end)
end
end
end
end
end
end
end
end)
task.spawn(function()
while task.wait(0.4)do
if cfg.Bring then
local r=rt()
if r then
for _,v in pairs(WS:GetDescendants())do
if v:IsA("Tool")and v.Parent and v.Parent~=ch()then
if v:FindFirstChild("Handle")then
pcall(function()v.Handle.CFrame=CFrame.new(r.Position+Vector3.new(0,1,0))end)
end
end
end
end
end
end
end)
task.spawn(function()
while task.wait(1)do
if cfg.ESP then
for _,v in pairs(WS:GetDescendants())do
if v:IsA("Humanoid")and v.Health>0 and v.Parent~=ch()then
local m=v.Parent
if not P:GetPlayerFromCharacter(m)then
mkEsp(m,Color3.fromRGB(255,80,80))
end
end
end
end
end
end)
local UIS=game:GetService("UserInputService")
UIS.JumpRequest:Connect(function()
if cfg.InfJump then
local h=hu()
if h then h:ChangeState(Enum.HumanoidStateType.Jumping)end
end
end)
