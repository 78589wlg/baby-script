-- 自制 UI（半透明玻璃窗 + 彩色流光 + 可收成悬浮球）；拉取失败自动回退 WindUI
local WindUI
do
local okB,B=pcall(function()
return loadstring(game:HttpGet("https://raw.githubusercontent.com/78589wlg/baby-script/main/BabyUI.lua?v=2"))()
end)
if okB and type(B)=="table" and B.CreateWindow then
WindUI=B
else
WindUI=loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua"))()
end
end
local P=game:GetService("Players")
local LP=P.LocalPlayer
local sp,jp=16,50
local function guiRoots()
local t={}
local pg=LP:FindFirstChildOfClass("PlayerGui")
if pg then t[#t+1]=pg end
local okc,cg=pcall(function() return game:GetService("CoreGui") end)
if okc and cg then t[#t+1]=cg end
return t
end
local GUIO={}
for _,r in ipairs(guiRoots()) do for _,c in ipairs(r:GetChildren()) do GUIO[c]=true end end
local Win=WindUI:CreateWindow({Title="婴儿脚本"})
local SelfGui
for _,r in ipairs(guiRoots()) do
for _,c in ipairs(r:GetChildren()) do
if not GUIO[c] and c:IsA("ScreenGui") then SelfGui=c end
end
end
local ok=false
local T2,T3,T4,T5
local ntHeartStart
local G="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/"
local PM={[537413528]="https://raw.githubusercontent.com/78589wlg/baby-script/main/Boat_v37.lua?v=53",[98502499119821]=G.."Fish_v2.lua",[90148635862803]=G.."Deadly.lua",[107778070777162]=G.."Egg.lua",[79546208627805]=G.."N99.lua",[10165583746]=G.."Examination_zh.lua",[136431686349723]="https://raw.githubusercontent.com/78589wlg/baby-script/main/Pursued.lua?v=5"}
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
-- 卡密验证已拆成独立脚本 BabyKey.lua；主脚本不再校验卡密
local auto=true
local AM={[537413528]=1,[98502499119821]=1,[90148635862803]=1,[107778070777162]=1,[79546208627805]=1,[10165583746]=1,[136431686349723]=1}
local done=false
local function ktrim(x)return (tostring(x):gsub("^%s+",""):gsub("%s+$",""))end
local function doUnlock()
if done then return end
done=true
for _,x in ipairs({T2,T3,T4,T5})do
if x then pcall(function()x.Locked=false x:UnlockAll()end)end
end
if ntHeartStart then pcall(ntHeartStart) end
if auto and AM[game.PlaceId]then
WindUI:Notify({Title="自动加载",Content="正在加载副脚本",Duration=3})
task.wait(1)
subAuto()
end
end

local T1=Win:Tab({Title="设置",Icon="settings"})
T1:Section({Title="界面配色（点一下立刻换色）"})
for i=1,#th do
local n=th[i]
T1:Button({Title=n,Callback=function()
pcall(function()WindUI:SetTheme(n)end)
WindUI:Notify({Title="主题",Content=n,Duration=1})
end})
end
T2=Win:Tab({Title="玩家增强",Icon="user"})
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
T2:Section({Title="飞行设置"})
local flyOn=false
local flySpeed=80
local flyBV,flyBG,flyConn=nil,nil,nil
local flyHoldUp,flyHoldDown=false,false
local flyPad,flyPadUp,flyPadDown
local flyToggleRef

local function buildFlyPad()
if flyPad then return flyPad end
local g=Instance.new("ScreenGui")
g.Name="BabyFlyPad"
g.ResetOnSpawn=false
g.IgnoreGuiInset=true
g.DisplayOrder=900
pcall(function()g.Parent=game:GetService("CoreGui")end)
if not g.Parent then g.Parent=LP:WaitForChild("PlayerGui")end
local function mk(text,posY)
local b=Instance.new("TextButton")
b.Size=UDim2.new(0,58,0,58)
b.Position=UDim2.new(1,-160,0.5,posY)
b.BackgroundColor3=Color3.fromRGB(28,31,40)
b.BackgroundTransparency=0.1
b.Text=text
b.TextColor3=Color3.fromRGB(255,255,255)
b.TextSize=22
b.Font=Enum.Font.GothamBold
b.AutoButtonColor=false
b.Parent=g
local c=Instance.new("UICorner")
c.CornerRadius=UDim.new(1,0)
c.Parent=b
local st=Instance.new("UIStroke")
st.Color=Color3.fromRGB(245,166,35)
st.Thickness=1
st.Transparency=0.4
st.Parent=b
return b
end
flyPadUp=mk("▲",-36)
flyPadDown=mk("▼",34)
local function bindHold(btn,field)
btn.InputBegan:Connect(function(i)
if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
if field=="up" then flyHoldUp=true else flyHoldDown=true end
end
end)
btn.InputEnded:Connect(function(i)
if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then
if field=="up" then flyHoldUp=false else flyHoldDown=false end
end
end)
end
bindHold(flyPadUp,"up")
bindHold(flyPadDown,"down")
g.Enabled=false
flyPad=g
return g
end

local function stopFly(quiet)
flyOn=false
flyHoldUp=false
flyHoldDown=false
if flyConn then flyConn:Disconnect() flyConn=nil end
if flyBV then pcall(function() flyBV:Destroy() end) flyBV=nil end
if flyBG then pcall(function() flyBG:Destroy() end) flyBG=nil end
if flyPad then flyPad.Enabled=false end
local c=LP.Character
local h=c and c:FindFirstChildOfClass("Humanoid")
if h then pcall(function() h.PlatformStand=false end) end
if not quiet then
pcall(function() WindUI:Notify({Title="飞行",Content="已关闭",Duration=1}) end)
end
end

local function startFly()
local c=LP.Character
local h=c and c:FindFirstChildOfClass("Humanoid")
local hrp=c and c:FindFirstChild("HumanoidRootPart")
if not (h and hrp) then
pcall(function() WindUI:Notify({Title="飞行",Content="没找到角色，重生后再试",Duration=2}) end)
return false
end
stopFly(true)
flyOn=true
local uis=game:GetService("UserInputService")
if not uis.TouchEnabled then
pcall(function() h.PlatformStand=true end)
end
flyBV=Instance.new("BodyVelocity")
flyBV.MaxForce=Vector3.new(100000,100000,100000)
flyBV.P=1250
flyBV.Velocity=Vector3.new(0,0,0)
flyBV.Parent=hrp
flyBG=Instance.new("BodyGyro")
flyBG.MaxTorque=Vector3.new(100000,100000,100000)
flyBG.P=3000
flyBG.D=100
flyBG.CFrame=hrp.CFrame
flyBG.Parent=hrp
buildFlyPad().Enabled=true
flyConn=game:GetService("RunService").RenderStepped:Connect(function()
local ch=LP.Character
local root=ch and ch:FindFirstChild("HumanoidRootPart")
local hum=ch and ch:FindFirstChildOfClass("Humanoid")
if not root or not flyBV or not flyBG or not flyOn then return end
local cam=workspace.CurrentCamera
local dir=Vector3.new(0,0,0)
if uis:GetFocusedTextBox()==nil then
if uis:IsKeyDown(Enum.KeyCode.W) then dir=dir+cam.CFrame.LookVector end
if uis:IsKeyDown(Enum.KeyCode.S) then dir=dir-cam.CFrame.LookVector end
if uis:IsKeyDown(Enum.KeyCode.D) then dir=dir+cam.CFrame.RightVector end
if uis:IsKeyDown(Enum.KeyCode.A) then dir=dir-cam.CFrame.RightVector end
if uis:IsKeyDown(Enum.KeyCode.Space) then dir=dir+Vector3.new(0,1,0) end
if uis:IsKeyDown(Enum.KeyCode.LeftControl) or uis:IsKeyDown(Enum.KeyCode.LeftShift) then dir=dir-Vector3.new(0,1,0) end
end
-- 手机摇杆（摇杆方向直接当飞行方向）
if hum and hum.MoveDirection.Magnitude>0.1 then
dir=dir+hum.MoveDirection
end
if flyHoldUp then dir=dir+Vector3.new(0,1,0) end
if flyHoldDown then dir=dir-Vector3.new(0,1,0) end
if dir.Magnitude>0 then
flyBV.Velocity=dir.Unit*flySpeed
else
flyBV.Velocity=Vector3.new(0,0,0)
end
flyBG.CFrame=cam.CFrame
end)
return true
end

flyToggleRef=T2:Toggle({Title="飞行（F 键开关 · 朝相机方向飞）",Value=false,Callback=function(v)
if v then
if not startFly() then
pcall(function() if flyToggleRef and flyToggleRef.Set then flyToggleRef:Set(false) end end)
end
else
stopFly()
end
end})
T2:Slider({Title="飞行速度",Value={Min=20,Max=300,Default=80},Callback=function(v)
flySpeed=v
end})
T2:Button({Title="飞行 · 上升一点",Callback=function()
local c=LP.Character
local hrp=c and c:FindFirstChild("HumanoidRootPart")
if hrp then hrp.CFrame=hrp.CFrame+Vector3.new(0,3,0) end
end})
T2:Button({Title="飞行 · 下降一点",Callback=function()
local c=LP.Character
local hrp=c and c:FindFirstChild("HumanoidRootPart")
if hrp then hrp.CFrame=hrp.CFrame-Vector3.new(0,3,0) end
end})
game:GetService("UserInputService").InputBegan:Connect(function(i,gpe)
if gpe then return end
if i.KeyCode==Enum.KeyCode.F then
if flyOn then
stopFly()
else
startFly()
end
pcall(function() if flyToggleRef and flyToggleRef.Set then flyToggleRef:Set(flyOn) end end)
end
end)
LP.CharacterAdded:Connect(function()
if flyOn then
task.wait(1)
pcall(function() stopFly(true) end)
end
end)
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
T3=Win:Tab({Title="其他脚本",Icon="package"})
T3:Section({Title="脚本列表"})
T3:Button({Title="皮脚本",Callback=function()
getgenv().XiaoPi="皮脚本QQ1002100032"
pcall(function()loadstring(game:HttpGet("https://raw.githubusercontent.com/xiaopi77/xiaopi77/main/QQ1002100032-Roblox-Pi-script.lua"))()end)
end})
T3:Section({Title="剑球（第三方 · 先私服试）"})
local function bb3(name,url)
WindUI:Notify({Title="第三方脚本",Content=name.." 不是我写的，用私服小号测",Duration=3})
pcall(function()loadstring(game:HttpGet(url))()end)
end
T3:Button({Title="剑球 · Fairn't Hub（8KB 明文）",Callback=function()
bb3("Fairn't Hub","https://cdn.jsdelivr.net/gh/Asyrantheyt/Fairn-t-Hub@main/scripts/Blade%20Ball.lua")
end})
T3:Button({Title="剑球 · CritClHub（6KB 明文，最简）",Callback=function()
bb3("CritClHub","https://cdn.jsdelivr.net/gh/wploits/critclhub@main/bladeball.lua")
end})
T3:Button({Title="剑球 · Opensurs（60KB 大杂烩）",Callback=function()
bb3("Opensurs","https://cdn.jsdelivr.net/gh/HOSTI1315/Opensurs@main/bladeball_2.lua")
end})
T4=Win:Tab({Title="更多"})
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
-- ===== 翻译 =====
T4:Section({Title="翻译"})
local trLang,trScene,trOther,trEngine="zh",false,true,"google"
T4:Dropdown({Title="翻译成",Values={"简体中文","English","日本語","한국어","繁體中文"},Value="简体中文",Callback=function(v)
local m={["简体中文"]="zh",["English"]="en",["日本語"]="ja",["한국어"]="ko",["繁體中文"]="zh-TW"}
trLang=m[v] or "zh"
getgenv().BabyTransLang=trLang
if getgenv().BabyTransSetLang then pcall(getgenv().BabyTransSetLang,trLang) end
end})
T4:Dropdown({Title="翻译引擎",Values={"Google","自动（谁快用谁）","必应","腾讯","MyMemory"},Value="Google",Callback=function(v)
local m={["自动（谁快用谁）"]="auto",["Google"]="google",["必应"]="bing",["腾讯"]="tencent",["MyMemory"]="mymemory"}
trEngine=m[v] or "auto"
getgenv().BabyTransEngine=trEngine
if getgenv().BabyTransSetEngine then pcall(getgenv().BabyTransSetEngine,trEngine) end
end})
T4:Toggle({Title="翻译游戏文字（界面）",Value=false,Callback=function(v)
if v then
getgenv().BabyTransLang=trLang
getgenv().BabyTransScene=trScene
getgenv().BabyTransOther=trOther
getgenv().BabyTransEngine=trEngine
getgenv().BabyTransSelfGui=SelfGui
pcall(function()loadstring(game:HttpGet("https://raw.githubusercontent.com/78589wlg/baby-script/main/Trans.lua?v=5"))()end)
else
if getgenv().BabyTransOff then pcall(getgenv().BabyTransOff) end
end
end})
T4:Toggle({Title="包含场景文字（告示牌/头顶字）",Value=false,Callback=function(v)
trScene=v
getgenv().BabyTransScene=v
if getgenv().BabyTransSetScene then pcall(getgenv().BabyTransSetScene,v) end
end})
T4:Toggle({Title="翻译其他脚本（第三方面板）",Value=true,Callback=function(v)
trOther=v
getgenv().BabyTransOther=v
if getgenv().BabyTransSetOther then pcall(getgenv().BabyTransSetOther,v) end
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
T5=Win:Tab({Title="脚本库",Icon="list"})
T5:Section({Title="其他脚本"})
local sel="造船寻宝"
local LU={["造船寻宝"]="https://raw.githubusercontent.com/78589wlg/baby-script/main/Boat_v37.lua?v=53",["重型钓鱼"]="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/Fish_v2.lua",["在末日中生存下来"]="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/Deadly.lua",["偷一个蛋"]="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/Egg.lua",["森林中的99夜"]="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/N99.lua",["试炼"]="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/Examination_zh.lua",["战利品"]="https://raw.githubusercontent.com/78589wlg/baby-script/main/Loot_v2.lua",["被追捕（HUNTED）"]="https://raw.githubusercontent.com/78589wlg/baby-script/main/Pursued.lua?v=5",["Blade Ball（剑球）"]="https://raw.githubusercontent.com/78589wlg/baby-script/main/BladeBall.lua?v=17",["监狱人生（Prison Life）"]="https://raw.githubusercontent.com/78589wlg/baby-script/main/PrisonLife.lua?v=2"}
T5:Dropdown({Title="选择脚本",Values={"造船寻宝","重型钓鱼","在末日中生存下来","偷一个蛋","森林中的99夜","试炼","战利品","被追捕（HUNTED）","Blade Ball（剑球）","监狱人生（Prison Life）"},Value="造船寻宝",Callback=function(v)
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
doUnlock()
