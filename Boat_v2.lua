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

-- ===== 复制别人的船（导出文件）=====
local T2=Win:Tab({Title="复制船",Icon="copy"})
T2:Section({Title="扫描设置"})
local HS=game:GetService("HttpService")

local function zoneNameOf(pl)
local tc=tostring(pl.TeamColor)
local n=tc.."Zone"
if gs:FindFirstChild(n)then return n end
for _,ch in ipairs(gs:GetChildren())do
local ln=ch.Name:lower()
if ln:find("zone")and ln:find(tc:lower())then return ch.Name end
end
return nil
end

local function collectParts(cont)
local out={}
if not cont then return out end
local seen={}
local stack={cont}
while #stack>0 do
local cur=table.remove(stack)
for _,v in ipairs(cur:GetChildren())do
if not seen[v]then
seen[v]=true
if v:IsA("BasePart")then
out[#out+1]=v
elseif v:IsA("Folder")or v:IsA("Model")then
stack[#stack+1]=v
end
end
end
end
return out
end

local function round(n,d)
local m=10^(d or 3)
return math.floor(n*m+0.5)/m
end

local function matName(p)
local ok,r=pcall(function()return p.Material.Name end)
return ok and r or "Plastic"
end

local function buildBlocks(cont)
local parts=collectParts(cont)
if #parts==0 then return nil,0 end
local origin=parts[1].Position
local list={}
for _,p in ipairs(parts)do
local rel=p.Position-origin
local cf=p.CFrame
local ry=math.deg(math.atan2(-cf.LookVector.X,-cf.LookVector.Z))
local ok,rx=pcall(function()
local r=cf:ToOrientation()
return math.deg(r)
end)
list[#list+1]={
N=p.Name,
M=matName(p),
C={math.floor(p.Color.R*255+0.5),math.floor(p.Color.G*255+0.5),math.floor(p.Color.B*255+0.5)},
S={round(p.Size.X,3),round(p.Size.Y,3),round(p.Size.Z,3)},
P={round(rel.X,3),round(rel.Y,3),round(rel.Z,3)},
R=round(ry,2),
A=p.Anchored and 1 or 0,
T=round(p.Transparency,2),
}
end
return list,#parts
end

local function playerList()
local t={}
for _,pl in ipairs(P:GetPlayers())do
t[#t+1]=pl.Name
end
table.sort(t)
return t
end

local target=""
local lastExport=nil

T2:Section({Title="选择目标"})
T2:Button({Title="列出房间内所有玩家",Callback=function()
local t=playerList()
local out={}
for i=1,#t do out[i]=t[i] end
WindUI:Notify({Title="玩家("..#t..")",Content=#t>0 and table.concat(out,"  ")or"房间里只有你",Duration=8})
end})
T2:Input({Title="目标玩家名",Placeholder="输入对方的用户名，进去重试",Value="",Callback=function(v)target=v:gsub("^%s+",""):gsub("%s+$","") end})
T2:Button({Title="扫描我的船（预览方块数）",Callback=function()
local zn=zoneNameOf(LP)
if not zn then WindUI:Notify({Title="复制船",Content="找不到你的建造区",Duration=3})return end
local _,n=buildBlocks(gs[zn])
if n==0 then
WindUI:Notify({Title="复制船",Content="建造区里没有方块",Duration=3})
else
WindUI:Notify({Title="复制船",Content="你的建造区共 "..n.." 个方块",Duration=4})
end
end})

T2:Section({Title="导出"})
T2:Button({Title="导出选中玩家的船",Callback=function()
if target==""then
WindUI:Notify({Title="复制船",Content="请先在输入框填对方用户名",Duration=3})
return
end
local pl=P:FindFirstChild(target)
if not pl then
WindUI:Notify({Title="复制船",Content="玩家已离开",Duration=3})
return
end
local zn=zoneNameOf(pl)
if not zn then
WindUI:Notify({Title="复制船",Content="找不到 "..target.." 的建造区（可能不在建造阶段）",Duration=4})
return
end
local list,n=buildBlocks(gs[zn])
if not list or n==0 then
WindUI:Notify({Title="复制船",Content="该玩家建造区没有方块",Duration=3})
return
end
local data={v=1,src=target,zone=zn,count=n,time=os.date("%Y-%m-%d %H:%M:%S"),blocks=list}
local ok,enc=pcall(function()return HS:JSONEncode(data)end)
if not ok then
WindUI:Notify({Title="复制船",Content="编码失败",Duration=3})
return
end
lastExport=enc
local fname=target.."_"..os.date("%m%d_%H%M")..".build"
local wrote=false
pcall(function()
if not writefile then return end
if makefolder and isfolder and not isfolder("BoatCopy")then makefolder("BoatCopy")end
writefile("BoatCopy/"..fname,enc)
wrote=true
end)
WindUI:Notify({Title="复制船",Content="已扫描 "..n.." 个方块，"..(wrote and ("已存到 BoatCopy/"..fname)or "已复制到系统剪贴板"),Duration=6})
pcall(function()setclipboard(enc)end)
end})
T2:Button({Title="把上次导出复制到剪贴板",Callback=function()
if not lastExport then
WindUI:Notify({Title="复制船",Content="还没有导出过",Duration=3})
return
end
pcall(function()setclipboard(lastExport)end)
WindUI:Notify({Title="复制船",Content="已复制（"..#lastExport.." 字符）",Duration=3})
end})
T2:Button({Title="查看导出文件列表",Callback=function()
local ok,list=pcall(function()
if not listfiles then return{}end
if isfolder and isfolder("BoatCopy")then return listfiles("BoatCopy")end
return{}
end)
if not ok or #list==0 then
WindUI:Notify({Title="复制船",Content="没有导出文件（或执行器不支持写文件）",Duration=4})
else
local names={}
for i=1,math.min(#list,6)do
names[#names+1]=list[i]:match("[^/\\]+$")or list[i]
end
WindUI:Notify({Title="导出文件("..#list..")",Content=table.concat(names,"\n"),Duration=8})
end
end})

T2:Section({Title="说明"})
T2:Button({Title="这个功能能做什么",Callback=function()
WindUI:Notify({Title="说明",Content="扫描别人建造区的方块，导成 .build 文件。不会在游戏里建造，也不会改服务器存档。",Duration=8})
end})
