local WindUI=loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua"))()
local P=game:GetService("Players")
local LP=P.LocalPlayer
local Win=WindUI:CreateWindow({Title="造船寻宝"})
local T1=Win:Tab({Title="刷钱",Icon="coins"})
T1:Section({Title="刷钱设置"})
local gs=game:GetService("Workspace")
local ge=gs:FindFirstChild("ClaimRiverResultsGold")
if not ge then ge=gs:WaitForChild("ClaimRiverResultsGold",10)end
local st=gs:FindFirstChild("BoatStages")
local ns=st and st:FindFirstChild("NormalStages")
local run=false
T1:Toggle({Title="自动刷钱",Value=false,Callback=function(s)
run=s
if s then
if not ns then
WindUI:Notify({Title="刷钱",Content="当前不是造船寻宝",Duration=3})
run=false
return
end
WindUI:Notify({Title="刷钱",Content="已开启",Duration=2})
task.spawn(function()
while run do
local c=LP.Character
local h=c and c:FindFirstChildOfClass("Humanoid")
local r=c and c:FindFirstChild("HumanoidRootPart")
if h and r then
pcall(function()
h.MaxHealth=1e9
h.Health=1e9
end)
for i=1,10 do
if not run then break end
local s2=ns:FindFirstChild("CaveStage"..i)
local d=s2 and s2:FindFirstChild("DarknessPart")
if d then
pcall(function()r.CFrame=d.CFrame end)
task.wait(0.6)
end
end
if ge then pcall(function()ge:FireServer()end)end
task.wait(0.3)
if h then pcall(function()h.Health=0 end)end
end
task.wait(1.5)
end
end)
else
WindUI:Notify({Title="刷钱",Content="已停止",Duration=2})
end
end})
