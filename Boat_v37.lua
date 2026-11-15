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
-- ===== 复制别人的船（独立页签，排在刷钱页下面） =====
local T2=Win:Tab({Title="复制船",Icon="copy"})

local copyBuilt=false
buildCopyOnce=function()
if copyBuilt then return end
copyBuilt=true
buildCopyUI()
end

buildCopyUI=function()
-- 复制/导出/建造整套功能已换成网上现成源码（Voltra Build System，明文，自带存档、加载、图像与地形生成）
getgenv().BabyVoltraHostTab=T2  -- Voltra 界面嵌入「复制船」页
local urls={
"https://raw.githubusercontent.com/78589wlg/baby-script/main/BoatCopyMain.lua?v=7",
"https://raw.githubusercontent.com/78589wlg/baby-script/main/BoatCopyMain.lua"
}
local done=false
WindUI:Notify({Title="复制船",Content="正在加载功能，稍等几秒，界面会陆续出现",Duration=8})
for _,u in ipairs(urls)do
local okd,src=pcall(function()return game:HttpGet(u)end)
if okd and src and #src>10000 then
task.wait()
local okl,err=pcall(function()loadstring(src)()end)
if okl then
done=true
WindUI:Notify({Title="复制船",Content="网上源码已加载（Voltra 汉化版）",Duration=6})
break
else
WindUI:Notify({Title="复制船",Content="源码执行出错："..tostring(err):sub(1,120),Duration=10})
end
end
end
if not done then
WindUI:Notify({Title="复制船",Content="网上源码拉取失败，稍后点「重新加载网上源码」再试",Duration=10})
end
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

-- ===== 多工具：所有工具一起拿（原版一次只能拿一个） =====
local MT=LP:WaitForChild("Backpack")
local multiOn=false
local function equipAllTools()
local ch=LP.Character
if not ch then return 0 end
local n=0
for _,t in ipairs(MT:GetChildren())do
if t:IsA("Tool")then
t.Parent=ch  -- 直接塞进角色=同时装备，不走 Humanid 只拿一把的逻辑
n=n+1
end
end
for _,t in ipairs(ch:GetChildren())do
if t:IsA("Tool")then n=n+1 end
end
return n
end
LP.CharacterAdded:Connect(function(ch)
task.wait(0.6)
if multiOn then task.spawn(equipAllTools) end
end)
T2:Toggle({Title="多工具（所有工具一起拿，重生后自动重新拿）",Value=false,Callback=function(v)
multiOn=v
if v then
local n=equipAllTools()
WindUI:Notify({Title="多工具",Content="已拿出 "..n.." 个工具",Duration=5})
else
WindUI:Notify({Title="多工具",Content="已关闭，重生后恢复正常",Duration=4})
end
end})
T2:Button({Title="立刻拿出所有工具",Callback=function()
local n=equipAllTools()
WindUI:Notify({Title="多工具",Content="已拿出 "..n.." 个工具",Duration=5})
end})

T2:Button({Title="删除所有保存的船文件（不可恢复）",Callback=function()
local n=0
local ok,files=pcall(listfiles,"VoltaraBuildStorage")
if ok and files then
for _,f in ipairs(files)do
if f:sub(-6)==".Build" or f:sub(-7)==".vBuild" then
if pcall(delfile,f) then n=n+1 end
end
end
end
WindUI:Notify({Title="删除所有文件",Content=ok and ("已删除 "..n.." 个存档文件") or ("执行器不支持文件操作或没有存档"),Duration=7})
end})

-- 每个功能单独一个按钮，点了才渲染（核心下载后控件只排队，不上屏）
T2:Section({Title="复制船功能（先点 1 下载核心，再点要用的功能）"})
T2:Button({Title="1. 点我下载复制船核心",Callback=function()
copyBuilt=true
task.spawn(buildCopyUI)
end})
T2:Button({Title="2. 保存船 / 建造船（主菜单）·自动拿全部工具",Callback=function()
getgenv().BabyVoltraLoadPage("主菜单")
task.spawn(equipAllTools)
end})
T2:Button({Title="3. 图片转方块",Callback=function()
getgenv().BabyVoltraLoadPage("图片")
end})
T2:Button({Title="4. 加载器（形状/文字/二维码）",Callback=function()
getgenv().BabyVoltraLoadPage("加载器")
end})
T2:Button({Title="5. 3D 模型",Callback=function()
getgenv().BabyVoltraLoadPage("3D 模型")
end})
T2:Button({Title="6. 调整（位置/旋转/缩放）",Callback=function()
getgenv().BabyVoltraLoadPage("调整")
end})
T2:Button({Title="重新下载核心（更新/出错用）",Callback=function()
copyBuilt=false
task.spawn(buildCopyUI)
end})
