-- 开发者功能（独立副脚本）
local WindUI=loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua"))()
local P=game:GetService("Players")
local LP=P.LocalPlayer

local DEVKEY="婴儿nb-作者-VIP8888"
local DFILE="BabyDev.txt"
local LFILE="BabyDevKeys.txt"
local KSH="https://ae1580126123eca19.app.workbuddy.host"
local KSS="WGTNFAERQB"
local HSK=game:GetService("HttpService")

local function ksPost(ep,body)
local url=KSH.."/"..ep.."?sharecode="..KSS
local payload=HSK:JSONEncode(body)
local res=nil
local ok1=pcall(function()res=game:HttpPost(url,payload,"application/json")end)
if not ok1 or type(res)~="string" then
local f=request
if not f then f=http_request end
if not f and syn and syn.request then f=syn.request end
if f then
local ok2=pcall(function()
local r=f({Url=url,Method="POST",Body=payload,Headers={["Content-Type"]="application/json"}})
res=type(r)=="table" and (r.Body or r.body) or r
end)
else
return false,"执行器不支持网络请求"
end
end
if type(res)~="string" or #res<3 then return false,"接口无响应" end
local okd,d=pcall(function()return HSK:JSONDecode(res)end)
if not okd or type(d)~="table" then return false,"接口返回异常" end
if not d.ok then return false,tostring(d.msg or "失败") end
if d["local"] then return true,tostring(d.msg or "").."（GitHub 未同步）" end
return true,tostring(d.msg or "已同步到云端")
end

local function ktrim(x)return (tostring(x):gsub("^%s+",""):gsub("%s+$",""))end
local function today()local o,d=pcall(function()return os.date("%Y-%m-%d")end)return o and d or "1970-01-01"end
local function expok(e)
if not e or e=="" or e=="永久" then return true,"永久" end
local d=tostring(e):gsub("[^%d]","")
if #d==8 then d=d:sub(1,4).."-"..d:sub(5,6).."-"..d:sub(7,8)end
if d<today() then return false,d end
return true,d
end
local function rmf(f)
pcall(function()if delfile then delfile(f)return end end)
pcall(function()if writefile and isfile and isfile(f)then writefile(f,"")end end)
end
local function loadList()
local t={}
local o,f=pcall(function()return readfile(LFILE)end)
if o and type(f)=="string" then
for line in f:gmatch("[^\r\n]+")do
local kk,ee=line:match("^([^,]+),?(.*)$")
if kk and ktrim(kk)~="" then t[ktrim(kk)]=ktrim(ee or "") end
end
end
return t
end
local function saveList(t)
local arr={}
for kk,ee in pairs(t)do arr[#arr+1]=kk..","..ee end
table.sort(arr)
pcall(function()if writefile then writefile(LFILE,table.concat(arr,"\n"))end end)
end
local function unlocked()
if getgenv().babyDevOK then return true end
local o,f=pcall(function()return readfile(DFILE)end)
if o and type(f)=="string" and ktrim(f)==DEVKEY then return true end
return false
end

local Win=WindUI:CreateWindow({Title="开发者功能"})
local T=Win:Tab({Title="卡密管理",Icon="key"})
local built=false

local function build()
if built then return end
built=true
local nk,ne="",""
T:Section({Title="本地卡密管理（仅对本设备生效）"})
T:Input({Title="卡密",Placeholder="要设置或删除的卡密",Value="",Callback=function(t)nk=ktrim(t)end})
T:Input({Title="有效期（YYYYMMDD，留空=永久）",Placeholder="如 20261231 或 永久",Value="",Callback=function(t)ne=ktrim(t)end})
T:Button({Title="设置卡密（新增或覆盖，可改时间）",Callback=function()
if nk=="" then
WindUI:Notify({Title="开发者",Content="请先在「卡密」框里填卡密",Duration=4})
return
end
if ne~="" and ne~="永久" then
local okk=expok(ne)
if not okk then
WindUI:Notify({Title="开发者",Content="该日期已过期，请填未来的日期",Duration=4})
return
end
end
local lst=loadList()
lst[nk]=ne
saveList(lst)
local okc,msg=ksPost("setkey",{dev=DEVKEY,k=nk,e=ne})
local show=ne=="" and "永久" or ne
WindUI:Notify({Title="开发者",Content="已设置："..nk.."（"..show.."）｜"..msg,Duration=7})
end})
T:Button({Title="删除该卡密",Callback=function()
if nk=="" then
WindUI:Notify({Title="开发者",Content="请先在「卡密」框里填卡密",Duration=4})
return
end
local lst=loadList()
if lst[nk]==nil then
WindUI:Notify({Title="开发者",Content="本地名单里没有这个卡密",Duration=4})
return
end
lst[nk]=nil
saveList(lst)
local okc,msg=ksPost("delkey",{dev=DEVKEY,k=nk})
WindUI:Notify({Title="开发者",Content="已删除："..nk.."｜"..msg,Duration=6})
end})
T:Button({Title="查看本地卡密列表",Callback=function()
local lst=loadList()
local n=0
local lines={}
for kk,ee in pairs(lst)do
n=n+1
if n<=8 then lines[#lines+1]=kk.."（"..(ee=="" and "永久" or ee).."）" end
end
if n==0 then
WindUI:Notify({Title="本地卡密",Content="空的，还没设置过",Duration=4})
else
table.sort(lines)
if n>8 then lines[#lines+1]="…还有 "..(n-8).." 个" end
WindUI:Notify({Title="本地卡密 "..n.." 个",Content=table.concat(lines," / "),Duration=8})
end
end})
T:Button({Title="从云端拉取名单（合并到本地）",Callback=function()
local okr,txt=pcall(function()return game:HttpGet(KSH.."/devkeys?sharecode="..KSS.."&t="..tostring(os.time()))end)
if not okr or type(txt)~="string" then
WindUI:Notify({Title="开发者",Content="云端拉取失败，检查网络",Duration=5})
return
end
local lst=loadList()
local n=0
for line in txt:gmatch("[^\r\n]+")do
local kk,ee=line:match("^([^,]+),?(.*)$")
if kk and ktrim(kk)~="" then
lst[ktrim(kk)]=ktrim(ee or "")
n=n+1
end
end
saveList(lst)
WindUI:Notify({Title="开发者",Content="已合并云端 "..n.." 个卡密到本地",Duration=5})
end})
T:Button({Title="清空本地卡密列表",Callback=function()
rmf(LFILE)
WindUI:Notify({Title="开发者",Content="本地列表已清空（云端名单不受影响）",Duration=5})
end})
T:Section({Title="清除"})
T:Button({Title="去除所有人的卡密（清除本机全部保存）",Callback=function()
rmf("BabyKey.txt")
rmf("BoatCopy/key.txt")
rmf("BoatCopy/ok.txt")
getgenv().babyKey=nil
WindUI:Notify({Title="开发者",Content="已清除本机保存的全部卡密，重开脚本生效",Duration=6})
end})
T:Button({Title="清空云端名单（所有人设置过的卡密失效）",Callback=function()
local okc,msg=ksPost("clear",{dev=DEVKEY})
rmf(LFILE)
WindUI:Notify({Title="开发者",Content="云端已清空｜"..msg,Duration=6})
end})
T:Section({Title="说明"})
T:Button({Title="本地名单对谁生效？（点我看）",Callback=function()
WindUI:Notify({Title="说明",Content="本地名单只对这台设备生效，别的设备要用，把卡密加进 GitHub 的 keys.txt 或由接口发",Duration=8})
end})
T:Button({Title="卡密时间格式？（点我看）",Callback=function()
WindUI:Notify({Title="说明",Content="8 位数字如 20261231，或直接写 永久，留空也是永久",Duration=6})
end})
end

if unlocked() then
build()
else
local dk=""
T:Section({Title="开发者验证"})
T:Input({Title="开发者卡密",Placeholder="请输入开发者专用卡密",Value="",Callback=function(t)dk=ktrim(t)end})
T:Button({Title="验证并解锁开发者功能",Callback=function()
if ktrim(dk)~=DEVKEY then
WindUI:Notify({Title="开发者",Content="卡密不对",Duration=4})
return
end
pcall(function()if writefile then writefile(DFILE,DEVKEY)end end)
getgenv().babyDevOK=true
WindUI:Notify({Title="开发者",Content="验证通过，开发者功能已解锁",Duration=4})
build()
end})
end
