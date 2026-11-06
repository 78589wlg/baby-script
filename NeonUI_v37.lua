local WindUI=loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua"))()
local P=game:GetService("Players")
local LP=P.LocalPlayer
local sp,jp=16,50
local Win=WindUI:CreateWindow({Title="婴儿脚本"})
local ok=false
local T2,T3,T4,T5
local G="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/"
local PM={[537413528]=G.."Boat_v37.lua",[98502499119821]=G.."Fish_v2.lua",[90148635862803]=G.."Deadly.lua",[107778070777162]=G.."Egg.lua",[79546208627805]=G.."N99.lua",[10165583746]=G.."Examination_zh.lua"}
local function subAuto()
local u=PM[game.PlaceId]
if not u then return end
pcall(function()loadstring(game:HttpGet(u))()end)
end
local th={"Dark","Light","Rose","Plant","Red","Indigo","Sky","Violet","Amber","Emerald","Midnight","Crimson","MonokaiPro","CottonCandy","Mellowsi","Rainbow"}
local function hum()
local c=LP.Character
if c then return c:FindFirstChildOfClass("Humanoid")end
end
-- 永久卡密（无限期，可无限次使用）
local PERM={"少羽没面","卡密制作婴儿脚本6767"}
local KEY=PERM[1]
local auto=true
local done=false
local AM={[537413528]=1,[98502499119821]=1,[90148635862803]=1,[107778070777162]=1,[79546208627805]=1,[10165583746]=1}

-- ===== 卡密（支持 7 天动态卡 + 老卡密） =====
local HSK=game:GetService("HttpService")
local KR="https://raw.githubusercontent.com/78589wlg/baby-script/main/"
local KAPI=""
local kapiLoaded=false
local function ktrim(x)return (tostring(x):gsub("^%s+",""):gsub("%s+$",""))end
local function isPerm(k)
local t=ktrim(k)
for _,v in ipairs(PERM)do
if t==v then return true end
end
return false
end
local function ktoday()local o,d=pcall(function()return os.date("%Y-%m-%d")end)return o and d or "1970-01-01"end
local function kgetAPI()
if kapiLoaded then return KAPI end
kapiLoaded=true
local okk,txt=pcall(function()return game:HttpGet(KR.."api.txt?t="..tostring(os.time()))end)
if okk and type(txt)=="string" then
for line in txt:gmatch("[^\r\n]+")do
local t=ktrim(line)
if t~="" and t:sub(1,1)~="#" and t:find("^https?://")then
KAPI=(t:gsub("/+$",""))
break
end
end
end
return KAPI
end
local function kexpok(e)
if not e or e=="" then return true,"永久" end
local d=tostring(e):gsub("[^%d]","")
if #d==8 then d=d:sub(1,4).."-"..d:sub(5,6).."-"..d:sub(7,8)end
if d<ktoday() then return false,d end
return true,d
end
local function keyCheck(k)
k=ktrim(k)
if k=="" then return false,"请输入卡密",nil end
if isPerm(k) then return true,"永久卡密（无限期）",nil end
local okk,txt=pcall(function()return game:HttpGet(KR.."keys.txt?t="..tostring(os.time()))end)
if okk and type(txt)=="string" then
for line in txt:gmatch("[^\r\n]+")do
local ln=ktrim(line)
if ln~="" and ln:sub(1,1)~="#" then
local kk,ee=ln:match("^([^,]+),?(.*)$")
if kk and ktrim(kk)==k then
local o2,e2=kexpok(ktrim(ee))
if not o2 then return false,"卡密已于 "..e2.." 过期",nil end
if e2=="永久"then return true,"验证通过（永久）","永久"end
return true,"验证通过（有效期至 "..e2.."）",e2
end
end
end
end
local base=kgetAPI()
if base=="" then return false,"卡密无效",nil end
local ok2,res=pcall(function()return game:HttpGet(base.."/verify?key="..k)end)
if not ok2 or type(res)~="string" or #res<3 then return false,"接口连接失败，请检查网络",nil end
local okd,d=pcall(function()return HSK:JSONDecode(res)end)
if not okd or type(d)~="table" then return false,"接口返回异常",nil end
if not d.ok then return false,tostring(d.msg or "卡密无效"),nil end
local exp=tostring(d.exp or "")
if exp=="" then return true,"验证通过",nil end
return true,"验证通过（有效期至 "..exp.."）",exp
end
local function saveShared(k,exp)
pcall(function()
if writefile then writefile("BabyKey.txt",ktrim(k).."|"..tostring(exp or ""))end
end)
end
-- 读取上次保存的卡密，免重复输入
local savedK,savedE="",""
pcall(function()
local f=readfile("BabyKey.txt")
if type(f)=="string" then
local a,b=f:match("^([^|]*)|([^|\r\n]*)")
if a then savedK=ktrim(a) savedE=ktrim(b or "") end
end
end)
if savedK~="" then
if isPerm(savedK) then ok=true
elseif savedE=="永久" then ok=true
elseif savedE~="" then
local okk=kexpok(savedE)
if okk then ok=true end
end
end
if getgenv().babyKey and isPerm(getgenv().babyKey)then ok=true end
local function doUnlock(silent)
if done then return end
done=true
for _,x in ipairs({T2,T3,T4,T5})do
if x then pcall(function()x.Locked=false x:UnlockAll()end)end
end
getgenv().babyKey=KEY
if silent then
WindUI:Notify({Title="婴儿脚本",Content="上次的卡密仍然有效，已自动登录",Duration=4})
else
WindUI:Notify({Title="婴儿脚本",Content="欢迎你使用婴儿脚本",Duration=3})
task.wait(1.2)
WindUI:Notify({Title="婴儿脚本",Content="祝你玩的开心",Duration=3})
task.wait(1.2)
end
if auto and AM[game.PlaceId]then
WindUI:Notify({Title="自动加载",Content="正在加载副脚本",Duration=3})
task.wait(1)
subAuto()
end
end

local T1=Win:Tab({Title="卡密验证",Icon="key"})
T1:Section({Title="请输入卡密（有效期 7 天 / 永久卡无限用）"})
local keyTxt=ok and savedK or ""
T1:Input({Title="卡密",Placeholder="BOAT-XXXX-XXXX",Value=keyTxt,Callback=function(t)
keyTxt=t
if isPerm(t) then ok=true end
end})
T1:Button({Title="验证卡密",Callback=function()
if done then return end
local k2=ktrim(keyTxt)
if k2=="" then WindUI:Notify({Title="失败",Content="请输入卡密",Duration=3})return end
WindUI:Notify({Title="验证中",Content="正在校验卡密…",Duration=2})
local kok,kmsg,kexp=keyCheck(k2)
if not kok then WindUI:Notify({Title="失败",Content=kmsg,Duration=5})return end
ok=true
saveShared(k2,kexp or "永久")
WindUI:Notify({Title="验证通过",Content=kmsg,Duration=4})
doUnlock(false)
end})
T1:Button({Title="忘记卡密？一键找回",Callback=function()
local k=PERM[1]
pcall(function()if setclipboard then setclipboard(k)end end)
if done then
WindUI:Notify({Title="找回卡密",Content="已解锁中｜永久卡密："..k.."（已复制）",Duration=8})
return
end
WindUI:Notify({Title="找回卡密",Content="永久卡密："..k.."（已自动登录并复制）",Duration=8})
keyTxt=k
saveShared(k,"永久")
ok=true
doUnlock(false)
end})
T1:Button({Title="清除已保存的卡密",Callback=function()
pcall(function()if delfile then delfile("BabyKey.txt")end end)
WindUI:Notify({Title="卡密",Content="已清除，下次启动需重新输入",Duration=5})
end})
T1:Section({Title="界面配色"})
for i=1,#th do
local n=th[i]
T1:Button({Title=n,Callback=function()
pcall(function()WindUI:SetTheme(n)end)
WindUI:Notify({Title="主题",Content=n,Duration=1})
end})
end
T2=Win:Tab({Title="玩家增强",Icon="user",Locked=true})
T2:Section({Title="移动设置"})
T2:Slider({Title="移动速度",Value={Min=16,Max=500,Default=16},Callback=function(v)
sp=v
local h=hum()
if h then h.WalkSpeed=sp end
end})
T2:Slider({Title="跳跃力",Value={Min=50,Max=500,Default=50},Callback=function(v)
jp=v
local h=hum()
if h then h.UseJumpPower=true h.JumpPower=jp end
end})
T2:Section({Title="穿墙设置"})
local pc={}
T2:Toggle({Title="穿墙",Value=false,Callback=function(s)
local c=LP.Character
if not c then return end
for _,v in pairs(c:GetDescendants())do
if v:IsA("BasePart")then
if s then
if v.CanCollide==true then pc[v]=true end
v.CanCollide=false
else
if pc[v] then v.CanCollide=true end
end
end
end
if not s then pc={} end
WindUI:Notify({Title="穿墙",Content=s and "已开启" or "已关闭",Duration=1})
end})
T2:Toggle({Title="透视",Value=false,Callback=function(s)
if s then
local cg=game:GetService("CoreGui")
for _,v in pairs(P:GetPlayers())do
if v~=LP and v.Character then
local h=Instance.new("Highlight")
h.FillColor=Color3.fromRGB(255,0,0)
h.FillTransparency=0.5
h.OutlineColor=Color3.fromRGB(255,0,0)
h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
h.Adornee=v.Character
h.Parent=cg
end
end
else
for _,h in pairs(game:GetService("CoreGui"):GetChildren())do
if h:IsA("Highlight")then pcall(function()h:Destroy()end)end
end
end
WindUI:Notify({Title="透视",Content=s and "已开启" or "已关闭",Duration=1})
end})
T3=Win:Tab({Title="其他脚本",Icon="package",Locked=true})
T3:Section({Title="脚本列表"})
T3:Button({Title="皮脚本",Callback=function()
getgenv().XiaoPi="皮脚本QQ1002100032"
pcall(function()loadstring(game:HttpGet("https://raw.githubusercontent.com/xiaopi77/xiaopi77/main/QQ1002100032-Roblox-Pi-script.lua"))()end)
end})
T4=Win:Tab({Title="更多",Locked=true})
T4:Section({Title="工具"})
T4:Button({Title="重生",Callback=function()
local h=hum()
if h then h.Health=0 end
end})
T4:Toggle({Title="友好玩家变绿",Value=false,Callback=function(v)
if v then
pcall(function()loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/EspUser.lua"))()end)
else
pcall(function()getgenv().BabyClear()end)
end
end})
T4:Toggle({Title="头顶名字标签",Value=false,Callback=function(v)
if v then
pcall(function()loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/TagUser.lua"))()end)
getgenv().BabyTagOn=true
WindUI:Notify({Title="头顶名字标签",Content="只给名单里的人显示",Duration=3})
else
getgenv().BabyTagOn=false
if getgenv().BabyTagClean then
pcall(getgenv().BabyTagClean)
else
for _,o in ipairs(game.Players:GetPlayers())do
local c=o.Character
local hd=c and c:FindFirstChild("Head")
local b=hd and hd:FindFirstChild("BabyNameTag")
if b then pcall(function()b:Destroy()end)end
end
end
end
end})
T4:Toggle({Title="脚本用户检测",Value=false,Callback=function(v)
if v then
WindUI:Notify({Title="脚本用户检测",Content="开发中，暂未开放",Duration=3})
else
getgenv().BabyDetect=false
end
end})
T4:Input({Title="本局临时名单",Placeholder="@后面的英文名，逗号分隔",Value="",Callback=function(t)
getgenv().BabyExtra2=t
pcall(function()if getgenv().BabyRescan then getgenv().BabyRescan()end end)
end})
T4:Button({Title="查看当前名单",Callback=function()
local L={}
pcall(function()if getgenv().BabyList then L=getgenv().BabyList()end end)
if #L==0 then
WindUI:Notify({Title="当前名单",Content="暂无名字",Duration=3})
else
WindUI:Notify({Title="当前名单",Content=table.concat(L,"，"),Duration=5})
end
end})
T4:Button({Title="复制QQ号",Callback=function()
pcall(function()setclipboard("3492202561")end)
WindUI:Notify({Title="QQ号",Content="3492202561 已复制",Duration=2})
end})
T5=Win:Tab({Title="脚本库",Icon="list",Locked=true})
T5:Section({Title="其他脚本"})
local sel="造船寻宝"
local LU={["造船寻宝"]="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/Boat_v37.lua",["重型钓鱼"]="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/Fish_v2.lua",["在末日中生存下来"]="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/Deadly.lua",["偷一个蛋"]="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/Egg.lua",["森林中的99夜"]="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/N99.lua",["试炼"]="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/Examination_zh.lua"}
T5:Dropdown({Title="选择脚本",Values={"造船寻宝","重型钓鱼","在末日中生存下来","偷一个蛋","森林中的99夜","试炼"},Value="造船寻宝",Callback=function(v)
sel=v
end})
T5:Button({Title="使用",Callback=function()
local u=LU[sel]
if not u then WindUI:Notify({Title="脚本库",Content="未知脚本",Duration=2})return end
WindUI:Notify({Title="脚本库",Content="正在执行 "..sel,Duration=2})
pcall(function()loadstring(game:HttpGet(u))()end)
end})
T5:Toggle({Title="进入游戏自动加载副脚本",Value=true,Callback=function(v)auto=v end})
local function runAuto()
if not ok or not auto then return end
if not AM[game.PlaceId]then return end
subAuto()
end
if ok then task.spawn(runAuto) end
LP.CharacterAdded:Connect(function(c)
local h=c:WaitForChild("Humanoid",10)
if h then
task.wait(0.5)
h.WalkSpeed=sp
h.UseJumpPower=true
h.JumpPower=jp
end
end)
T2:LockAll()
T3:LockAll()
T4:LockAll()
T5:LockAll()

if ok then task.defer(doUnlock,true)end
