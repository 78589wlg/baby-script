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


-- ===== 复制功能独立卡密（支持自动发卡接口）=====
local HSK=game:GetService("HttpService")
local GH="https://raw.githubusercontent.com/78589wlg/baby-script/main/"
local KEYURL=GH.."keys.txt"
local APIFILE=GH.."api.txt"
local LOCALKEYS={"BOAT-VIP-8888","BOAT-A1B2-C3D4","少羽没面","卡密制作婴儿脚本6767"}
local KEYFILE="BoatCopy/key.txt"
local CACHEF="BoatCopy/ok.txt"
local unlocked=false
local API=""
local apiLoaded=false

local function trim(s)
return (tostring(s):gsub("^%s+",""):gsub("%s+$",""))
end

local function today()
local ok,d=pcall(function()return os.date("%Y-%m-%d")end)
return ok and d or "1970-01-01"
end

local function readSaved()
local ok,v=pcall(function()return readfile(KEYFILE)end)
if ok and type(v)=="string" then return trim(v) end
return nil
end

local function saveKey(k)
pcall(function()
if makefolder and isfolder and not isfolder("BoatCopy")then makefolder("BoatCopy")end
writefile(KEYFILE,k)
end)
end

local function readCache()
local ok,v=pcall(function()return readfile(CACHEF)end)
if not ok or type(v)~="string" then return nil end
local k,e=v:match("^([^|]*)|([^|]*)$")
if not k then return nil end
return {k=trim(k),e=trim(e or "")}
end

local function writeCache(k,exp)
pcall(function()
if makefolder and isfolder and not isfolder("BoatCopy")then makefolder("BoatCopy")end
writefile(CACHEF,trim(k).."|"..tostring(exp or ""))
end)
end

local function getAPI()
if apiLoaded then return API end
apiLoaded=true
local ok,txt=pcall(function()return game:HttpGet(APIFILE.."?t="..tostring(os.time()))end)
if ok and type(txt)=="string" then
for line in txt:gmatch("[^\r\n]+")do
local t=trim(line)
if t~="" and t:sub(1,1)~="#" and t:find("^https?://")then
API=(t:gsub("/+$",""))
break
end
end
end
return API
end

local function loadKeyList()
local list={}
for _,e in ipairs(LOCALKEYS)do
local k,exp=e:match("^([^,]+),?(.*)$")
if k then
k=trim(k) exp=trim(exp)
if exp=="" then exp=nil end
list[#list+1]={k=k,exp=exp}
end
end
local ok,txt=pcall(function()return game:HttpGet(KEYURL.."?t="..tostring(os.time()))end)
if ok and type(txt)=="string" and #txt>3 then
for line in txt:gmatch("[^\r\n]+")do
line=trim(line)
if line~="" and line:sub(1,1)~="#" then
local k,exp=line:match("^([^,]+),?(.*)$")
if k then
k=trim(k) exp=trim(exp)
if exp=="" then exp=nil end
list[#list+1]={k=k,exp=exp}
end
end
end
end
return list
end

local function checkExp(exp)
if not exp or exp=="" then return true,"永久" end
local e=tostring(exp):gsub("[^%d]","")
if e=="" then return true,"永久" end
if #e==8 then e=e:sub(1,4).."-"..e:sub(5,6).."-"..e:sub(7,8) end
if e<today() then return false,e end
return true,e
end

local function verifyRemote(k)
local base=getAPI()
if base=="" then return nil,"未配置接口" end
local ok,txt=pcall(function()return game:HttpGet(base.."/verify?key="..k)end)
if not ok or type(txt)~="string" or #txt<3 then return nil,"接口连接失败" end
local okd,d=pcall(function()return HSK:JSONDecode(txt)end)
if not okd or type(d)~="table" then return nil,"接口返回异常" end
if d.ok then return true,tostring(d.exp or "") end
return false,tostring(d.msg or "卡密无效")
end

local function verifyKey(k)
k=trim(k)
if k=="" then return false,"请输入卡密",nil end
for _,e in ipairs(loadKeyList())do
if e.k==k then
local ok2,e2=checkExp(e.exp)
if not ok2 then return false,"卡密已于 "..e2.." 过期",nil end
if e2=="永久" then return true,"解锁成功（永久）",nil end
return true,"解锁成功，有效期至 "..e2,e2
end
end
local ok2,msg=verifyRemote(k)
if ok2==nil then
return false,"卡密不在名单里，且"..tostring(msg).."，请检查网络",nil
end
if ok2==true then
local exp=msg
if exp=="" then return true,"解锁成功（接口验证）",nil end
return true,"解锁成功，有效期至 "..exp,exp
end
return false,tostring(msg),nil
end

local buildCopyOnce
local buildCopyUI

local function unlockWith(k)
local ok,msg,exp=verifyKey(k)
WindUI:Notify({Title="复制功能卡密",Content=msg,Duration=7})
if ok then
unlocked=true
saveKey(trim(k))
writeCache(trim(k),exp or "")
if buildCopyOnce then buildCopyOnce() end
end
return ok
end

do
-- 与主脚本共用：主脚本验证通过后会写 BabyKey.txt
if not unlocked then
local okf,f=pcall(function()return readfile("BabyKey.txt")end)
if okf and type(f)=="string" then
local kk,ee=f:match("^([^|]*)|([^|\r\n]*)")
kk=kk and trim(kk) or ""
ee=ee and trim(ee) or ""
if kk~="" and checkExp(ee) then
unlocked=true
saveKey(kk)
writeCache(kk,ee)
end
end
end

local sv=readSaved()
if sv and sv~="" then
local c=readCache()
if c and c.k==sv then
local okok=checkExp(c.e)
if okok then unlocked=true end
end
if not unlocked then
local ok,res,exp=pcall(verifyKey,sv)
if ok and res==true then
unlocked=true
writeCache(sv,exp or "")
end
end
end
end

T1:Section({Title="复制功能卡密（单独）"})
local keyIn=""
T1:Input({Title="输入卡密",Placeholder="BOAT-XXXX-XXXX",Value="",Callback=function(t)keyIn=t end})
T1:Button({Title="验证并解锁复制功能",Callback=function()
unlockWith(keyIn)
end})
T1:Button({Title="忘记卡密？一键找回",Callback=function()
local k="卡密制作婴儿脚本6767"
pcall(function()if setclipboard then setclipboard(k)end end)
if unlocked then
WindUI:Notify({Title="复制功能卡密",Content="已解锁中｜永久卡密："..k.."（已复制）",Duration=8})
return
end
unlockWith(k)
end})
T1:Button({Title="清除已保存的卡密",Callback=function()
pcall(function()if delfile then delfile(KEYFILE)end end)
unlocked=false
WindUI:Notify({Title="卡密",Content="已清除，复制功能已锁定（重开脚本生效）",Duration=6})
end})
-- ===== 复制别人的船 =====
local T2=Win:Tab({Title="复制船",Icon="copy"})

local copyBuilt=false
buildCopyOnce=function()
if copyBuilt then return end
copyBuilt=true
WindUI:Notify({Title="复制功能",Content="卡密验证通过，功能已解锁",Duration=5})
buildCopyUI()
end

buildCopyUI=function()
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

-- 关键：以第一块为参照系做局部坐标，导出时同时记录包围盒（用于落地对齐）
local function buildBlocks(cont)
local parts=collectParts(cont)
if #parts==0 then return nil,0 end
local base=parts[1].CFrame
local baseInv=base:Inverse()
local list={}
local minV=nil
local maxV=nil
for _,p in ipairs(parts)do
local okt,entry=pcall(function()
local lp=baseInv*p.Position
local cf=baseInv*p.CFrame
local xv,yv,zv=cf.XVector,cf.YVector,cf.ZVector
local sx,sy,sz=p.Size.X,p.Size.Y,p.Size.Z
local lo=Vector3.new(lp.X-sx/2,lp.Y-sy/2,lp.Z-sz/2)
local hi=Vector3.new(lp.X+sx/2,lp.Y+sy/2,lp.Z+sz/2)
if not minV then
minV=lo
maxV=hi
else
minV=Vector3.new(math.min(minV.X,lo.X),math.min(minV.Y,lo.Y),math.min(minV.Z,lo.Z))
maxV=Vector3.new(math.max(maxV.X,hi.X),math.max(maxV.Y,hi.Y),math.max(maxV.Z,hi.Z))
end
local cls=p.ClassName
local shape=nil
if p:IsA("Part")then
local oks,sv=pcall(function()return p.Shape.Name end)
if oks then shape=sv end
end
local meshId,texId=nil,nil
if cls=="MeshPart"then
pcall(function()meshId=p.MeshId end)
pcall(function()texId=p.TextureID end)
end
local decos=nil
do
local dl={}
for _,ch2 in ipairs(p:GetChildren())do
if ch2:IsA("Decal")or ch2:IsA("Texture")then
dl[#dl+1]={k=ch2.ClassName,i=ch2.Texture,ta=round(ch2.Transparency*100,0),f=ch2.Face and ch2.Face.Name or "Front"}
elseif ch2:IsA("PointLight")or ch2:IsA("SpotLight")or ch2:IsA("SurfaceLight")then
dl[#dl+1]={k=ch2.ClassName,c={math.floor(ch2.Color.R*255+0.5),math.floor(ch2.Color.G*255+0.5),math.floor(ch2.Color.B*255+0.5)},ra=round(ch2.Range,1),br=round(ch2.Brightness,2)}
elseif ch2:IsA("SurfaceGui")then
dl[#dl+1]={k="SurfaceGui",f=ch2.Face and ch2.Face.Name or "Front"}
end
if #dl>=4 then break end
end
if #dl>0 then decos=dl end
end
return {
N=p.Name,
CL=cls,
SH=shape,
MI=meshId,
TX=texId,
D=decos,
M=matName(p),
C={math.floor(p.Color.R*255+0.5),math.floor(p.Color.G*255+0.5),math.floor(p.Color.B*255+0.5)},
S={round(sx,3),round(sy,3),round(sz,3)},
P={round(lp.X,3),round(lp.Y,3),round(lp.Z,3)},
X={round(xv.X,5),round(xv.Y,5),round(xv.Z,5)},
Y={round(yv.X,5),round(yv.Y,5),round(yv.Z,5)},
Z={round(zv.X,5),round(zv.Y,5),round(zv.Z,5)},
A=p.Anchored and 1 or 0,
T=round(p.Transparency,2),
R=round(p.Reflectance,2),
}
end)
if okt and entry then list[#list+1]=entry end
end
if #list==0 then return nil,0 end
local box={min={round(minV.X,3),round(minV.Y,3),round(minV.Z,3)},max={round(maxV.X,3),round(maxV.Y,3),round(maxV.Z,3)}}
return list,#parts,nil,box
end

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
local target=""
local pdd
local function refreshPlayers()
if not pdd then return end
pcall(function()pdd:Refresh(plist())end)
end
pdd=T2:Dropdown({Title="本服玩家",Values=plist(),Value=plist()[1],Callback=function(v)
if v~="（只有你一个人）"then target=v end
end})
P.PlayerAdded:Connect(function()task.wait(1)refreshPlayers()end)
P.PlayerRemoving:Connect(function()task.wait(1)refreshPlayers()end)
T2:Button({Title="刷新玩家列表",Callback=function()
refreshPlayers()
WindUI:Notify({Title="复制船",Content="玩家列表已刷新",Duration=3})
end})

T2:Section({Title="导出"})
local lastExport=nil
T2:Button({Title="导出选中玩家的船",Callback=function()
local okRun,errRun=pcall(function()
if target==""then
WindUI:Notify({Title="复制船",Content="先在上面选择目标玩家",Duration=3})
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
local list,n,_,box=buildBlocks(z)
if not list or n==0 then
WindUI:Notify({Title="复制船",Content=target.." 的船是空的（还没开始建）",Duration=4})
return
end
local data={v=2,src=target,zone=z.Name,count=#list,time=os.date("%Y-%m-%d %H:%M:%S"),box=box,blocks=list}
local ok,enc=pcall(function()return HS:JSONEncode(data)end)
if not ok then
WindUI:Notify({Title="复制船",Content="编码失败",Duration=4})
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
WindUI:Notify({Title="导出成功",Content="共 "..#list.." 块，文件="..tostring(wrote and fname or "(未写入文件)"),Duration=8})
end)
if not okRun then
WindUI:Notify({Title="导出失败",Content=tostring(errRun):sub(1,180),Duration=10})
end
end})

T2:Section({Title="加载 / 预览"})
getgenv().BabyBoatLift=getgenv().BabyBoatLift or 6
local buildFolderName="BabyBoatPreview"

local function clearBuilt()
local old=gs:FindFirstChild(buildFolderName)
if old then pcall(function()old:Destroy()end)end
end

-- 自检：在你脚下直接摆标记柱，并把你传过去看
local function selftest()
local res={}
local function add(k,v)res[#res+1]=k.."="..tostring(v)end
local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
add("角色",hrp~=nil)
local cam=gs.CurrentCamera
if cam then
add("摄像机模式",tostring(cam.CameraType))
add("摄像机位置",string.format("%.0f, %.0f, %.0f",cam.CFrame.Position.X,cam.CFrame.Position.Y,cam.CFrame.Position.Z))
end
if hrp and cam then
local rel=cam.CFrame:PointToObjectSpace(hrp.Position)
add("你相对镜头",string.format("前%.0f 右%.0f 下%.0f",-rel.Z,rel.X,-rel.Y))
local lv=cam.CFrame.LookVector
add("镜头朝向",string.format("%.0f, %.0f, %.0f",lv.X,lv.Y,lv.Z))
end
-- 在镜头正前方 12 格堆一串不同大小/颜色的方块，前 3 块用 CanCollide 抑制 + 全透明关掉
local base
if cam then
base=cam.CFrame.Position+cam.CFrame.LookVector*12
elseif hrp then
base=hrp.Position+Vector3.new(0,5,-12)
else
base=Vector3.new(0,20,0)
end
add("测试位置",string.format("%.0f, %.0f, %.0f",base.X,base.Y,base.Z))
local old=gs:FindFirstChild("BabySelfTest")
if old then pcall(function()old:Destroy()end)end
local folder=Instance.new("Folder")
folder.Name="BabySelfTest"
folder.Parent=gs
local made=0
for i=1,4 do
local okp,errp=pcall(function()
local p2=Instance.new("Part")
p2.Name="BabyMark"..i
p2.Size=Vector3.new(6,6,6)
p2.Anchored=true
p2.CanCollide=false
p2.CanQuery=false
p2.CanTouch=false
p2.CastShadow=false
p2.Material=Enum.Material.Neon
p2.Color=Color3.fromRGB(255,0,255)
p2.Transparency=0
p2.Position=base+Vector3.new((i-1)*10,(i-1)*3,0)
p2.Parent=folder
end)
if okp then made=made+1 else add("建第"..i.."个失败",errp)end
end
add("建立方块",made.."/4")
local f2=gs:FindFirstChild("BabySelfTest")
if f2 then
add("文件夹存在",true)
add("子项数",#f2:GetChildren())
local any=f2:FindFirstChild("BabyMark1")
if any then
add("第一块父对象",any.Parent and any.Parent.Name or "nil")
add("第一块坐标",string.format("%.0f, %.0f, %.0f",any.Position.X,any.Position.Y,any.Position.Z))
add("第一块可见",any.Transparency<1)
end
end
local txt=table.concat(res,"\n")
pcall(function()setclipboard(txt)end)
WindUI:Notify({Title="自检完成",Content=txt,Duration=14})
end

local function rebuild(jsonText,scale)
local ok,data=pcall(function()return HS:JSONDecode(jsonText)end)
if not ok or type(data)~="table"or not data.blocks then
WindUI:Notify({Title="加载",Content="文件内容不是有效的船数据",Duration=5})
return false,"bad json"
end
-- 默认就摆在你面前（和自检标记柱同一套算法，已证明能显示）
local anchor
local hrp0=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
if getgenv().BabyUseFix then
local fx=getgenv().BabyFixX or 0
local fy=getgenv().BabyFixY or 20
local fz=getgenv().BabyFixZ or 0
anchor=CFrame.new(fx,fy,fz)
else
-- 先估算船的跨度，决定摆多远（船大就放远，避免糊住镜头）
local span=20
if data.box and data.box.min and data.box.max then
local dx=data.box.max[1]-data.box.min[1]
local dy=data.box.max[2]-data.box.min[2]
local dz=data.box.max[3]-data.box.min[3]
span=math.max(dx,dy,dz)
end
local zoom0=getgenv().BabyZoom or 1
local dist=math.clamp(span*zoom0*1.1,16,220)
local cam=gs.CurrentCamera
if cam then
anchor=CFrame.new(cam.CFrame.Position+cam.CFrame.LookVector*dist+Vector3.new(0,span*zoom0*0.15,0))
elseif hrp0 then
anchor=CFrame.new(hrp0.Position+Vector3.new(0,8,0)-hrp0.CFrame.LookVector*dist)
else
anchor=CFrame.new(0,20,0)
end
end
-- 船底贴齐锚点所在平面
-- 旧格式适配改为可选（默认关闭，行为和 v28 一致）
local isOld=(data.v~=2)or(not data.box)
local shift=Vector3.new(0,0,0)
local fitScale=1
if getgenv().BabyFitOld and isOld and #data.blocks>0 then
local sum=Vector3.new(0,0,0)
local n0=0
local mn,mx=nil,nil
for _,b in ipairs(data.blocks)do
if b.P then
local q=Vector3.new(b.P[1],b.P[2],b.P[3])
sum=sum+q
n0=n0+1
if not mn then mn=q mx=q else
mn=Vector3.new(math.min(mn.X,q.X),math.min(mn.Y,q.Y),math.min(mn.Z,q.Z))
mx=Vector3.new(math.max(mx.X,q.X),math.max(mx.Y,q.Y),math.max(mx.Z,q.Z))
end
end
end
if n0>0 then
local center=sum/n0
shift=-center
if mn and mx then
local span=(mx-mn).Magnitude
if span>45 and span>0 then
fitScale=45/span
end
end
end
end
local lift=0
if data.box and data.box.min then lift=-data.box.min[2] end
local zoom=getgenv().BabyZoom or 1
local total=fitScale*zoom*(scale or 1)
if math.abs(total-1)>0.01 then
WindUI:Notify({Title="缩放",Content=string.format("预览缩放 %.0f%%",total*100),Duration=5})
end
clearBuilt()
local folder=Instance.new("Folder")
folder.Name=buildFolderName
folder.Parent=gs
local cnt=0
local firstErr=nil
for bi,b in ipairs(data.blocks)do
local okb,errb=pcall(function()
local p
local cls=tostring(b.CL or"Part")
local made=false
if (cls=="MeshPart")and b.MI and b.MI~=""then
local okm,mp=pcall(function()
local m=Instance.new("MeshPart")
m.MeshId=b.MI
if b.TX then m.TextureID=b.TX end
return m
end)
if okm and mp then p=mp made=true end
end
if not made then
p=Instance.new("Part")
local okS=pcall(function()
if b.SH then p.Shape=Enum.PartType[b.SH]end
end)
end
p.Name=tostring(b.N or"Block")
if b.M then pcall(function()p.Material=Enum.Material[b.M]end)end
if b.C then p.Color=Color3.fromRGB(b.C[1],b.C[2],b.C[3])end
if b.T then pcall(function()p.Transparency=b.T end)end
if b.R then pcall(function()p.Reflectance=b.R end)end
if b.D then
for _,dd in ipairs(b.D)do
pcall(function()
if dd.k=="Decal"or dd.k=="Texture"then
local o=Instance.new(dd.k)
o.Texture=dd.i or""
if dd.ta then o.Transparency=dd.ta/100 end
if dd.f and o.Face then o.Face=Enum.NormalId[dd.f]end
o.Parent=p
elseif dd.k=="PointLight"or dd.k=="SpotLight"or dd.k=="SurfaceLight"then
local o=Instance.new(dd.k)
if dd.c then o.Color=Color3.fromRGB(dd.c[1],dd.c[2],dd.c[3])end
if dd.ra then o.Range=dd.ra end
if dd.br then o.Brightness=dd.br end
o.Parent=p
elseif dd.k=="SurfaceGui"then
local o=Instance.new("SurfaceGui")
if dd.f and o.Face then o.Face=Enum.NormalId[dd.f]end
o.Parent=p
end
end)
end
end
local sx,sy,sz=b.S[1],b.S[2],b.S[3]
if getgenv().BabyBoatSnap then
local function q(n)
local r=math.floor(n+0.5)
if r<1 then r=1 end
return r
end
sx,sy,sz=q(sx),q(sy),q(sz)
end
p.Size=Vector3.new(sx,sy,sz)*total
p.Anchored=true
p.CanCollide=false
p.CanTouch=false
p.CanQuery=false
p.CastShadow=false
local rot
if b.X and b.Y and b.Z then
local vx=Vector3.new(b.X[1],b.X[2],b.X[3])
local vy=Vector3.new(b.Y[1],b.Y[2],b.Y[3])
local vz=Vector3.new(b.Z[1],b.Z[2],b.Z[3])
local okM,m=pcall(function()return CFrame.fromMatrix(Vector3.zero,vx,vy,vz)end)
if okM and m then
rot=m
else
local okM2,m2=pcall(function()return CFrame.new(Vector3.zero)*CFrame.new(0,0,0,vx.X,vx.Y,vx.Z,vy.X,vy.Y,vy.Z) end)
if okM2 and m2 then
rot=m2
else
rot=CFrame.Angles(0,math.atan2(-vx.Z,vx.X),0)
end
end
else
rot=CFrame.Angles(0,math.rad(b.R or 0),0)
end
local lp=(Vector3.new(b.P[1],b.P[2],b.P[3])+shift)*total+Vector3.new(0,lift*total,0)
local okC,cf2=pcall(function()return anchor*CFrame.new(lp)*rot end)
if not okC then cf2=CFrame.new(anchor.Position+lp)end
p.CFrame=cf2
p.Parent=folder
cnt=cnt+1
end)
if not okb and not firstErr then firstErr="第"..bi.."块: "..tostring(errb) end
end
if cnt==0 then
local m="一块都没摆出来 错误="..tostring(firstErr).." 数据块数="..#data.blocks
pcall(function()setclipboard(m)end)
WindUI:Notify({Title="加载失败",Content=m:sub(1,200),Duration=12})
return false,tostring(firstErr)
end
pcall(function()
local mk=Instance.new("Part")
mk.Name="BabyBoatMarker"
mk.Size=Vector3.new(3,3,3)
mk.Anchored=true mk.CanCollide=false mk.CanQuery=false
mk.Material=Enum.Material.Neon
mk.Color=Color3.fromRGB(255,255,0)
mk.Transparency=0.3
mk.CFrame=anchor
mk.Parent=folder
end)
getgenv().BabyBoatAnchor=anchor
pcall(function()
local tb=Instance.new("BillboardGui")
tb.Size=UDim2.new(0,220,0,60)
tb.AlwaysOnTop=true
tb.Adornee=folder:FindFirstChild("BabyBoatMarker")
local tl=Instance.new("TextLabel")
tl.Size=UDim2.new(1,0,1,0)
tl.BackgroundTransparency=1
tl.TextColor3=Color3.fromRGB(255,255,0)
tl.TextStrokeTransparency=0
tl.TextScaled=true
tl.Text="船在这里 ("..cnt.."块)"
tl.Parent=tb
tb.Parent=folder:FindFirstChild("BabyBoatMarker")
end)
local ax,ay,az=anchor.Position.X,anchor.Position.Y,anchor.Position.Z
-- 统计尺寸/颜色种类，判断"全是同一种方块"是数据问题还是赋值问题
local szSet,colSet=0,0
do
local a,b2={},{}
for _,v in ipairs(folder:GetChildren())do
if v:IsA("BasePart")then
a[string.format("%.2f,%.2f,%.2f",v.Size.X,v.Size.Y,v.Size.Z)]=1
b[v.Color.R.."_"..v.Color.G.."_"..v.Color.B]=1
end
end
for _ in pairs(a)do szSet=szSet+1 end
for _ in pairs(b)do colSet=colSet+1 end
end
local st=string.format("加载成功 块数=%d\n坐标 %.1f, %.1f, %.1f\n尺寸种类=%d 颜色种类=%d",cnt,ax,ay,az,szSet,colSet)
pcall(function()setclipboard(st)end)
WindUI:Notify({Title="加载成功",Content=string.format("已摆 %d 块  尺寸种类 %d  颜色种类 %d",cnt,szSet,colSet),Duration=12})
if getgenv().BabyAutoTp then
local hrp2=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
if hrp2 then
local b2=data.box
local w=0
if b2 and b2.max and b2.min then
w=(b2.max[1]-b2.min[1])
end
pcall(function()hrp2.CFrame=CFrame.new(ax+w/2+25,ay+12,az+w/2+25)end)
WindUI:Notify({Title="已传送",Content="到预览旁边了，环视四周",Duration=6})
end
end
return true,cnt
end
T2:Button({Title="重建上次导出的船",Callback=function()
if not lastExport then
WindUI:Notify({Title="加载",Content="先导出一次，或把文件内容复制进剪贴板",Duration=4})
return
end
rebuild(lastExport,1)
end})
T2:Button({Title="清除重建的方块",Callback=function()
clearBuilt()
WindUI:Notify({Title="加载",Content="已清除预览",Duration=2})
end})
T2:Slider({Title="预览高度偏移",Value={Min=-20,Max=80,Default=6},Callback=function(v)
local n=math.floor(v)
getgenv().BabyBoatLift=n
end})
getgenv().BabyBoatSnap=getgenv().BabyBoatSnap or false
T2:Toggle({Title="尺寸取整（方块看起来发扁时打开）",Value=false,Callback=function(v)
getgenv().BabyBoatSnap=v
end})

T2:Section({Title="文件"})
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
local selFile=fileList()[1]
local fileDD
local function refreshFiles()
local l=fileList()
if fileDD then pcall(function()fileDD:Refresh(l)end)end
selFile=l[1]
end
fileDD=T2:Dropdown({Title="选择文件",Values=fileList(),Value=selFile,Callback=function(v)selFile=v end})
T2:Button({Title="刷新文件列表",Callback=function()
refreshFiles()
WindUI:Notify({Title="文件",Content="当前："..tostring(selFile),Duration=4})
end})
T2:Button({Title="加载选中的文件",Callback=function()
local name=selFile
if not name or name=="（没有文件）"then
WindUI:Notify({Title="加载",Content="没有可用的文件，先导出一份",Duration=4})
return
end
local ok,txt=pcall(function()return readfile("BoatCopy/"..name)end)
if not ok or not txt or txt==""then
WindUI:Notify({Title="加载",Content="读不到 BoatCopy/"..name,Duration=6})
return
end
rebuild(txt,1)
end})
T2:Button({Title="从剪贴板读入并预览",Callback=function()
local txt
pcall(function()txt=getclipboard()end)
if not txt or txt==""then
WindUI:Notify({Title="加载",Content="剪贴板是空的",Duration=4})
return
end
if #txt<50 then
WindUI:Notify({Title="加载",Content="剪贴板内容太短，不是船数据",Duration=4})
return
end
rebuild(txt,1)
end})
T2:Button({Title="查看文件列表和大小",Callback=function()
local lines={}
local ok,err=pcall(function()
if not listfiles then lines[1]="执行器不支持 listfiles" return end
if not isfolder or not isfolder("BoatCopy")then lines[1]="BoatCopy 文件夹不存在" return end
local lf=listfiles("BoatCopy")or{}
lines[1]="共 "..#lf.." 个文件"
local i=2
for _,f in ipairs(lf)do
if i>10 then lines[i]="..." break end
local sz="?"
pcall(function()
local d=readfile(f)
if d then sz=#d.."B" end
end)
lines[i]=(f:match("[^/\\]+$")or f).."  "..sz
i=i+1
end
end)
if not ok then lines[1]="读取出错: "..tostring(err)end
local txt=table.concat(lines,"\n")
pcall(function()setclipboard(txt)end)
WindUI:Notify({Title="文件",Content=txt:sub(1,240),Duration=12})
end})
T2:Button({Title="删除选中的文件",Callback=function()
local name=selFile
if not name or name=="（没有文件）"then
WindUI:Notify({Title="删除",Content="没有选中文件",Duration=3})
return
end
local ok=pcall(function()delfile("BoatCopy/"..name)end)
if ok then
refreshFiles()
WindUI:Notify({Title="删除",Content="已删除 "..name,Duration=4})
else
WindUI:Notify({Title="删除",Content="删除失败",Duration=4})
end
end})
T2:Button({Title="全部删除导出文件",Callback=function()
local n=0
pcall(function()
if not listfiles or not isfolder or not isfolder("BoatCopy")then return end
for _,f in ipairs(listfiles("BoatCopy")or{})do
if pcall(function()delfile(f)end)then n=n+1 end
end
end)
refreshFiles()
WindUI:Notify({Title="删除",Content="已删除 "..n.." 个文件",Duration=5})
end})
T2:Button({Title="查看文件保存路径",Callback=function()
local real=""
pcall(function()
if isfolder and isfolder("BoatCopy")then
local lf=listfiles("BoatCopy")or{}
if #lf>0 then real=lf[1]:match("^(.+)[/\\][^/\\]+$")or"" end
end
end)
if real==""then real="BoatCopy" end
pcall(function()setclipboard(real)end)
WindUI:Notify({Title="保存路径",Content=real.."（已复制）",Duration=10})
end})

T2:Section({Title="找不到预览时"})
-- 固定坐标输入（默认 0,20,0 就是地图原点上方）
getgenv().BabyFixX=getgenv().BabyFixX or 0
getgenv().BabyFixY=getgenv().BabyFixY or 20
getgenv().BabyFixZ=getgenv().BabyFixZ or 0
T2:Input({Title="固定X",Placeholder="0",Value=tostring(getgenv().BabyFixX),Callback=function(t)
getgenv().BabyFixX=tonumber(t)or 0
end})
T2:Input({Title="固定Y",Placeholder="20",Value=tostring(getgenv().BabyFixY),Callback=function(t)
getgenv().BabyFixY=tonumber(t)or 20
end})
T2:Input({Title="固定Z",Placeholder="0",Value=tostring(getgenv().BabyFixZ),Callback=function(t)
getgenv().BabyFixZ=tonumber(t)or 0
end})
getgenv().BabyZoom=getgenv().BabyZoom or 1
T2:Slider({Title="预览缩放",Value={Min=5,Max=200,Default=100},Callback=function(v)
getgenv().BabyZoom=math.floor(v)/100
end})
T2:Button({Title="自动适配视野（缩到 40 格内）",Callback=function()
local name=selFile
if not name or name=="（没有文件）"then
WindUI:Notify({Title="适配",Content="先选一个文件",Duration=4})
return
end
local ok,txt=pcall(function()return readfile("BoatCopy/"..name)end)
if not ok or not txt then
WindUI:Notify({Title="适配",Content="读不到文件",Duration=4})
return
end
local ok2,d=pcall(function()return HS:JSONDecode(txt)end)
if not ok2 or not d.blocks then
WindUI:Notify({Title="适配",Content="解析失败",Duration=4})
return
end
local span=0
if d.box and d.box.min and d.box.max then
span=math.max(d.box.max[1]-d.box.min[1],d.box.max[2]-d.box.min[2],d.box.max[3]-d.box.min[3])
else
local mn,mx=nil,nil
for _,b in ipairs(d.blocks)do
if b.P then
local q=Vector3.new(b.P[1],b.P[2],b.P[3])
if not mn then mn=q mx=q else
mn=Vector3.new(math.min(mn.X,q.X),math.min(mn.Y,q.Y),math.min(mn.Z,q.Z))
mx=Vector3.new(math.max(mx.X,q.X),math.max(mx.Y,q.Y),math.max(mx.Z,q.Z))
end
end
end
if mn and mx then
span=(mx-mn).Magnitude
end
end
if span<=0 then
WindUI:Notify({Title="适配",Content="算不出船的大小",Duration=4})
return
end
local z2=40/span
if z2>1 then z2=1 end
if z2<0.05 then z2=0.05 end
getgenv().BabyZoom=z2
WindUI:Notify({Title="适配完成",Content=string.format("船跨度 %.0f 格，已缩放到 %.0f%%",span,z2*100),Duration=8})
rebuild(txt,1)
end})
getgenv().BabyFitOld=getgenv().BabyFitOld or false
T2:Toggle({Title="旧文件自动归一化（默认关）",Value=false,Callback=function(v)
getgenv().BabyFitOld=v
end})
getgenv().BabyUseFix=getgenv().BabyUseFix or false
T2:Toggle({Title="改用固定坐标摆（默认关闭）",Value=false,Callback=function(v)
getgenv().BabyUseFix=v
end})
getgenv().BabyAutoTp=getgenv().BabyAutoTp or false
T2:Toggle({Title="加载后自动传送到预览旁",Value=false,Callback=function(v)
getgenv().BabyAutoTp=v
end})
T2:Button({Title="★ 自检（先点这个）",Callback=function()
selftest()
end})
T2:Button({Title="统计船上方块类型（普通/功能）",Callback=function()
if target==""then
WindUI:Notify({Title="统计",Content="先选择目标玩家",Duration=4})
return
end
local pl=P:FindFirstChild(target)
if not pl then
WindUI:Notify({Title="统计",Content="玩家不在了",Duration=4})
return
end
local z=boatContainerOf(pl)
if not z then
WindUI:Notify({Title="统计",Content="找不到该玩家的方块文件夹",Duration=4})
return
end
local parts=collectParts(z)
if #parts==0 then
WindUI:Notify({Title="统计",Content="没有方块",Duration=4})
return
end
local byName={}
local byCls={}
local bySize={}
for _,v in ipairs(parts)do
byName[v.Name]=(byName[v.Name]or 0)+1
byCls[v.ClassName]=(byCls[v.ClassName]or 0)+1
local k=string.format("%.1fx%.1fx%.1f",v.Size.X,v.Size.Y,v.Size.Z)
bySize[k]=(bySize[k]or 0)+1
end
local function dump(t,title,lim)
local ks={}
for k,v in pairs(t)do ks[#ks+1]={k,v} end
table.sort(ks,function(a,b)return a[2]>b[2] end)
local out={title}
for i=1,math.min(#ks,lim or 12)do
out[#out+1]=ks[i][1].." ×"..ks[i][2]
end
if #ks>(lim or 12)then out[#out+1]="...共"..#ks.."种" end
return table.concat(out,"\n")
end
local txt=dump(byCls,"【按类型】",8).."\n\n"..dump(byName,"【按名字】",12).."\n\n"..dump(bySize,"【按尺寸】",8)
pcall(function()setclipboard(txt)end)
WindUI:Notify({Title="方块类型 共"..#parts.."块",Content=txt:sub(1,240),Duration=16})
end})
T2:Button({Title="★★ 摆5个不同尺寸的测试块（先点这个）",Callback=function()
local cam=gs.CurrentCamera
local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
local base
if cam then
base=cam.CFrame.Position+cam.CFrame.LookVector*14
elseif hrp then
base=hrp.Position+Vector3.new(0,6,-14)
else
base=Vector3.new(0,20,0)
end
local old2=gs:FindFirstChild("BabySizeTest")
if old2 then pcall(function()old2:Destroy()end)end
local f=Instance.new("Folder")
f.Name="BabySizeTest"
f.Parent=gs
local specs={
{4,0.3,2,Color3.fromRGB(255,80,80),"4x0.3x2"},
{6,0.3,2,Color3.fromRGB(80,255,80),"6x0.3x2"},
{4,0.5,24,Color3.fromRGB(80,80,255),"4x0.5x24"},
{1.5,0.1,6,Color3.fromRGB(255,255,0),"1.5x0.1x6"},
{2.5,0.1,4,Color3.fromRGB(255,0,255),"2.5x0.1x4"},
}
local out={}
for i,sp in ipairs(specs)do
local okp,errp=pcall(function()
local q=Instance.new("Part")
q.Name="SizeTest"..i
q.Size=Vector3.new(sp[1],sp[2],sp[3])
q.Anchored=true
q.CanCollide=false
q.CanQuery=false
q.CanTouch=false
q.Material=Enum.Material.Neon
q.Color=sp[4]
q.CFrame=CFrame.new(base+Vector3.new((i-3)*7,(i-1)*4,0))*CFrame.Angles(0,0,math.rad(25))
q.Parent=f
end)
if okp then
out[#out+1]=i..") 设="..sp[5].." 实="..string.format("%.2f,%.2f,%.2f",f:FindFirstChild("SizeTest"..i).Size.X,f:FindFirstChild("SizeTest"..i).Size.Y,f:FindFirstChild("SizeTest"..i).Size.Z)
else
out[#out+1]=i..") 失败 "..tostring(errp)
end
end
local txt=table.concat(out,"\n")
pcall(function()setclipboard(txt)end)
WindUI:Notify({Title="尺寸测试",Content=txt,Duration=14})
WindUI:Notify({Title="看前方",Content="应该是 5 个形状明显不同的块",Duration=10})
end})
T2:Button({Title="查看选中文件里的前3块数据",Callback=function()
local name=selFile
if not name or name=="（没有文件）"then
WindUI:Notify({Title="数据",Content="先选一个文件",Duration=4})
return
end
local ok,txt=pcall(function()return readfile("BoatCopy/"..name)end)
if not ok or not txt then
WindUI:Notify({Title="数据",Content="读不到文件",Duration=4})
return
end
local ok2,d=pcall(function()return HS:JSONDecode(txt)end)
if not ok2 or not d.blocks then
WindUI:Notify({Title="数据",Content="解析失败",Duration=4})
return
end
local lines={}
lines[1]="文件="..name
lines[2]="块数="..#d.blocks.."  版本="..tostring(d.v)
if d.box and d.box.min then
lines[3]=string.format("包围盒 min %.1f,%.1f,%.1f max %.1f,%.1f,%.1f",d.box.min[1],d.box.min[2],d.box.min[3],d.box.max[1],d.box.max[2],d.box.max[3])
end
local i=#lines+1
for j=1,math.min(3,#d.blocks)do
local b=d.blocks[j]
local sz=b.S and string.format("%.2f,%.2f,%.2f",b.S[1],b.S[2],b.S[3])or"无"
local ps=b.P and string.format("%.1f,%.1f,%.1f",b.P[1],b.P[2],b.P[3])or"无"
lines[i]=j..") 尺寸="..sz.." 位置="..ps
i=i+1
end
local t2=table.concat(lines,"\n")
pcall(function()setclipboard(t2)end)
WindUI:Notify({Title="文件数据",Content=t2:sub(1,240),Duration=14})
end})
T2:Button({Title="检查预览里到底有什么",Callback=function()
local f=gs:FindFirstChild("BabyBoatPreview")
if not f then
WindUI:Notify({Title="检查",Content="还没有预览，先点加载",Duration=5})
return
end
local ps={}
for _,v in ipairs(f:GetChildren())do
if v:IsA("BasePart")then ps[#ps+1]=v end
end
if #ps==0 then
WindUI:Notify({Title="检查",Content="预览文件夹是空的",Duration=5})
return
end
local lines={}
lines[1]="方块总数="..#ps
local sizes={}
local minV,maxV=ps[1].Position,ps[1].Position
for _,v in ipairs(ps)do
local k=string.format("%.2f,%.2f,%.2f",v.Size.X,v.Size.Y,v.Size.Z)
sizes[k]=(sizes[k]or 0)+1
local q=v.Position
if q.X<minV.X then minV=Vector3.new(q.X,minV.Y,minV.Z)end
if q.Y<minV.Y then minV=Vector3.new(minV.X,q.Y,minV.Z)end
if q.Z<minV.Z then minV=Vector3.new(minV.X,minV.Y,q.Z)end
if q.X>maxV.X then maxV=Vector3.new(q.X,maxV.Y,maxV.Z)end
if q.Y>maxV.Y then maxV=Vector3.new(maxV.X,q.Y,maxV.Z)end
if q.Z>maxV.Z then maxV=Vector3.new(maxV.X,maxV.Y,q.Z)end
end
lines[2]="不同尺寸种类="..#(function()local n=0 for _ in pairs(sizes)do n=n+1 end return {n}end)()
lines[3]=string.format("位置范围 X %.1f~%.1f  Y %.1f~%.1f  Z %.1f~%.1f",minV.X,maxV.X,minV.Y,maxV.Y,minV.Z,maxV.Z)
lines[4]=string.format("跨度 %.1f x %.1f x %.1f",maxV.X-minV.X,maxV.Y-minV.Y,maxV.Z-minV.Z)
lines[5]="--- 尺寸分布（前5种）---"
local i=6
for k,v in pairs(sizes)do
if i>10 then break end
lines[i]=k.." ×"..v
i=i+1
end
lines[i]="--- 前5块坐标 ---"
i=i+1
for j=1,math.min(5,#ps)do
local v=ps[j]
lines[i]=string.format("%d) %.1f,%.1f,%.1f",j,v.Position.X,v.Position.Y,v.Position.Z)
i=i+1
end
local txt=table.concat(lines,"\n")
pcall(function()setclipboard(txt)end)
WindUI:Notify({Title="预览检查",Content=txt:sub(1,240),Duration=14})
end})
T2:Button({Title="一键测试：导出我的船并立刻重建",Callback=function()
local z=boatContainerOf(LP)
if not z then
WindUI:Notify({Title="测试",Content="Blocks 里没有你的文件夹",Duration=5})
return
end
local list,n,_,box=buildBlocks(z)
if not list or n==0 then
WindUI:Notify({Title="测试",Content="你的船里没有方块，先造几块",Duration=5})
return
end
local data={v=2,src=LP.Name,count=#list,box=box,blocks=list}
local ok,enc=pcall(function()return HS:JSONEncode(data)end)
if not ok then
WindUI:Notify({Title="测试",Content="编码失败",Duration=4})
return
end
lastExport=enc
WindUI:Notify({Title="测试",Content="你自己的船共 "..n.." 块，开始重建",Duration=5})
rebuild(enc,1)
end})
T2:Button({Title="传送到预览位置",Callback=function()
local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
if not hrp then
WindUI:Notify({Title="传送",Content="角色不存在",Duration=4})
return
end
local x,y,z=getgenv().BabyFixX or 0,getgenv().BabyFixY or 20,getgenv().BabyFixZ or 0
pcall(function()hrp.CFrame=CFrame.new(x+30,y+15,z+30)end)
WindUI:Notify({Title="传送",Content=string.format("已到 %.0f, %.0f, %.0f 旁边",x,y,z),Duration=5})
end})
T2:Button({Title="把当前脚下坐标设为固定点",Callback=function()
local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
if not hrp then return end
local p2=hrp.Position
getgenv().BabyFixX=math.floor(p2.X)
getgenv().BabyFixY=math.floor(p2.Y)+6
getgenv().BabyFixZ=math.floor(p2.Z)
WindUI:Notify({Title="固定点",Content=string.format("已设为 %.0f, %.0f, %.0f（重开窗口可看到数值）",getgenv().BabyFixX,getgenv().BabyFixY,getgenv().BabyFixZ),Duration=8})
end})
T2:Button({Title="跳到我那堆方块旁边",Callback=function()
local z=boatContainerOf(LP)
local parts=collectParts(z)
if #parts==0 then
WindUI:Notify({Title="定位",Content="你还没有放方块",Duration=4})
return
end
local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
if hrp then
pcall(function()hrp.CFrame=parts[1].Position+Vector3.new(0,6,12)end)
WindUI:Notify({Title="定位",Content="已传送到你的第一块方块附近",Duration=4})
else
WindUI:Notify({Title="定位",Content="角色不存在",Duration=4})
end
end})
T2:Button({Title="统计我的船（有多少块/在哪）",Callback=function()
local z=boatContainerOf(LP)
local parts=collectParts(z)
if #parts==0 then
WindUI:Notify({Title="统计",Content="Blocks 里没有你的方块",Duration=5})
return
end
local p1=parts[1].Position
local lines={}
lines[1]="你的船共 "..#parts.." 块"
lines[2]=string.format("第一块位置 %.1f, %.1f, %.1f",p1.X,p1.Y,p1.Z)
local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
if hrp then
lines[3]=string.format("你当前位置 %.1f, %.1f, %.1f",hrp.Position.X,hrp.Position.Y,hrp.Position.Z)
lines[4]=string.format("相距 %.1f 格",(hrp.Position-p1).Magnitude)
end
local txt=table.concat(lines,"\n")
pcall(function()setclipboard(txt)end)
WindUI:Notify({Title="统计",Content=txt,Duration=12})
end})
T2:Button({Title="导出我的船（做对照测试）",Callback=function()
local z=boatContainerOf(LP)
local list,n=buildBlocks(z)
if not list or n==0 then
WindUI:Notify({Title="对照",Content="你还没有放方块",Duration=4})
return
end
local data={v=2,src=LP.Name,count=#list,blocks=list}
pcall(function()lastExport=HS:JSONEncode(data)end)
rebuild(lastExport,1)
end})

T2:Section({Title="说明"})
T2:Button({Title="这个功能能做什么",Callback=function()
WindUI:Notify({Title="说明",Content="扫描别人船上的方块，存成 .build 文件，再在你面前还原出来看。还原的方块只在你本机显示，别人看不到，也不会进游戏存档。",Duration=10})
end})

end

local function buildLockUI()
T2:Section({Title="复制功能需要卡密（未解锁）"})
local lk=""
T2:Input({Title="卡密",Placeholder="输入后点下面的按钮",Value="",Callback=function(t)lk=t end})
T2:Button({Title="验证并解锁",Callback=function()
unlockWith(lk)
end})
T2:Button({Title="我已经在刷钱页输入过了",Callback=function()
WindUI:Notify({Title="提示",Content="在「刷钱」页点验证后会自动解锁本页",Duration=6})
end})
end

if unlocked then buildCopyOnce() else buildLockUI() end
