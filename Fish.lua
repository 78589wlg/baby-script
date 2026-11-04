local WindUI=loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua"))()
local P=game:GetService("Players")
local LP=P.LocalPlayer
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local RunS=game:GetService("RunService")
local function getEv(n)
local ev=RS:FindFirstChild("Events")
local e=ev and ev:FindFirstChild(n)
if not e then
local e2=RS:FindFirstChild(n)
if e2 and (e2:IsA("RemoteEvent")or e2:IsA("RemoteFunction"))then e=e2 end
end
return e
end
local function fEv(n,a,b)
local e=getEv(n)
if not e then return false end
if e:IsA("RemoteFunction")then
pcall(function()e:InvokeServer(a,b)end)
else
pcall(function()e:FireServer(a,b)end)
end
return true
end
local Win=WindUI:CreateWindow({Title="重型钓鱼"})
local T1=Win:Tab({Title="钓鱼",Icon="fish"})
local skillOn={Z=true,X=true,C=true,V=true}
T1:Section({Title="自动钓鱼"})
local auto=false
local lockBar=false
T1:Toggle({Title="锁定绿条",Value=false,Callback=function(v)lockBar=v end})
T1:Toggle({Title="自动钓鱼",Value=false,Callback=function(s)
auto=s
if s then
task.spawn(function()
while auto do
pcall(function()
local c=LP.Character
local fg=LP:FindFirstChild("PlayerGui")
local mg=fg and fg:FindFirstChild("MainGui")
local fish=mg and mg:FindFirstChild("Fishing")
local busy=c and c:GetAttribute("Fishing")
if fish and fish.Visible then
if lockBar then
local bf=fish:FindFirstChild("BarFrame")
local b=bf and bf:FindFirstChild("Bar")
if b then
b.Position=UDim2.new(0.5,0,b.Position.Y.Scale,0)
end
end
fEv("UpdateFishProgression")
elseif not busy and c then
local t=c:GetAttribute("Type")
if t~="Fishing Rod" then
fEv("ToggleHotbar","1")
else
fEv("Fishing",c:FindFirstChild("HumanoidRootPart")and c.HumanoidRootPart.CFrame)
end
end
end)
task.wait(0.05)
end
end)
WindUI:Notify({Title="钓鱼",Content="已开启",Duration=2})
else
WindUI:Notify({Title="钓鱼",Content="已停止",Duration=2})
end
end})
local BAITS={"Ancestral Bait","Elite Bait","Corrupted Essence Bait","Crude Mash Bait","Basic Bait"}
local baitName=BAITS[1]
local baitAmt=5
local baitMin=10
local buyBait=false
local function baitFolder()
local d=RS:FindFirstChild("Data")
local pd=d and d:FindFirstChild(tostring(LP.UserId))
return pd and pd:FindFirstChild("Bait")or nil
end
local function baitCount(n)
local f=baitFolder()
local it=f and f:FindFirstChild(n)
if it and it:IsA("ValueBase")then return tonumber(it.Value)or 0 end
if it and it:IsA("Folder")then
local v=it:FindFirstChild("Amount")or it:FindFirstChild("Count")or it:FindFirstChild("Value")
if v then return tonumber(v.Value)or 0 end
end
return 0
end
local function buyBaitNow(n,k)
local e=getEv("BuyBait")
if not e then return false end
if e:IsA("RemoteFunction")then
pcall(function()e:InvokeServer(n,k)end)
else
pcall(function()e:FireServer(n,k)end)
end
return true
end
T1:Section({Title="自动购买饵料"})
T1:Dropdown({Title="饵料种类",Values=BAITS,Value="Ancestral Bait",Callback=function(v)baitName=v end})
T1:Slider({Title="每次购买数量",Value={Min=1,Max=50,Default=5},Callback=function(v)baitAmt=math.floor(v)end})
T1:Slider({Title="低于多少自动买",Value={Min=1,Max=50,Default=10},Callback=function(v)baitMin=math.floor(v)end})
T1:Toggle({Title="自动购买饵料",Value=false,Callback=function(s)
buyBait=s
if s then
task.spawn(function()
while buyBait do
pcall(function()
local c=baitCount(baitName)
if c<baitMin then
buyBaitNow(baitName,baitAmt)
end
end)
task.wait(1)
end
end)
WindUI:Notify({Title="饵料",Content="低于 "..baitMin.." 自动买 "..baitAmt.." 个",Duration=3})
else
WindUI:Notify({Title="饵料",Content="已停止",Duration=2})
end
end})
T1:Button({Title="立即购买一次",Callback=function()
local ok=buyBaitNow(baitName,baitAmt)
if ok then
WindUI:Notify({Title="饵料",Content="已购买 "..baitName.." x"..baitAmt,Duration=3})
else
WindUI:Notify({Title="饵料",Content="未找到 BuyBait 事件，可能不在游戏中",Duration=3})
end
end})
T1:Button({Title="查看饵料库存",Callback=function()
local f=baitFolder()
if not f then
WindUI:Notify({Title="饵料",Content="读不到背包数据",Duration=3})
return
end
local out={}
for _,n in ipairs(BAITS)do
out[#out+1]=n..":"..baitCount(n)
end
WindUI:Notify({Title="饵料库存",Content=table.concat(out,"  "),Duration=6})
end})
local function slotOk(k)
local c=LP.Character
local sf=c and c:FindFirstChild("Skills")
if not sf then return true end
local cnt=0
for _,v in pairs(sf:GetChildren())do
if v:IsA("NumberValue")then
cnt=cnt+1
local kk=v:GetAttribute("Key")or v.Name
if tostring(kk)==k then
if(v:GetAttribute("UsingSkill")or 0)>0 then return false end
if v.Value>0 then return false end
return true
end
end
end
if cnt>0 then return false end
return true
end
local order={"Z","X","C","V"}
local function skillLoop()
local idx=1
local last=0
local pk=nil
while skill do
pcall(function()
local c=LP.Character
local fg=LP:FindFirstChild("PlayerGui")
local mg=fg and fg:FindFirstChild("MainGui")
local fish=mg and mg:FindFirstChild("Fishing")
if not fish or not fish.Visible then idx=1 return end
if c then
if c:GetAttribute("SkillLocked")or c:GetAttribute("Confused")or c:GetAttribute("Phase2")then return end
local st=c:FindFirstChild("Stats")
local stun=st and st:FindFirstChild("Stun")
if stun and stun.Value==true then return end
local rods=RS:FindFirstChild("Data")
local pd=rods and rods:FindFirstChild(tostring(LP.UserId))
if pd then
local rv=pd:FindFirstChild("FishingRod")
local ri=pd:FindFirstChild("FishingRodInventory")
local rf=(rv and rv.Value~=""and ri)and ri:FindFirstChild(rv.Value)or nil
local sk=rf and rf:FindFirstChild("Skill")
if sk then
for _,k in ipairs(order)do
local sv=sk:FindFirstChild(k)
if sv and sv:IsA("StringValue")and sv.Value==""then return end
end
end
end
end
if os.clock()-last<0.3 then return end
local pick=nil
for step=1,#order do
local i=((idx-1+(step-1))%#order)+1
local k=order[i]
if skillOn[k]and slotOk(k)then
pick=i
break
end
end
if not pick then return end
idx=pick
local key=order[idx]
last=os.clock()
pk=key
fEv("UseSkill",key)
idx=(idx%#order)+1
end)
task.wait(0.1)
end
end
T1:Toggle({Title="自动技能",Value=false,Callback=function(s)
skill=s
if s then
task.spawn(skillLoop)
WindUI:Notify({Title="技能",Content="已开启",Duration=2})
else
WindUI:Notify({Title="技能",Content="已停止",Duration=2})
end
end})
T1:Section({Title="技能键选择"})
T1:Toggle({Title="Z 键",Value=true,Callback=function(v)skillOn.Z=v end})
T1:Toggle({Title="X 键",Value=true,Callback=function(v)skillOn.X=v end})
T1:Toggle({Title="C 键",Value=true,Callback=function(v)skillOn.C=v end})
T1:Toggle({Title="V 键",Value=true,Callback=function(v)skillOn.V=v end})
T1:Section({Title="自动卖鱼"})
local sell=false
T1:Toggle({Title="自动卖鱼",Value=false,Callback=function(s)
sell=s
if s then
task.spawn(function()
while sell do
fEv("SellFish","All")
task.wait(5)
end
end)
WindUI:Notify({Title="卖鱼",Content="已开启",Duration=2})
else
WindUI:Notify({Title="卖鱼",Content="已停止",Duration=2})
end
end})
T1:Section({Title="兑换码"})
T1:Button({Title="领取所有兑换码",Callback=function()
local n=0
task.spawn(function()
local set={}
pcall(function()
local info=RS:FindFirstChild("Info")
local data=RS:FindFirstChild("Data")
local pd=data and data:FindFirstChild(tostring(LP.UserId))
local containers={info and info:FindFirstChild("Code"),info and info:FindFirstChild("Codes"),pd and pd:FindFirstChild("Code"),pd and pd:FindFirstChild("Codes")}
for _,c in pairs(containers)do
if c then
if c:IsA("ModuleScript")then
local ok,d=pcall(require,c)
if ok and type(d)=="table"then
for k,v in pairs(d)do
if type(k)=="string"and#k>2 then set[k]=true end
if type(v)=="string"and#v>2 then set[v]=true end
end
end
end
for _,ch in pairs(c:GetChildren())do
if #ch.Name>2 then set[ch.Name]=true end
if ch:IsA("StringValue")and#ch.Value>2 then set[ch.Value]=true end
end
end
end
end)
local total=0
for _ in pairs(set)do total=total+1 end
if total==0 then
WindUI:Notify({Title="兑换码",Content="游戏里没找到码表",Duration=3})
return
end
for code in pairs(set)do
fEv("RedeemCode",code)
n=n+1
task.wait(0.2)
end
WindUI:Notify({Title="兑换码",Content="已提交 "..n.." 个码",Duration=3})
end)
end})
T1:Section({Title="传送"})
for i=1,9 do
T1:Button({Title="岛 "..i,Callback=function()
pcall(function()
local m=workspace:FindFirstChild("Map")
local isl=m and m:FindFirstChild("Map "..i)
local p=isl and isl:FindFirstChildWhichIsA("BasePart",true)
local c=LP.Character
local r=c and c:FindFirstChild("HumanoidRootPart")
if p and r then r.CFrame=p.CFrame+Vector3.new(0,5,0)end
end)
WindUI:Notify({Title="传送",Content="岛 "..i,Duration=1})
end})
end
