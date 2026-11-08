local WindUI=loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua"))()
local P=game:GetService("Players")
local LP=P.LocalPlayer
local sp,jp=16,50
local Win=WindUI:CreateWindow({Title="婴儿脚本"})
local ok=false
local T2,T3,T4,T5
local ntHeartStart
local G="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/"
local PM={[537413528]=G.."Boat_v37.lua",[98502499119821]=G.."Fish_v2.lua",[90148635862803]=G.."Deadly.lua",[107778070777162]=G.."Egg.lua",[79546208627805]=G.."N99.lua",[10165583746]=G.."Examination_zh.lua",[136431686349723]="https://raw.githubusercontent.com/78589wlg/baby-script/main/Pursued.lua",[13772394625]="https://raw.githubusercontent.com/78589wlg/baby-script/333ae2bad6/BladeBall.lua"}
local subLoaded=false
local function subAuto()
local u=PM[game.PlaceId]
if not u then return end
if subLoaded then return end
subLoaded=true
local okk=pcall(function()loadstring(game:HttpGet(u))()end)
if not okk then subLoaded=false end
end
local th={"Dark","Light","Rose","Plant","Red","Indigo","Sky","Violet","Amber","Emerald","Midnight","Crimson","MonokaiPro","CottonCandy","Mellowsi","Rainbow"}
local function hum()
local c=LP.Character
if c then return c:FindFirstChildOfClass("Humanoid")end
end
-- 永久卡密（无限期，可无限次使用）
local PERM={"卡密制作婴儿脚本6767","少羽没面"}
local KEY=PERM[1]
local auto=true
local done=false
local AM={[537413528]=1,[98502499119821]=1,[90148635862803]=1,[107778070777162]=1,[79546208627805]=1,[10165583746]=1,[136431686349723]=1,[13772394625]=1}

-- ===== 卡密（支持 7 天动态卡 + 老卡密） =====
local HSK=game:GetService("HttpService")
local KR="https://raw.githubusercontent.com/78589wlg/baby-script/main/"
local KSH="https://ae1580126123eca19.app.workbuddy.host"
local KSS="WGTNFAERQB"
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
local dvo,dvf=pcall(function()return readfile("BabyDevKeys.txt")end)
if dvo and type(dvf)=="string" then
for line in dvf:gmatch("[^\r\n]+")do
local dkk,dee=line:match("^([^,]+),?(.*)$")
if dkk and ktrim(dkk)==k then
local o2,e2=kexpok(ktrim(dee))
if not o2 then return false,"卡密已于 "..e2.." 过期",nil end
if e2=="永久" or e2=="" then return true,"验证通过（开发者·永久）","永久" end
return true,"验证通过（开发者·有效期至 "..e2.."）",e2
end
end
end
local okk,txt=pcall(function()return game:HttpGet(KSH.."/devkeys?sharecode="..KSS.."&t="..tostring(os.time()))end)
if not okk or type(txt)~="string" or #txt<1 then
okk,txt=pcall(function()return game:HttpGet(KR.."devkeys.txt?t="..tostring(os.time()))end)
end
if okk and type(txt)=="string" then
for line in txt:gmatch("[^\r\n]+")do
local ln=ktrim(line)
if ln~="" and ln:sub(1,1)~="#" then
local kk,ee=ln:match("^([^,]+),?(.*)$")
if kk and ktrim(kk)==k then
local o2,e2=kexpok(ktrim(ee))
if not o2 then return false,"卡密已于 "..e2.." 过期",nil end
if e2=="永久" or e2=="" then return true,"验证通过（开发者·永久）","永久" end
return true,"验证通过（开发者·有效期至 "..e2.."）",e2
end
end
end
end
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
if writefile then writefile("BabyKey.txt",ktrim(k).."|"..tostring(exp or "").."|"..tostring(os.time()))end
end)
end
-- 读取上次保存的卡密，免重复输入
local savedK,savedE,savedT="","",0
pcall(function()
local f=readfile("BabyKey.txt")
if type(f)=="string" then
local a,b,c=f:match("^([^|]+)|([^|\r\n]*)|?([^|\r\n]*)")
if a then savedK=ktrim(a) savedE=ktrim(b or "") savedT=tonumber(c) or 0 end
end
end)
if savedK~="" then
local valid=false
local sawList=false
if isPerm(savedK) then
valid=true
else
-- 检查卡密是否还被保留：本地名单 → 云端名单 → keys.txt → 接口
local dvo,dvf=pcall(function()return readfile("BabyDevKeys.txt")end)
if dvo and type(dvf)=="string" then
for line in dvf:gmatch("[^\r\n]+")do
local dkk,dee=line:match("^([^,]+),?(.*)$")
if dkk and ktrim(dkk)==savedK then
sawList=true
if kexpok(ktrim(dee))then valid=true end
end
end
end
if not sawList then
local okc,ctxt=pcall(function()return game:HttpGet(KSH.."/devkeys?sharecode="..KSS.."&t="..tostring(os.time()))end)
if not okc or type(ctxt)~="string" then
okc,ctxt=pcall(function()return game:HttpGet(KR.."devkeys.txt?t="..tostring(os.time()))end)
end
if okc and type(ctxt)=="string" and #ctxt>0 then
sawList=true
for line in ctxt:gmatch("[^\r\n]+")do
local kk,ee=line:match("^([^,]+),?(.*)$")
if kk and ktrim(kk)==savedK then
if kexpok(ktrim(ee))then valid=true end
end
end
end
end
if not sawList then
local okt,tt=pcall(function()return game:HttpGet(KR.."keys.txt?t="..tostring(os.time()))end)
if okt and type(tt)=="string" and #tt>0 then
sawList=true
for line in tt:gmatch("[^\r\n]+")do
local ln=ktrim(line)
if ln~="" and ln:sub(1,1)~="#" then
local kk,ee=ln:match("^([^,]+),?(.*)$")
if kk and ktrim(kk)==savedK then
if kexpok(ktrim(ee))then valid=true end
end
end
end
end
end
if not sawList then
local base=kgetAPI()
if base~="" then
local okv,res=pcall(function()return game:HttpGet(base.."/verify?key="..savedK)end)
if okv and type(res)=="string" and #res>2 then
sawList=true
local okd,d=pcall(function()return HSK:JSONDecode(res)end)
if okd and type(d)=="table" and d.ok then valid=true end
end
end
end
-- 网络全挂拿不到任何名单时放行，避免误踢
if not sawList then valid=true end
end
if valid then
ok=true
else
ok=false
savedK="" savedE="" savedT=0
pcall(function()if writefile then writefile("BabyKey.txt","")end end)
getgenv().babyKeyDeleted=true
end
-- 服务器端清除检查：保存时间早于清除点且不是豁免卡密 → 强制重新输入
if ok then
local okr,rtxt=pcall(function()return game:HttpGet(KSH.."/keyreset?sharecode="..KSS.."&t="..tostring(os.time()))end)
if not okr or type(rtxt)~="string" or #rtxt<3 then
okr,rtxt=pcall(function()return game:HttpGet(KR.."keyreset.txt?t="..tostring(os.time()))end)
end
if okr and type(rtxt)=="string" then
local rt,rk=rtxt:match("^(%d+)|([^|\r\n]*)")
rt=tonumber(rt)
if rt and savedT<rt and ktrim(savedK)~=ktrim(rk or "")then
ok=false
savedK="" savedE="" savedT=0
pcall(function()if writefile then writefile("BabyKey.txt","")end end)
getgenv().babyResetKick=true
end
end
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
if ntHeartStart then pcall(ntHeartStart) end
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
-- ===== 在线脚本用户（公共在线表，免部署） =====
local NT="https://ntfy.sh/"
local ntOn=false
local ntSeen={}
local ntGui,ntTitle,ntBody
local hudOn=false

local function ntTopic()return "bs_online_"..tostring(game.PlaceId)end
local function ntClean(s)local t=tostring(s or "")return (t:gsub("[|\r\n]",""))end
local function ntPost(u,b)
local ok=pcall(function()game:HttpPost(u,b)end)
if ok then return true end
local f=request
if not f then f=http_request end
if not f and syn and syn.request then f=syn.request end
if f then
local ok2=pcall(function()f({Url=u,Method="POST",Body=b,Headers={["Content-Type"]="text/plain"}})end)
return ok2
end
return false
end

local function ntHUD()
if ntGui and ntGui.Parent then return true end
local pg=LP:FindFirstChildOfClass("PlayerGui")
if not pg then return false end
local oldg=pg:FindFirstChild("BabyOnline")
if oldg then pcall(function()oldg:Destroy()end) end
local g=Instance.new("ScreenGui")
g.Name="BabyOnline"
g.ResetOnSpawn=false
g.IgnoreGuiInset=true
g.DisplayOrder=999
g.Parent=pg
local f=Instance.new("Frame")
f.Name="Box"
f.AnchorPoint=Vector2.new(1,0)
f.Position=UDim2.new(1,-12,0,84)
f.Size=UDim2.new(0,236,0,186)
f.BackgroundColor3=Color3.fromRGB(20,20,26)
f.BackgroundTransparency=0.12
f.BorderSizePixel=0
f.Parent=g
local c1=Instance.new("UICorner")
c1.CornerRadius=UDim.new(0,8)
c1.Parent=f
local t=Instance.new("TextButton")
t.Name="Head"
t.Size=UDim2.new(1,0,0,30)
t.BackgroundColor3=Color3.fromRGB(38,38,50)
t.BorderSizePixel=0
t.Text="在线脚本用户 0"
t.TextColor3=Color3.fromRGB(255,255,255)
t.Font=Enum.Font.GothamBold
t.TextSize=14
t.AutoButtonColor=false
t.Parent=f
local b=Instance.new("TextLabel")
b.Name="Body"
b.Position=UDim2.new(0,10,0,36)
b.Size=UDim2.new(1,-20,1,-44)
b.BackgroundTransparency=1
b.Text=""
b.TextColor3=Color3.fromRGB(215,215,225)
b.Font=Enum.Font.Gotham
b.TextSize=13
b.TextXAlignment=Enum.TextXAlignment.Left
b.TextYAlignment=Enum.TextYAlignment.Top
b.TextWrapped=true
b.Parent=f
ntGui=g
ntTitle=t
ntBody=b
t.MouseButton1Click:Connect(function()
b.Visible=not b.Visible
f.Size=UDim2.new(0,236,0,b.Visible and 186 or 34)
end)
return true
end

local function ntRender()
if not hudOn then return end
if not ntHUD() then return end
local arr={}
for _,v in pairs(ntSeen)do arr[#arr+1]=v end
table.sort(arr,function(a,b)return (a.t or 0)>(b.t or 0)end)
local myJ=tostring(game.JobId)
local lines={}
local cross=0
local shown=0
local lim=12
local sameFirst={}
local otherFirst={}
for _,v in ipairs(arr)do
if v.j and v.j~="" and v.j~=myJ then otherFirst[#otherFirst+1]=v else sameFirst[#sameFirst+1]=v end
end
for _,v in ipairs(sameFirst)do
if shown>=lim then break end
shown=shown+1
local nm=v.dn
if not nm or nm=="" then nm=v.nm end
local me=(tostring(v.u)==tostring(LP.UserId)) and "（你）" or ""
lines[#lines+1]="· "..nm..me
end
if #otherFirst>0 then
lines[#lines+1]="── 其他服务器 "..#otherFirst.." 人 ──"
for _,v in ipairs(otherFirst)do
cross=cross+1
if shown<lim then
shown=shown+1
local nm=v.dn
if not nm or nm=="" then nm=v.nm end
lines[#lines+1]="· "..nm.."（跨服 @"..v.nm.."）"
end
end
end
if #arr==0 then lines[#lines+1]="暂无记录" end
local hidden=#arr-shown
if hidden>0 then lines[#lines+1]="…还有 "..hidden.." 人" end
if cross>0 then
ntTitle.Text="在线脚本用户 "..#arr.."（跨服 "..cross.."）"
else
ntTitle.Text="在线脚本用户 "..#arr
end
ntBody.Text=table.concat(lines,"\n")
end

local function ntBeat()
local jid=ntClean(tostring(game.JobId))
if jid=="" then jid="unknown" end
local b=tostring(LP.UserId).."|"..ntClean(LP.DisplayName).."|"..ntClean(LP.Name).."|"..tostring(game.PlaceId).."|"..tostring(os.time()).."|"..jid
return ntPost(NT..ntTopic(),b)
end

-- 常驻心跳：与两个开关无关，脚本一解锁就一直上报（这样别人关掉开关也能被你看到）
local ntHeartOn=false
ntHeartStart=function()
if ntHeartOn then return end
ntHeartOn=true
task.spawn(function()
while ntHeartOn do
pcall(ntBeat)
local n=0
while ntHeartOn and n<60 do task.wait(1) n=n+1 end
end
end)
end

local function ntFetch()
local ok,txt=pcall(function()return game:HttpGet(NT..ntTopic().."/json?poll=1&since=15m")end)
if not ok or type(txt)~="string" then return false end
local now=os.time()
local seen={}
for line in txt:gmatch("[^\r\n]+")do
local m=line:match('"message":"(.-)"')
if m then
local u,dn,nm,p,ts,j=m:match("^(%d+)|([^|]*)|([^|]*)|(%d+)|(%d+)|?(.-)$")
if u and ts then
local tt=tonumber(ts)
if tt and now-tt<=200 then
local o=seen[u]
if not o or tt>o.t then
seen[u]={u=u,dn=dn,nm=nm,t=tt,j=j or ""}
end
end
end
end
end
local added={}
for u,v in pairs(seen)do
if not ntSeen[u] then added[#added+1]=v end
end
ntSeen=seen
return true,added
end

-- ===== 脚本使用者：绿色高亮 + 头顶标签 =====
local espOn=false
local espMap={}
local function espClear()
for pl,e in pairs(espMap)do
if e.hl then pcall(function()e.hl:Destroy()end) end
if e.tag then pcall(function()e.tag:Destroy()end) end
end
espMap={}
end

local function espApply()
if not espOn then return end
for _,pl in ipairs(game.Players:GetPlayers())do
local rec=ntSeen[tostring(pl.UserId)]
local ch=pl.Character
local e=espMap[pl]
if rec and ch then
if not e then e={} espMap[pl]=e end
if not (e.hl and e.hl.Parent) then
local hl=Instance.new("Highlight")
hl.Name="BabyScriptHL"
hl.FillColor=Color3.fromRGB(0,255,90)
hl.FillTransparency=0.55
hl.OutlineColor=Color3.fromRGB(0,255,90)
hl.OutlineTransparency=0
hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
hl.Adornee=ch
hl.Parent=ch
e.hl=hl
end
local hd=ch:FindFirstChild("Head")
if hd and not (e.tag and e.tag.Parent) then
local bb=Instance.new("BillboardGui")
bb.Name="BabyScriptTag"
bb.Size=UDim2.new(0,150,0,34)
bb.StudsOffset=Vector3.new(0,2.4,0)
bb.AlwaysOnTop=true
bb.MaxDistance=150
local tl=Instance.new("TextLabel")
tl.Size=UDim2.new(1,0,1,0)
tl.BackgroundTransparency=1
tl.Text="脚本使用者"
tl.TextColor3=Color3.fromRGB(0,255,90)
tl.TextStrokeColor3=Color3.fromRGB(0,0,0)
tl.TextStrokeTransparency=0.35
tl.Font=Enum.Font.GothamBold
tl.TextScaled=true
tl.Parent=bb
bb.Parent=hd
e.tag=bb
end
else
if e then
if e.hl then pcall(function()e.hl:Destroy()end) end
if e.tag then pcall(function()e.tag:Destroy()end) end
espMap[pl]=nil
end
end
end
end

local function ntDropHud()
hudOn=false
if ntGui then pcall(function()ntGui:Destroy()end) end
ntGui=nil
end

local function ntStop()
ntOn=false
hudOn=false
if ntGui then pcall(function()ntGui:Destroy()end) end
ntGui=nil
ntSeen={}
espClear()
end

local function ntStart()
if ntOn then return end
ntOn=true
task.spawn(function()
local first=true
local fast=0
while ntOn do
local ok,added=pcall(ntFetch)
if ok then
pcall(ntRender)
pcall(espApply)
if first then
local n=0
for _ in pairs(ntSeen)do n=n+1 end
if n>1 then
WindUI:Notify({Title="脚本使用者",Content="发现 "..n.." 个同脚本玩家（含你）",Duration=5})
elseif n==1 then
local only=nil
for _,v in pairs(ntSeen)do only=v end
if only then
if tostring(only.u)==tostring(LP.UserId)then
WindUI:Notify({Title="脚本使用者",Content="目前只有你在用",Duration=4})
else
local nm=only.dn
if not nm or nm=="" then nm=only.nm end
local cj=only.j and only.j~="" and only.j~=tostring(game.JobId)
local pre=cj and "跨服发现脚本使用者：" or "发现脚本使用者："
WindUI:Notify({Title="脚本使用者",Content=pre..nm..(cj and "（在其他服务器）" or ""),Duration=5})
end
end
end
first=false
elseif type(added)=="table" and #added>0 then
local k=0
for _,v in ipairs(added)do
if tostring(v.u)~=tostring(LP.UserId)then
k=k+1
if k<=3 then
local nm=v.dn
if not nm or nm=="" then nm=v.nm end
local isCross=v.j and v.j~="" and v.j~=tostring(game.JobId)
if isCross then
WindUI:Notify({Title="跨服发现脚本使用者",Content=nm.."（在其他服务器）",Duration=4})
else
WindUI:Notify({Title="新发现脚本使用者",Content=nm,Duration=4})
end
end
end
end
end
end
fast=fast+1
local gap=60
if fast<=6 then gap=20 end
local n=0
while ntOn and n<gap do task.wait(1) n=n+1 end
end
end)
task.spawn(function()
while ntOn do
task.wait(2)
if espOn then pcall(espApply) end
end
end)
task.delay(5,function()
if not ntOn then return end
local n=0
for _ in pairs(ntSeen)do n=n+1 end
if n==0 then
WindUI:Notify({Title="脚本用户检测",Content="暂时没拉到在线数据（没人开或网络受限）",Duration=5})
end
end)
end

T4:Toggle({Title="脚本用户检测（显示右侧小窗）",Value=false,Callback=function(v)
if v then
hudOn=true
WindUI:Notify({Title="脚本用户检测",Content="正在连接公共在线表…",Duration=3})
if ntOn then
task.spawn(function()
pcall(ntFetch)
pcall(ntRender)
pcall(espApply)
end)
else
ntStart()
end
else
ntDropHud()
if not espOn then
ntStop()
WindUI:Notify({Title="脚本用户检测",Content="小窗已关闭｜你的心跳仍在上报，别人依然看得到你",Duration=5})
else
WindUI:Notify({Title="脚本用户检测",Content="小窗已关闭，变绿仍生效｜你依然在别人的名单里",Duration=5})
end
end
end})
T4:Toggle({Title="脚本使用者变绿 + 头顶字（独立生效）",Value=false,Callback=function(v)
espOn=v
if v then
if not ntOn then
hudOn=false
ntStart()
end
WindUI:Notify({Title="脚本使用者",Content="同脚本玩家会变绿，头顶显示「脚本使用者」",Duration=4})
task.spawn(function()
pcall(ntFetch)
pcall(ntRender)
pcall(espApply)
end)
else
espClear()
if not hudOn then ntStop() end
WindUI:Notify({Title="脚本使用者",Content="已关闭｜你依然在别人的名单里（心跳常驻）",Duration=5})
end
end})
T4:Button({Title="刷新在线名单",Callback=function()
if not ntOn then WindUI:Notify({Title="在线名单",Content="请先打开上面的开关",Duration=3})return end
local ok=ntFetch()
if ok then pcall(ntRender) end
local n=0
for _ in pairs(ntSeen)do n=n+1 end
WindUI:Notify({Title="在线名单",Content=ok and ("当前 "..n.." 人") or "拉取失败，检查网络",Duration=3})
end})
T4:Button({Title="复制在线名单",Callback=function()
local arr={}
for _,v in pairs(ntSeen)do
local nm=v.dn
if not nm or nm=="" then nm=v.nm end
arr[#arr+1]=nm.."("..tostring(v.nm)..")"
end
if #arr==0 then WindUI:Notify({Title="在线名单",Content="暂无数据",Duration=3})return end
pcall(function()if setclipboard then setclipboard(table.concat(arr,"\n"))end end)
WindUI:Notify({Title="在线名单",Content="已复制 "..#arr.." 人",Duration=3})
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
T4:Section({Title="开发者功能"})
local DEVKEY="婴儿nb-作者-VIP8888"
local DEVURL="https://raw.githubusercontent.com/78589wlg/baby-script/main/Dev_v5.lua"
local devTxt=""
local function devLoad()
local okk=pcall(function()loadstring(game:HttpGet(DEVURL))()end)
if okk then
WindUI:Notify({Title="开发者功能",Content="已加载",Duration=3})
else
WindUI:Notify({Title="开发者功能",Content="加载失败，检查网络",Duration=4})
end
end
T4:Input({Title="开发者卡密",Placeholder="请输入开发者专用卡密",Value="",Callback=function(t)devTxt=t end})
T4:Button({Title="验证并加载开发者功能",Callback=function()
if ktrim(devTxt)~=DEVKEY then
WindUI:Notify({Title="开发者功能",Content="卡密不对",Duration=4})
return
end
pcall(function()if writefile then writefile("BabyDev.txt",DEVKEY)end end)
getgenv().babyDevOK=true
devLoad()
end})
T4:Button({Title="重新打开开发者面板（免输卡密）",Callback=function()
local has=false
pcall(function()if isfile and isfile("BabyDev.txt")then has=readfile("BabyDev.txt")==DEVKEY end end)
if not has and not getgenv().babyDevOK then
WindUI:Notify({Title="开发者功能",Content="还没解锁，请先输入开发者卡密验证",Duration=4})
return
end
devLoad()
end})

T4:Button({Title="复制QQ号",Callback=function()
pcall(function()setclipboard("3492202561")end)
WindUI:Notify({Title="QQ号",Content="3492202561 已复制",Duration=2})
end})
T5=Win:Tab({Title="脚本库",Icon="list",Locked=true})
T5:Section({Title="其他脚本"})
local sel="造船寻宝"
local LU={["造船寻宝"]="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/Boat_v37.lua",["重型钓鱼"]="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/Fish_v2.lua",["在末日中生存下来"]="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/Deadly.lua",["偷一个蛋"]="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/Egg.lua",["森林中的99夜"]="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/N99.lua",["试炼"]="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/Examination_zh.lua",["战利品"]="https://raw.githubusercontent.com/78589wlg/baby-script/main/Loot_v2.lua",["被追捕（HUNTED）"]="https://raw.githubusercontent.com/78589wlg/baby-script/main/Pursued.lua",["Blade Ball（剑球）"]="https://raw.githubusercontent.com/78589wlg/baby-script/333ae2bad6/BladeBall.lua"}
T5:Dropdown({Title="选择脚本",Values={"造船寻宝","重型钓鱼","在末日中生存下来","偷一个蛋","森林中的99夜","试炼","战利品","被追捕（HUNTED）","Blade Ball（剑球）"},Value="造船寻宝",Callback=function(v)
sel=v
end})
T5:Button({Title="使用",Callback=function()
local u=LU[sel]
if not u then WindUI:Notify({Title="脚本库",Content="未知脚本",Duration=2})return end
WindUI:Notify({Title="脚本库",Content="正在执行 "..sel,Duration=2})
pcall(function()loadstring(game:HttpGet(u))()end)
end})
T5:Toggle({Title="进入游戏自动加载副脚本",Value=true,Callback=function(v)auto=v end})
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

if getgenv().babyResetKick then
task.delay(2,function()
pcall(function()WindUI:Notify({Title="卡密",Content="你的卡密已被开发者清除，请重新输入",Duration=6})end)
end)
end
if getgenv().babyKeyDeleted then
task.delay(2,function()
pcall(function()WindUI:Notify({Title="卡密",Content="你的卡密已被开发者删除，已失效，请重新获取卡密",Duration=7})end)
end)
end
if ok then task.defer(doUnlock,true)end
