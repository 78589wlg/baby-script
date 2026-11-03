local WindUI=loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua"))()
local P=game:GetService("Players")
local LP=P.LocalPlayer
local WS=game:GetService("Workspace")
local UIS=game:GetService("UserInputService")
local PPS=game:GetService("ProximityPromptService")
local Win=WindUI:CreateWindow({Title="偷一个蛋"})
local cfg={AutoPrompt=false,Range=25,EggESP=false,PlayerESP=false,Speed=false,SpeedVal=30,Noclip=false,InfJump=false,AntiAFK=true}
local function ch()return LP.Character end
local function root()
local c=ch()
return c and(c:FindFirstChild("HumanoidRootPart")or c.PrimaryPart)
end
local function hum()
local c=ch()
return c and c:FindFirstChildOfClass("Humanoid")
end
local function near(p,r)
local rt=root()
if not(rt and p)then return false end
return(p.Position-rt.Position).Magnitude<=r
end
local T1=Win:Tab({Title="自动化",Icon="hand"})
T1:Section({Title="交互"})
T1:Toggle({Title="自动触发交互",Value=false,Callback=function(v)cfg.AutoPrompt=v end})
T1:Slider({Title="触发距离",Value={Min=5,Max=60,Default=25},Callback=function(v)cfg.Range=v end})
T1:Button({Title="立即触发一次",Callback=function()
local n=0
for _,pr in pairs(PPS:GetPromptList())do
if pr.Enabled and near(pr.Parent,cfg.Range)then
pcall(function()
pr.HoldDuration=0
pr:InputHoldBegin()
task.wait(0.05)
pr:InputHoldEnd()
end)
n=n+1
end
end
WindUI:Notify({Title="交互",Content="触发了 "..n.." 个",Duration=2})
end})
T1:Section({Title="防挂机"})
T1:Toggle({Title="防踢下线",Value=true,Callback=function(v)cfg.AntiAFK=v end})
local T2=Win:Tab({Title="透视",Icon="eye"})
T2:Section({Title="标记"})
local hl={}
local function clear()
for k,v in pairs(hl)do
pcall(function()v:Destroy()end)
hl[k]=nil
end
end
local function mark(obj,key,col)
if hl[key]then return end
local h=Instance.new("Highlight")
h.FillColor=col
h.OutlineColor=col
h.FillTransparency=0.6
h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
h.Adornee=obj
h.Parent=game:GetService("CoreGui")
hl[key]=h
end
T2:Toggle({Title="蛋透视",Value=false,Callback=function(v)cfg.EggESP=v if not v then clear()end end})
T2:Toggle({Title="玩家透视",Value=false,Callback=function(v)cfg.PlayerESP=v if not v then clear()end end})
T2:Button({Title="关闭全部透视",Callback=function()
cfg.EggESP=false
cfg.PlayerESP=false
clear()
end})
local T3=Win:Tab({Title="玩家",Icon="user"})
T3:Section({Title="移动"})
T3:Slider({Title="移动速度",Value={Min=16,Max=100,Default=30},Callback=function(v)
cfg.Speed=true
cfg.SpeedVal=v
local h=hum()
if h then h.WalkSpeed=v end
end})
T3:Toggle({Title="穿墙",Value=false,Callback=function(v)
cfg.Noclip=v
if not v then
local c=ch()
for _,p in pairs(c and c:GetChildren()or{})do
if p:IsA("BasePart")then p.CanCollide=true end
end
end
end})
T3:Toggle({Title="无限跳跃",Value=false,Callback=function(v)cfg.InfJump=v end})
local T4=Win:Tab({Title="其他",Icon="settings"})
T4:Section({Title="工具"})
T4:Button({Title="重生",Callback=function()
local h=hum()
if h then h.Health=0 end
end})
T4:Button({Title="重新连接",Callback=function()
pcall(function()game:GetService("TeleportService"):Teleport(game.PlaceId,LP)end)
end})
UIS.JumpRequest:Connect(function()
if cfg.InfJump then
local h=hum()
if h then h:ChangeState(Enum.HumanoidStateType.Jumping)end
end
end)
LP.Idled:Connect(function()
if cfg.AntiAFK then
pcall(function()
local vu=game:GetService("VirtualUser")
vu:CaptureController()
vu:ClickButton2(Vector2.new())
end)
end
end)
task.spawn(function()
while task.wait(0.2)do
pcall(function()
if not cfg.AutoPrompt then return end
local rt=root()
if not rt then return end
for _,pr in pairs(PPS:GetPromptList())do
if pr.Enabled and near(pr.Parent,cfg.Range)then
pcall(function()
if pr.HoldDuration>0 then pr.HoldDuration=0 end
pr:InputHoldBegin()
task.wait(0.03)
pr:InputHoldEnd()
end)
end
end
end)
end
end)
task.spawn(function()
while task.wait(0.5)do
pcall(function()
local rt=root()
if not rt then return end
if cfg.EggESP then
for _,o in pairs(WS:GetDescendants())do
local n=o.Name
if#n<=20 and string.find(n,"Egg")and(o:IsA("Model")or o:IsA("BasePart"))then
local p=o:IsA("Model")and(o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart",true))or o
if p and near(p,400)then
mark(o,"e"..o:GetDebugId(),Color3.fromRGB(255,220,0))
end
end
end
end
if cfg.PlayerESP then
for _,pl in pairs(P:GetPlayers())do
if pl~=LP and pl.Character then
mark(pl.Character,"p"..pl.Name,Color3.fromRGB(255,60,60))
end
end
end
end)
end
end)
task.spawn(function()
while task.wait(0.1)do
pcall(function()
local c=ch()
local h=hum()
if not(h and c)then return end
if cfg.Speed and math.abs(h.WalkSpeed-cfg.SpeedVal)>0.5 then h.WalkSpeed=cfg.SpeedVal end
if cfg.Noclip then
for _,p in pairs(c:GetDescendants())do
if p:IsA("BasePart")and p.CanCollide then p.CanCollide=false end
end
end
end)
end
end)
