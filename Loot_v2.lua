-- 婴儿脚本 · 布洛克斯战利品 V13
-- 反踢出常驻 + 通用透视 / 自动拾取 / 移动增强
local P=game:GetService("Players")
local LP=P.LocalPlayer
local UIS=game:GetService("UserInputService")
local RS=game:GetService("ReplicatedStorage")

-- ================= 反踢出（启动即生效，不可关闭） =================
local AK={on=false,blocked=0}
local function notify(t,x)
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification",{Title=t,Text=x,Duration=6})
end)
end

local function installHooks()
local done=false
pcall(function()
local gm=getrawmetatable(game)
if not gm then return end
local old=gm.__namecall
if not old then return end
local hooked=function(self,...)
local m=""
pcall(function()m=getnamecallmethod()end)
if (m=="Kick" or m=="kick" or m=="KickPlayer")then
local okc,cc=pcall(function()return checkcaller()end)
if not okc or cc==false then
AK.blocked=AK.blocked+1
return nil
end
end
return old(self,...)
end
local fn=hooked
pcall(function()
if newcclosure then fn=newcclosure(hooked) end
end)
pcall(function()setreadonly(gm,false)end)
gm.__namecall=fn
pcall(function()setreadonly(gm,true)end)
done=true
end)
if not done then
pcall(function()
local old
old=hookmetamethod(game,"__namecall",function(self,...)
local m=""
pcall(function()m=getnamecallmethod()end)
if m=="Kick" or m=="kick" or m=="KickPlayer" then
local okc,cc=pcall(function()return checkcaller()end)
if not okc or cc==false then
AK.blocked=AK.blocked+1
return nil
end
end
return old(self,...)
end)
done=true
end)
end
AK.on=done
return done
end

-- 断掉游戏可能用来让你自我踢出的同步通道
local function cutRigSync()
pcall(function()
local pk=RS:FindFirstChild("Packages")
local nw=pk and pk:FindFirstChild("Networking")
local rg=nw and nw:FindFirstChild("RE/RigSync/Refresh")
if rg and getconnections then
for _,c in pairs(getconnections(rg.OnClientEvent))do
pcall(function()c:Disconnect()end)
end
end
end)
end

local akOK=installHooks()
task.spawn(function()
task.wait(3)
cutRigSync()
end)
notify("反踢出","已开启 · 服务端强制断开无法拦截")

-- ================= 通用工具 =================
local function hum()
local c=LP.Character
if c then return c:FindFirstChildOfClass("Humanoid")end
end
local function root()
local c=LP.Character
if c then return c:FindFirstChild("HumanoidRootPart")end
end
local function lower(s)return string.lower(tostring(s or ""))end

local ITEM_KW={"loot","drop","chest","crate","item","coin","gem","gold","money","cash","reward","bag","orb","shard","key","box","pickup"}
local MOB_KW={"mob","enemy","monster","boss","slime","goblin","frog","croc","witch","zombie","skeleton","guard"}
local function matchAny(name,list)
local n=lower(name)
for _,k in ipairs(list)do
if string.find(n,k,1,true)then return true end
end
return false
end

-- ================= WindUI =================
local WindUI=loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua"))()
local Win=WindUI:CreateWindow({Title="战利品 V13"})

local T1=Win:Tab({Title="移动",Icon="move"})
local T2=Win:Tab({Title="透视",Icon="eye"})
local T3=Win:Tab({Title="自动",Icon="cpu"})
local T4=Win:Tab({Title="反踢出",Icon="shield"})

local sp,jp=16,50

T1:Section({Title="速度"})
T1:Slider({Title="移动速度",Value={Min=16,Max=300,Default=16},Callback=function(v)
sp=v
local h=hum()
if h then h.WalkSpeed=sp end
end})
T1:Slider({Title="跳跃力",Value={Min=50,Max=300,Default=50},Callback=function(v)
jp=v
local h=hum()
if h then h.UseJumpPower=true h.JumpPower=jp end
end})

T1:Section({Title="飞行"})
local flyBV,flyBG,flyOn=false,false,false
T1:Toggle({Title="飞行",Value=false,Callback=function(v)
flyOn=v
local h=hum()
local r=root()
if not h or not r then flyOn=false return end
if v then
flyBV=Instance.new("BodyVelocity")
flyBV.MaxForce=Vector3.new(1e5,1e5,1e5)
flyBV.Velocity=Vector3.zero
flyBV.Parent=r
flyBG=Instance.new("BodyGyro")
flyBG.MaxTorque=Vector3.new(1e5,1e5,1e5)
flyBG.P=Vector3.new(1e4,1e4,1e4)
flyBG.CFrame=r.CFrame
flyBG.Parent=r
task.spawn(function()
while flyOn do
task.wait(0.05)
local r2=root()
if not r2 then break end
local dir=Vector3.zero
local cam=workspace.CurrentCamera
if cam then
local cf=cam.CFrame
if UIS:IsKeyDown(Enum.KeyCode.W)then dir=dir+cf.LookVector end
if UIS:IsKeyDown(Enum.KeyCode.S)then dir=dir-cf.LookVector end
if UIS:IsKeyDown(Enum.KeyCode.A)then dir=dir-cf.RightVector end
if UIS:IsKeyDown(Enum.KeyCode.D)then dir=dir+cf.RightVector end
if UIS:IsKeyDown(Enum.KeyCode.Space)then dir=dir+Vector3.new(0,1,0) end
if UIS:IsKeyDown(Enum.KeyCode.LeftControl)then dir=dir-Vector3.new(0,1,0) end
end
if dir.Magnitude>0 then dir=dir.Unit end
if flyBV and flyBV.Parent then flyBV.Velocity=dir*80 end
end
end)
else
if flyBV then pcall(function()flyBV:Destroy()end) flyBV=nil end
if flyBG then pcall(function()flyBG:Destroy()end) flyBG=nil end
end
end})

T1:Section({Title="其他"})
local nc={}
T1:Toggle({Title="无碰撞（穿墙）",Value=false,Callback=function(v)
local c=LP.Character
if not c then return end
for _,p in ipairs(c:GetDescendants())do
if p:IsA("BasePart")then
if v then
if p.CanCollide then nc[p]=true end
p.CanCollide=false
else
if nc[p] then p.CanCollide=true end
end
end
end
if not v then nc={} end
end})

-- ================= 透视 =================
local espFolder
local function espRoot()
local g=LP:FindFirstChildOfClass("PlayerGui")
if not g then return nil end
if espFolder and espFolder.Parent then return espFolder end
espFolder=Instance.new("Folder")
espFolder.Name="LootESP"
espFolder.Parent=g
return espFolder
end

local espItems={}   -- obj -> billboard
local function clearESP(map)
for o,b in pairs(map)do
if b then pcall(function()b:Destroy()end) end
end
for k in pairs(map)do map[k]=nil end
end

local itemOn,mobOn=false,false

local function tagFor(part,text,color)
local bb=Instance.new("BillboardGui")
bb.Size=UDim2.new(0,120,0,26)
bb.StudsOffset=Vector3.new(0,1.6,0)
bb.AlwaysOnTop=true
bb.MaxDistance=500
bb.Adornee=part
local tl=Instance.new("TextLabel")
tl.Size=UDim2.new(1,0,1,0)
tl.BackgroundTransparency=1
tl.Text=text
tl.TextColor3=color
tl.TextStrokeTransparency=0.4
tl.Font=Enum.Font.GothamBold
tl.TextSize=14
tl.Parent=bb
bb.Parent=espRoot()
return bb
end

local function scanESP()
if not (itemOn or mobOn)then return end
local keep={}
for _,d in ipairs(workspace:GetDescendants())do
if d:IsA("BasePart")then
local nm=d.Name
local isItem=itemOn and matchAny(nm,ITEM_KW)
local isMob=mobOn and matchAny(nm,MOB_KW)
if isItem or isMob then
keep[d]=true
if not espItems[d] or not espItems[d].Parent then
local col=isItem and Color3.fromRGB(80,255,160) or Color3.fromRGB(255,90,90)
espItems[d]=tagFor(d,nm,col)
end
end
end
end
for o,b in pairs(espItems)do
if not keep[o] or not o.Parent then
if b then pcall(function()b:Destroy()end) end
espItems[o]=nil
end
end
end

T2:Section({Title="物品 / 掉落"})
T2:Toggle({Title="显示掉落物和箱子",Value=false,Callback=function(v)
itemOn=v
if not v then scanESP() end
WindUI:Notify({Title="透视",Content=v and "已开启" or "已关闭",Duration=2})
end})
T2:Section({Title="怪物"})
T2:Toggle({Title="显示怪物 / BOSS",Value=false,Callback=function(v)
mobOn=v
if not v then scanESP() end
end})

T2:Section({Title="玩家"})
local pHL={}
T2:Toggle({Title="玩家高亮",Value=false,Callback=function(v)
if v then
for _,pl in ipairs(P:GetPlayers())do
if pl~=LP and pl.Character then
local h=Instance.new("Highlight")
h.FillColor=Color3.fromRGB(0,200,255)
h.FillTransparency=0.55
h.OutlineColor=Color3.fromRGB(0,200,255)
h.Adornee=pl.Character
h.Parent=pl.Character
pHL[pl]=h
end
end
else
for pl,h in pairs(pHL)do
if h then pcall(function()h:Destroy()end) end
end
pHL={}
end
end})

task.spawn(function()
while true do
task.wait(2)
pcall(scanESP)
end
end)

task.spawn(function()
while true do
task.wait(1)
if next(pHL)then
for pl,h in pairs(pHL)do
if not pl.Character or not h or not h.Parent then
if h then pcall(function()h:Destroy()end) end
pHL[pl]=nil
end
end
end
end
end)

-- ================= 自动 =================
local autoPick,fastPick=false,false
local paySkip=true
local PAY_KW={"buy","purchase","robux","r$","price","cost","unlock","pay","premium","购买","付费","解锁"}
local function isPaid(pr)
if not paySkip then return false end
local t,o="",""
pcall(function()t=lower(pr.PromptText)end)
pcall(function()o=lower(pr.ObjectText)end)
for _,k in ipairs(PAY_KW)do
if string.find(t,k,1,true)or string.find(o,k,1,true)then return true end
end
if t:match("%$%s*%d")or o:match("%$%s*%d")then return true end
return false
end

local function nearPrompts(maxDist)
local r=root()
if not r then return {} end
local out={}
for _,d in ipairs(workspace:GetDescendants())do
if d:IsA("ProximityPrompt") and d.Enabled and not isPaid(d)then
local pp=d.Parent
if pp and pp:IsA("BasePart")then
local dist=(pp.Position-r.Position).Magnitude
if dist<=maxDist then
out[#out+1]={pr=d,part=pp,dist=dist}
end
end
end
end
table.sort(out,function(a,b)return a.dist<b.dist end)
return out
end

task.spawn(function()
while true do
task.wait(0.35)
if autoPick then
pcall(function()
local list=nearPrompts(10)
for i=1,math.min(#list,2)do
local it=list[i]
pcall(function()it.pr:InputHoldBegin()end)
task.wait(0.12)
pcall(function()it.pr:InputHoldEnd()end)
end
end)
end
end
end)

-- 瞬移拾取：有风险，默认关
local tpPick=false
task.spawn(function()
while true do
task.wait(1.2)
if tpPick then
pcall(function()
local list=nearPrompts(200)
if #list==0 then return end
local it=list[1]
local r=root()
if not r then return end
r.CFrame=it.part.CFrame+Vector3.new(0,3,0)
task.wait(0.15)
pcall(function()it.pr:InputHoldBegin()end)
task.wait(0.15)
pcall(function()it.pr:InputHoldEnd()end)
end)
end
end
end)

local autoAtk=false
local strictOnly=true
local NPC_KW={"npc","shop","quest","vendor","merchant","seller","trader","dialog","guide","store","smith","banker","owner","clerk","waiter","doctor"}

local function isNPCModel(m)
if not m or not m:IsA("Model")then return true end
if matchAny(m.Name,NPC_KW)then return true end
if m:FindFirstChildOfClass("ProximityPrompt")then return true end
if m:FindFirstChildOfClass("Dialog")then return true end
return false
end

local function hostileTagged(m)
if matchAny(m.Name,MOB_KW)then return true end
local o=m
for _=1,3 do
o=o.Parent
if not o or o==workspace then break end
if matchAny(o.Name,MOB_KW)then return true end
end
return false
end

-- 刷怪样本：玩家手动指认一次，脚本按它的名字/所在文件夹认怪
local sample={ok=false,names={}}

local function sampleMatch(m)
if not sample.ok then return false end
local o=m
for _=1,4 do
if not o or o==workspace then break end
local n=lower(o.Name)
for _,sn in ipairs(sample.names)do
if n==sn then return true end
end
o=o.Parent
end
return false
end

local function learnSample()
local r=root()
if not r then return false,"没找到你的角色" end
local best,bd=nil,80
for _,d in ipairs(workspace:GetDescendants())do
if d:IsA("Humanoid") and d.Health>0 and d.Parent~=LP.Character then
local m=d.Parent
local isPlr=m and P:GetPlayerFromCharacter(m)
if not isPlr and not isNPCModel(m)then
local pr=m and (m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso") or m:FindFirstChild("UpperTorso"))
if pr then
local dist=(pr.Position-r.Position).Magnitude
if dist<bd then bd=dist best=m end
end
end
end
end
if not best then return false,"附近没找到怪，走近一点再点" end
local names={}
local o=best
for _=1,4 do
if not o or o==workspace then break end
names[#names+1]=lower(o.Name)
o=o.Parent
end
sample.names=names
sample.ok=true
return true,best.Name
end

local function nearestMob(maxDist)
local r=root()
if not r then return nil end
local best,bd=nil,maxDist
for _,d in ipairs(workspace:GetDescendants())do
if d:IsA("Humanoid") and d.Health>0 and d.Parent~=LP.Character then
local m=d.Parent
local isPlr=m and P:GetPlayerFromCharacter(m)
if not isPlr and not isNPCModel(m)then
local okt=false
if sample.ok then
okt=sampleMatch(m)
elseif strictOnly then
okt=hostileTagged(m)
else
okt=true
end
if okt then
local pr=m and (m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso") or m:FindFirstChild("UpperTorso"))
if pr then
local dist=(pr.Position-r.Position).Magnitude
if dist<bd then bd=dist best=d end
end
end
end
end
end
return best
end

local farmOn=false
local farmWarned=false
task.spawn(function()
while true do
task.wait(0.45)
if farmOn then
pcall(function()
local tgt=nearestMob(1000)
if not tgt then
if not farmWarned then
farmWarned=true
WindUI:Notify({Title="刷怪农场",Content="找不到目标：先走到怪旁边点「把最近的怪物设为样本」，或关掉严格模式",Duration=6})
end
return
end
farmWarned=false
local m=tgt.Parent
local pr=m and (m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Torso") or m:FindFirstChild("UpperTorso"))
local r=root()
if pr and r then
r.CFrame=pr.CFrame*CFrame.new(0,0,3.5)
task.wait(0.12)
local tool=LP.Character and LP.Character:FindFirstChildOfClass("Tool")
if tool then pcall(function()tool:Activate()end) end
end
end)
end
end
end)

task.spawn(function()
while true do
task.wait(0.25)
if autoAtk then
pcall(function()
local h=hum()
local tool=LP.Character and LP.Character:FindFirstChildOfClass("Tool")
local tgt=nearestMob(25)
if h and tool and tgt then
h:MoveTo(tgt.Parent.HumanoidRootPart.Position)
tool:Activate()
end
end)
end
end
end)

T3:Section({Title="拾取"})
T3:Toggle({Title="自动拾取（走到附近才触发）",Value=false,Callback=function(v)autoPick=v end})
T3:Toggle({Title="跳过付费选项（购买/Robux 不拿）",Value=true,Callback=function(v)paySkip=v end})
T3:Toggle({Title="瞬移拾取（快，但可能被反作弊盯）",Value=false,Callback=function(v)
tpPick=v
if v then WindUI:Notify({Title="注意",Content="瞬移拾取风险较高，已开反踢出兜底",Duration=4}) end
end})
T3:Section({Title="战斗"})
T3:Toggle({Title="自动攻击最近目标",Value=false,Callback=function(v)autoAtk=v end})
T3:Toggle({Title="严格模式（只打怪物，不碰商店/任务NPC）",Value=true,Callback=function(v)strictOnly=v end})

T3:Section({Title="刷怪农场"})
T3:Toggle({Title="自动刷怪农场（瞬移到怪旁边自动打）",Value=false,Callback=function(v)
farmOn=v
if v then
WindUI:Notify({Title="刷怪农场",Content="建议先走到怪旁边点「设为样本」，打得又准又不误伤",Duration=5})
end
end})
T3:Button({Title="把最近的怪物设为刷怪样本",Callback=function()
local ok,msg=learnSample()
WindUI:Notify({Title="刷怪样本",Content=ok and ("已学习："..msg) or ("失败："..tostring(msg)),Duration=6})
end})
T3:Button({Title="查看当前样本",Callback=function()
if not sample.ok then
WindUI:Notify({Title="刷怪样本",Content="还没设置",Duration=4})
else
WindUI:Notify({Title="刷怪样本",Content=table.concat(sample.names," / "),Duration=6})
end
end})
T3:Button({Title="清除刷怪样本",Callback=function()
sample.ok=false
sample.names={}
WindUI:Notify({Title="刷怪样本",Content="已清除",Duration=3})
end})

T3:Section({Title="传送"})
T3:Button({Title="传送到最近的掉落物",Callback=function()
local list=nearPrompts(9999)
local r=root()
if #list==0 then WindUI:Notify({Title="传送",Content="附近没有可交互物体",Duration=3})return end
if r then
r.CFrame=list[1].part.CFrame+Vector3.new(0,4,0)
WindUI:Notify({Title="传送",Content="已到 "..list[1].part.Name,Duration=3})
end
end})
T3:Button({Title="回到出生点",Callback=function()
local r=root()
local sp2=workspace:FindFirstChild("SpawnLocation")
if r and sp2 then r.CFrame=sp2.CFrame+Vector3.new(0,4,0) end
end})

-- ================= 反踢出页 =================
T4:Section({Title="状态"})
T4:Button({Title="查看拦截次数",Callback=function()
WindUI:Notify({Title="反踢出",Content="已拦截 "..tostring(AK.blocked).." 次踢出请求",Duration=5})
end})
T4:Button({Title="重新安装防护",Callback=function()
local ok=installHooks()
pcall(cutRigSync)
WindUI:Notify({Title="反踢出",Content=ok and "已重新安装" or "安装失败（执行器不支持）",Duration=4})
end})
T4:Section({Title="说明"})
T4:Button({Title="能拦什么？（点我看说明）",Callback=function()
WindUI:Notify({Title="能拦",Content="客户端发起的 Kick() 会被吃掉，比如检测到你飞天/瞬移后本地踢你",Duration=6})
end})
T4:Button({Title="拦不住什么？（点我看说明）",Callback=function()
WindUI:Notify({Title="拦不住",Content="服务器直接断线属于网络层，客户端收不到，只能重连",Duration=6})
end})

T4:Section({Title="本游戏"})
T4:Button({Title="复制本游戏 PlaceId（发我就能自动加载）",Callback=function()
pcall(function()if setclipboard then setclipboard(tostring(game.PlaceId))end end)
WindUI:Notify({Title="PlaceId",Content=tostring(game.PlaceId).." 已复制",Duration=5})
end})

LP.CharacterAdded:Connect(function(c)
local h=c:WaitForChild("Humanoid",10)
if h then
task.wait(0.6)
h.WalkSpeed=sp
h.UseJumpPower=true
h.JumpPower=jp
end
end)

notify("战利品脚本","已加载 · 反踢出生效中")
