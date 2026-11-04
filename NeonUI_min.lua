local S="https://cdn.jsdelivr.net/gh/78589wlg/baby-script@main/"
local P,L=game:GetService("Players"),game.Players.LocalPlayer
local W=loadstring(game:HttpGet(S.."ui.lua"))()
local Win=W:CreateWindow({Title="婴儿脚本"})
local N=W.Notify
local K="少羽没面"
local ok=false
local a={"/Boat_v21","/Fish_v2","/Deadly","/Egg","/N99","/Examination_zh"}
local I={537413528,98502499119821,90148635862803,107778070777162,79546208627805,10165583746}
local PM={}
for i=1,6 do PM[I[i]]=S..a[i]..".lua" end
local function sub()
local u=PM[game.PlaceId]
if u then pcall(function()loadstring(game:HttpGet(u))()end)end
end
local th={"Dark","Light","Rose","Plant","Red","Indigo","Sky","Violet","Amber","Emerald","Midnight","Crimson","MonokaiPro","CottonCandy","Mellowsi","Rainbow"}
local function hum()
local c=L.Character
return c and c:FindFirstChildOfClass("Humanoid")
end
local sp,jp=16,50
local auto=true
local d1=false
if getgenv().babyKey==K then ok=true end
local T1=Win:Tab({Title="卡密验证",Icon="key"})
T1:Section({Title="请输入卡密"})
T1:Input({Title="卡密",Placeholder="在此输入",Value=ok and K or "",Callback=function(t)
if t:gsub("%s","")==K then ok=true end
end})
local T2,T3,T4,T5
T1:Button({Title="验证卡密",Callback=function()
if d1 then return end
if not ok then N({Title="失败",Content="卡密不对",Duration=2})return end
d1=true
for _,x in ipairs({T2,T3,T4,T5})do
if x then pcall(function()x.Locked=false x:UnlockAll()end)end
end
getgenv().babyKey=K
N({Title="婴儿脚本",Content="欢迎你使用婴儿脚本",Duration=3})
task.wait(1.2)
N({Title="婴儿脚本",Content="祝你玩的开心",Duration=3})
task.wait(1.2)
if auto and PM[game.PlaceId]then
N({Title="自动加载",Content="正在加载副脚本",Duration=3})
task.wait(1)
sub()
end
end})
T1:Section({Title="界面配色"})
for i=1,#th do
local n=th[i]
T1:Button({Title=n,Callback=function()
pcall(function()W:SetTheme(n)end)
N({Title="主题",Content=n,Duration=1})
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
local c=L.Character
if not c then return end
for _,v in pairs(c:GetDescendants())do
if v:IsA("BasePart")then
if s then
if v.CanCollide==true then pc[v]=true end
v.CanCollide=false
elseif pc[v]then
v.CanCollide=true
end
end
end
if not s then pc={}end
N({Title="穿墙",Content=s and"已开启"or"已关闭",Duration=1})
end})
T2:Toggle({Title="透视",Value=false,Callback=function(s)
local cg=game:GetService("CoreGui")
if s then
for _,v in pairs(P:GetPlayers())do
if v~=L and v.Character then
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
for _,h in pairs(cg:GetChildren())do
if h:IsA("Highlight")then pcall(function()h:Destroy()end)end
end
end
N({Title="透视",Content=s and"已开启"or"已关闭",Duration=1})
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
pcall(function()loadstring(game:HttpGet(S.."EspUser.lua"))()end)
else
pcall(function()getgenv().BabyClear()end)
end
end})
T4:Toggle({Title="头顶名字标签",Value=false,Callback=function(v)
if v then
pcall(function()loadstring(game:HttpGet(S.."TagUser.lua"))()end)
getgenv().BabyTagOn=true
N({Title="头顶名字标签",Content="只给名单里的人显示",Duration=3})
else
getgenv().BabyTagOn=false
if getgenv().BabyTagClean then
pcall(getgenv().BabyTagClean)
else
for _,o in ipairs(P:GetPlayers())do
local c=o.Character
local hd=c and c:FindFirstChild("Head")
local b=hd and hd:FindFirstChild("BabyNameTag")
if b then pcall(function()b:Destroy()end)end
end
end
end
end})
T4:Toggle({Title="脚本用户检测",Value=false,Callback=function(v)
if not v then getgenv().BabyDetect=false return end
N({Title="脚本用户检测",Content="开发中，暂未开放",Duration=3})
end})
T4:Input({Title="本局临时名单",Placeholder="@后面的英文名，逗号分隔",Value="",Callback=function(t)
getgenv().BabyExtra2=t
pcall(function()if getgenv().BabyRescan then getgenv().BabyRescan()end end)
end})
T4:Button({Title="查看当前名单",Callback=function()
local l={}
pcall(function()if getgenv().BabyList then l=getgenv().BabyList()end end)
if #l==0 then
N({Title="当前名单",Content="暂无名字",Duration=3})
else
N({Title="当前名单",Content=table.concat(l,"，"),Duration=5})
end
end})
T4:Button({Title="复制QQ号",Callback=function()
pcall(function()setclipboard("3492202561")end)
N({Title="QQ号",Content="3492202561 已复制",Duration=2})
end})
T5=Win:Tab({Title="脚本库",Icon="list",Locked=true})
T5:Section({Title="其他脚本"})
local nm={"造船寻宝","重型钓鱼","在末日中生存下来","偷一个蛋","森林中的99夜","试炼"}
local sel=nm[1]
T5:Dropdown({Title="选择脚本",Values=nm,Value=sel,Callback=function(v)sel=v end})
T5:Button({Title="使用",Callback=function()
for i=1,6 do
if nm[i]==sel then
N({Title="脚本库",Content="正在执行 "..sel,Duration=2})
local u=S..a[i]..".lua"
pcall(function()loadstring(game:HttpGet(u))()end)
return
end
end
N({Title="脚本库",Content="未知脚本",Duration=2})
end})
T5:Toggle({Title="进入游戏自动加载副脚本",Value=true,Callback=function(v)auto=v end})
if ok then
task.spawn(function()
if auto and PM[game.PlaceId]then sub()end
end)
end
L.CharacterAdded:Connect(function(c)
local h=c:WaitForChild("Humanoid",10)
if h then
task.wait(0.5)
h.WalkSpeed=sp
h.UseJumpPower=true
h.JumpPower=jp
end
end)
for _,x in ipairs({T2,T3,T4,T5})do x:LockAll() end
