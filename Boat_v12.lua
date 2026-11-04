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

local function allZones()
local t={}
for _,ch in ipairs(gs:GetChildren())do
local ln=ch.Name:lower()
if ln:find("zone")then
t[#t+1]=ch
end
end
return t
end

local function blocksFolder()
return gs:FindFirstChild("Blocks")
end

local function blocksOf(pl)
local bf=blocksFolder()
if not bf then return {} end
local out={}
local uname=pl.Name
for _,ch in ipairs(bf:GetChildren())do
local hit=false
if ch.Name==uname then hit=true
elseif ch:GetAttribute("Owner")==uname then hit=true
elseif ch:GetAttribute("Player")==uname then hit=true
elseif ch:GetAttribute("UserId")==pl.UserId then hit=true
elseif ch.Name:find(uname,1,true)then hit=true
end
if hit then
out[#out+1]=ch
end
end
return out
end

local function boatContainerOf(pl)
local bf=blocksFolder()
if bf then
local f=bf:FindFirstChild(pl.Name)
if f then return f end
for _,ch in ipairs(bf:GetChildren())do
if ch:GetAttribute("Owner")==pl.Name or ch:GetAttribute("Player")==pl.Name then return ch end
if ch:GetAttribute("UserId")==pl.UserId then return ch end
end
end
return nil
end

local function zoneOfPlayer(pl)
local tc=tostring(pl.TeamColor)
local tcL=tc:lower()
for _,z in ipairs(allZones())do
if z.Name:lower()==(tcL.."zone")then return z end
end
for _,z in ipairs(allZones())do
if z.Name:lower():find(tcL,1,true)then return z end
end
return nil
end

local SKIP={Head=1,Torso=1,["Left Arm"]=1,["Right Arm"]=1,["Left Leg"]=1,["Right Leg"]=1,HumanoidRootPart=1,UpperTorso=1,LowerTorso=1,["LeftUpperArm"]=1,["LeftLowerArm"]=1,["LeftHand"]=1,["RightUpperArm"]=1,["RightLowerArm"]=1,["RightHand"]=1,["LeftUpperLeg"]=1,["LeftLowerLeg"]=1,["LeftFoot"]=1,["RightUpperLeg"]=1,["RightLowerLeg"]=1,["RightFoot"]=1}

local function isCharPart(p)
local ok,r=pcall(function()
local m=p:FindFirstAncestorOfClass("Model")
while m do
if m:FindFirstChildOfClass("Humanoid")then return true end
m=m:FindFirstAncestorOfClass("Model")
end
return false
end)
return ok and r or false
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
if not SKIP[v.Name]and not isCharPart(v)then
out[#out+1]=v
end
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
local okt,entry=pcall(function()
local rel=p.Position-origin
local cf=p.CFrame
local xv,yv,zv=cf.XVector,cf.YVector,cf.ZVector
return {
N=p.Name,
M=matName(p),
C={math.floor(p.Color.R*255+0.5),math.floor(p.Color.G*255+0.5),math.floor(p.Color.B*255+0.5)},
S={round(p.Size.X,3),round(p.Size.Y,3),round(p.Size.Z,3)},
P={round(rel.X,3),round(rel.Y,3),round(rel.Z,3)},
X={round(xv.X,4),round(xv.Y,4),round(xv.Z,4)},
Y={round(yv.X,4),round(yv.Y,4),round(yv.Z,4)},
Z={round(zv.X,4),round(zv.Y,4),round(zv.Z,4)},
A=p.Anchored and 1 or 0,
T=round(p.Transparency,2),
}
end)
if okt and entry then list[#list+1]=entry end
end
return list,#parts,origin
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
local function plist()
local t={}
for _,pl in ipairs(P:GetPlayers())do
if pl~=LP then t[#t+1]=pl.Name end
end
table.sort(t)
if #t==0 then t={"（只有你一个人）"}end
return t
end
local pdd=T2:Dropdown({Title="本服玩家",Values=plist(),Value=plist()[1],Callback=function(v)
if v~="（只有你一个人）"then target=v end
end})
T2:Button({Title="刷新玩家列表",Callback=function()
WindUI:Notify({Title="复制船",Content="关掉这个窗口再打开，列表会更新",Duration=4})
end})
T2:Button({Title="诊断：显示所有建造区",Callback=function()
local zs=allZones()
if #zs==0 then
WindUI:Notify({Title="诊断",Content="workspace 里没有任何 Zone",Duration=6})
return
end
local out={}
for i=1,math.min(#zs,8)do
local z=zs[i]
local parts=collectParts(z)
out[i]=z.Name.."="..#parts.."块"
end
WindUI:Notify({Title="建造区("..#zs..")",Content=table.concat(out,"\n"),Duration=10})
local me=tostring(LP.TeamColor)
local mine=zoneOfPlayer(LP)
WindUI:Notify({Title="我的队伍",Content=me.."  对应建造区："..(mine and mine.Name or "未找到"),Duration=8})
end})
T2:Button({Title="查看 Blocks 文件夹结构（关键）",Callback=function()
local bf=blocksFolder()
if not bf then
WindUI:Notify({Title="Blocks",Content="workspace 里没有 Blocks",Duration=5})
return
end
local lines={}
lines[1]="Blocks 共 "..#bf:GetChildren().." 个直接子项"
local cnt=0
for _,ch in ipairs(bf:GetChildren())do
cnt=cnt+1
if cnt>25 then lines[#lines+1]="...还有更多" break end
local np=0
pcall(function()
for _,d in ipairs(ch:GetDescendants())do
if d:IsA("BasePart")then np=np+1 end
if np>500 then break end
end
end)
local attrs=""
pcall(function()
for k,v in pairs(ch:GetAttributes())do
attrs=attrs.." "..k.."="..tostring(v)
end
end)
lines[#lines+1]=ch.Name.." ["..ch.ClassName.."] Part="..np..attrs
end
local txt=table.concat(lines,"\n")
pcall(function()setclipboard(txt)end)
WindUI:Notify({Title="Blocks",Content="已复制 "..#lines.." 行",Duration=8})
end})
T2:Button({Title="查看我的模型里有什么",Callback=function()
local z=boatContainerOf(LP)
if not z then
WindUI:Notify({Title="模型",Content="找不到以你名字命名的模型",Duration=4})
return
end
local lines={}
local function walk(inst,depth)
if depth>3 then return end
local pad=string.rep("  ",depth)
local txt=pad..inst.Name.." ["..inst.ClassName.."]"
if inst:IsA("BasePart")then
txt=txt.." "..tostring(math.floor(inst.Size.X*10)/10).."x"..tostring(math.floor(inst.Size.Y*10)/10).."x"..tostring(math.floor(inst.Size.Z*10)/10)
end
lines[#lines+1]=txt
local n=0
for _,c in ipairs(inst:GetChildren())do
n=n+1
if n>18 then lines[#lines+1]=pad.."  ..." break end
walk(c,depth+1)
end
end
walk(z,0)
local txt=table.concat(lines,"\n")
pcall(function()setclipboard(txt)end)
WindUI:Notify({Title="我的模型",Content="已复制 "..#lines.." 行到剪贴板",Duration=7})
end})
T2:Button({Title="导出 workspace 顶层结构（重要）",Callback=function()
local lines={}
for _,ch in ipairs(gs:GetChildren())do
local n=0
local parts=0
pcall(function()
for _,d in ipairs(ch:GetDescendants())do
n=n+1
if d:IsA("BasePart")then parts=parts+1 end
if n>3000 then break end
end
end)
lines[#lines+1]=ch.Name.." ["..ch.ClassName.."] 子项="..n.." 内含Part="..parts
end
local txt=table.concat(lines,"\n")
pcall(function()setclipboard(txt)end)
WindUI:Notify({Title="workspace",Content="已复制 "..#lines.." 项到剪贴板",Duration=8})
end})
T2:Button({Title="导出结构树到剪贴板（重要）",Callback=function()
local z=zoneOfPlayer(LP)
if not z then
WindUI:Notify({Title="结构树",Content="找不到你的建造区",Duration=4})
return
end
local lines={}
local function walk(inst,depth,path)
if depth>4 then return end
local pad=string.rep("  ",depth)
local kind=inst.ClassName
local extra=""
if inst:IsA("BasePart")then
extra=" size="..tostring(math.floor(inst.Size.X*10)/10)..","..tostring(math.floor(inst.Size.Y*10)/10)..","..tostring(math.floor(inst.Size.Z*10)/10)
end
lines[#lines+1]=pad..inst.Name.." ["..kind.."]"..extra
local n=0
for _,c in ipairs(inst:GetChildren())do
n=n+1
if n>25 then
lines[#lines+1]=pad.."  ...还有更多"
break
end
walk(c,depth+1,path.."/"..c.Name)
end
end
walk(z,0,z.Name)
local txt=table.concat(lines,"\n")
pcall(function()setclipboard(txt)end)
WindUI:Notify({Title="结构树",Content="已复制 "..#lines.." 行到剪贴板，粘贴发给我",Duration=8})
end})
T2:Button({Title="扫描我的船（预览方块数）",Callback=function()
local z=boatContainerOf(LP)
if not z then WindUI:Notify({Title="复制船",Content="Blocks 里没有你的文件夹，先去建造区放几块",Duration=4})return end
local _,n=buildBlocks(z)
if n==0 then
WindUI:Notify({Title="复制船",Content="建造区里没有方块",Duration=3})
else
WindUI:Notify({Title="复制船",Content="你的建造区共 "..n.." 个方块",Duration=4})
end
end})

T2:Section({Title="导出"})
T2:Button({Title="导出选中玩家的船",Callback=function()
local okRun,errRun=pcall(function()
if target==""then
WindUI:Notify({Title="复制船",Content="请先在输入框填对方用户名",Duration=3})
return
end
local pl=P:FindFirstChild(target)
if not pl then
WindUI:Notify({Title="复制船",Content="玩家已离开",Duration=3})
return
end
local z=boatContainerOf(pl)
if not z then
WindUI:Notify({Title="复制船",Content="Blocks 里找不到 "..target.." 的文件夹",Duration=4})
return
end
local list,n,anc=buildBlocks(z)
if not list or n==0 then
WindUI:Notify({Title="复制船",Content=target.." 的船是空的（还没开始建）",Duration=4})
return
end
local av=anc or Vector3.new(0,0,0)
local data={v=1,src=target,zone=z.Name,count=n,time=os.date("%Y-%m-%d %H:%M:%S"),anchor={round(av.X,3),round(av.Y,3),round(av.Z,3)},blocks=list}
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
local kinds={}
for _,b in ipairs(list)do
kinds[b.N]=(kinds[b.N]or 0)+1
end
local ks={}
for k,v in pairs(kinds)do ks[#ks+1]=k.."x"..v end
table.sort(ks)
local brief=table.concat(ks," ")
if #brief>120 then brief=brief:sub(1,120).."..." end
WindUI:Notify({Title="复制船",Content="共 "..n.." 块："..brief,Duration=8})
WindUI:Notify({Title="复制船",Content=(wrote and ("已存到 BoatCopy/"..fname)or "已复制到系统剪贴板"),Duration=5})
pcall(function()setclipboard(enc)end)
end)
if not okRun then
WindUI:Notify({Title="导出失败",Content=tostring(errRun):sub(1,180),Duration=10})
end
end})
T2:Button({Title="查看数据样本（前5块）",Callback=function()
if not lastExport then
WindUI:Notify({Title="样本",Content="先导出一次",Duration=3})
return
end
local ok,d=pcall(function()return HS:JSONDecode(lastExport)end)
if not ok or not d.blocks then
WindUI:Notify({Title="样本",Content="解析失败",Duration=3})
return
end
local lines={}
for i=1,math.min(#d.blocks,5)do
local b=d.blocks[i]
local sx=b.S and string.format("%.2f,%.2f,%.2f",b.S[1],b.S[2],b.S[3])or"?"
lines[i]=b.N.." 尺寸="..sx
end
local txt=table.concat(lines,"\n")
pcall(function()setclipboard(txt)end)
WindUI:Notify({Title="数据样本",Content="已复制前"..math.min(#d.blocks,5).."块",Duration=6})
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

T2:Section({Title="重建（仅本地显示）"})
getgenv().BabyBoatLift=getgenv().BabyBoatLift or 4
T2:Slider({Title="显示高度偏移",Value={Min=-20,Max=60,Default=4},Callback=function(v)
getgenv().BabyBoatLift=math.floor(v)
end})
local built={}
local buildFolderName="BabyBoatPreview"

local function clearBuilt()
local old=gs:FindFirstChild(buildFolderName)
if old then pcall(function()old:Destroy()end)end
built={}
end

local function rebuild(jsonText,scale)
local ok,data=pcall(function()return HS:JSONDecode(jsonText)end)
if not ok or type(data)~="table"or not data.blocks then
WindUI:Notify({Title="重建",Content="数据格式不对",Duration=4})
return
end
local zn=zoneOfPlayer(LP)
local basePos
if zn then
basePos=zn.Position+Vector3.new(0,zn.Size.Y/2+getgenv().BabyBoatLift,0)
else
local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
basePos=(hrp and hrp.Position or Vector3.new(0,10,0))+Vector3.new(0,6,0)
end
clearBuilt()
local folder=Instance.new("Folder")
folder.Name=buildFolderName
folder.Parent=gs
local cnt=0
for _,b in ipairs(data.blocks)do
local p=Instance.new("Part")
p.Name=b.N or"Block"
pcall(function()
if b.M then p.Material=Enum.Material[b.M]end
end)
pcall(function()
if b.C then p.Color=Color3.fromRGB(b.C[1],b.C[2],b.C[3])end
end)
pcall(function()
if b.S then
local sx,sy,sz=b.S[1],b.S[2],b.S[3]
if getgenv().BabyBoatSnap then
local function q(n)
local r=math.floor(n+0.5)
if r<1 then r=1 end
return r
end
sx,sy,sz=q(sx),q(sy),q(sz)
end
p.Size=Vector3.new(sx,sy,sz)*(scale or 1)
end
end)
local off=Vector3.new(b.P[1],b.P[2],b.P[3])*(scale or 1)
p.Anchored=true
p.CanCollide=false
p.CanTouch=false
p.CanQuery=false
p.CastShadow=false
local rot
if b.X and b.Y and b.Z then
rot=CFrame.new(
b.X[1],b.Y[1],b.Z[1],
b.X[2],b.Y[2],b.Z[2],
b.X[3],b.Y[3],b.Z[3]
)
else
rot=CFrame.Angles(0,math.rad(b.R or 0),0)
end
p.CFrame=CFrame.new(basePos+off)*rot
p.Parent=folder
cnt=cnt+1
end
WindUI:Notify({Title="重建",Content="已在建造区上方显示 "..cnt.." 块（只有你能看到）",Duration=7})
end

getgenv().BabyBoatSnap=getgenv().BabyBoatSnap or false
T2:Toggle({Title="尺寸取整（修复扁平方块）",Value=false,Callback=function(v)
getgenv().BabyBoatSnap=v
end})
T2:Button({Title="重建上次导出的船",Callback=function()
if not lastExport then
WindUI:Notify({Title="重建",Content="先导出一次",Duration=3})
return
end
rebuild(lastExport,1)
end})
T2:Button({Title="清除重建的方块",Callback=function()
clearBuilt()
WindUI:Notify({Title="重建",Content="已清除",Duration=2})
end})
local fileDD
local function fileList()
local t={}
pcall(function()
if not listfiles then return end
if isfolder and isfolder("BoatCopy")then
for _,f in ipairs(listfiles("BoatCopy"))do
local n=f:match("[^/\\]+$")or f
if n:find("%.build$")or n:find("%.json$")or n:find("%.txt$")then
t[#t+1]=n
end
end
end
end)
table.sort(t)
if #t==0 then t={"（没有文件）"}end
return t
end
fileDD=T2:Dropdown({Title="选择文件",Values=fileList(),Value=fileList()[1],Callback=function()end})
T2:Button({Title="刷新文件列表",Callback=function()
WindUI:Notify({Title="文件",Content="重开窗口后可看到最新列表",Duration=4})
end})
T2:Button({Title="加载选中的文件",Callback=function()
local name=nil
pcall(function()name=fileDD.Value end)
if not name or name=="（没有文件）"then
WindUI:Notify({Title="加载",Content="没有可用的文件",Duration=3})
return
end
local path="BoatCopy/"..name
local ok,txt=pcall(function()return readfile(path)end)
if not ok or not txt or txt==""then
WindUI:Notify({Title="加载",Content="读不到 "..path,Duration=4})
return
end
rebuild(txt,1)
end})
T2:Button({Title="从剪贴板读入并重建",Callback=function()
local txt
pcall(function()txt=getclipboard()end)
if not txt or txt==""then
WindUI:Notify({Title="重建",Content="剪贴板是空的",Duration=3})
return
end
rebuild(txt,1)
end})

T2:Section({Title="说明"})
T2:Button({Title="这个功能能做什么",Callback=function()
WindUI:Notify({Title="说明",Content="扫描别人建造区的方块，导成 .build 文件。不会在游戏里建造，也不会改服务器存档。",Duration=8})
end})
