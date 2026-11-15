-- ============================================================
-- BoatLib v4 · 接口适配层（分功能加载版）
-- 对外：完全兼容 Voltra 原来的 libtest 接口（mainmod 无需改动）
-- 对内：核心下载后控件**只排队不上屏**；复制船页每个功能一个按钮，
--       点哪个才渲染哪个页面（主菜单/图片/加载器/3D 模型/调整），
--       每页分批渲染（每 6 个控件让一帧），彻底避免卡死。
-- 对外暴露（给 Boat_v37 的按钮用）：
--   getgenv().BabyVoltraLoadPage("页面名")  渲染该页控件
--   getgenv().BabyVoltraQueues             各页排队表（存在=核心已下载）
-- 兼容清单（Voltra 实际用到的全部）：
--   library.new / 窗口:open / 窗口:new({text}) / 页签:show
--   页签:new("button|switch|slider|input|dropdown|label|folder", 属性)
--   选项.new(名) / 选项:Select() / 选项.object / 选项:Destroy()
--   文件夹.open()（点调用）/ 控件.event:Connect
-- ============================================================
local WindUI = loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua"))()

local function newSignal()
	local conns = {}
	local sig = {}
	function sig:Connect(fn)
		if type(fn) ~= "function" then return { Disconnect = function() end } end
		conns[#conns + 1] = fn
		return { Disconnect = function() end }
	end
	function sig:Fire(...)
		for _, f in ipairs(conns) do task.spawn(f, ...) end
	end
	return sig
end

-- 各页排队表 / 已渲染标记（核心重新下载时按页清空）
local QUEUES = getgenv().BabyVoltraQueues
if not QUEUES then QUEUES = {} getgenv().BabyVoltraQueues = QUEUES end
local FLUSHED = getgenv().BabyVoltraFlushed
if not FLUSHED then FLUSHED = {} getgenv().BabyVoltraFlushed = FLUSHED end

-- 独立窗口兜底（宿主页缺失时才创建）
local WIN

-- 把排队的一个控件真正渲染出来（绑定到排队时创建的 el 对象）
local function render(kind, o, el, target)
	o = o or {}
	kind = tostring(kind or "")

	if kind == "folder" then
		pcall(function() target:Section({ Title = o.text or "" }) end)
		return
	end

	if kind == "button" then
		pcall(function()
			target:Button({ Title = o.text or "按钮", Callback = function() el.event:Fire() end })
		end)
		return
	end

	if kind == "switch" then
		pcall(function()
			target:Toggle({
				Title = o.text or "开关",
				Value = el.on,
				Callback = function(v) el.on = v el.event:Fire(v) end,
			})
		end)
		return
	end

	if kind == "slider" then
		pcall(function()
			target:Slider({
				Title = o.text or "滑条",
				Value = { Min = o.min or 0, Max = o.max or 100, Default = o.value or o.min or 0 },
				Callback = function(v) el.value = v el.event:Fire(v) end,
			})
		end)
		return
	end

	if kind == "input" then
		pcall(function()
			target:Input({
				Title = o.text or "输入",
				Placeholder = o.placeholder or "",
				Value = o.value or "",
				Callback = function(t) el.event:Fire(t) end,
			})
		end)
		return
	end

	if kind == "dropdown" then
		pcall(function()
			el._wd = target:Dropdown({
				Title = o.text or "选择",
				Values = el.values,
				AllowNull = true,
				Callback = function(name) el.event:Fire(name) end,
			})
		end)
		return
	end

	if kind == "label" then
		pcall(function()
			el._para = target:Paragraph({ Title = o.text or "", Desc = "" })
		end)
		return
	end

	if kind == "spacer" or kind == "separator" then
		pcall(function() target:Divider() end)
		return
	end

	pcall(function() target:Paragraph({ Title = o.text or kind, Desc = "" }) end)
end

local library = {}

function library.new(cfg)
	local win = {}
	local host = getgenv().BabyVoltraHostTab

	if not host then
		if not WIN then
			pcall(function()
				WIN = WindUI:CreateWindow({
					Title = (cfg and cfg.text) or "Voltra 自动建造",
					Icon = "hammer",
					Size = UDim2.fromOffset(400, 580),
					Theme = "Dark",
					Folder = "VoltraAutoBuild",
				})
			end)
			if not WIN then
				WIN = WindUI:CreateWindow({ Title = (cfg and cfg.text) or "Voltra 自动建造" })
			end
		end
		if WIN and WIN.SetTheme then pcall(function() WIN:SetTheme("Dark") end) end
	end

	function win.open()
		if not host and WIN and WIN.Toggle then pcall(function() WIN:Toggle(true) end) end
	end

	function win.new(tabCfg)
		local title = (tabCfg and tabCfg.text) or "Main"
		-- 每次核心重新下载都按页重置队列
		QUEUES[title] = {}
		FLUSHED[title] = nil

		local tab = {}
		function tab.show() end

		function tab.new(kind, o)
			o = o or {}
			kind = tostring(kind or "")
			if kind == "textbox" then kind = "input" end
			if kind == "checkbox" then kind = "switch" end
			if kind == "number" then kind = "slider" end

			local el = { event = newSignal() }

			if kind == "folder" then
				-- 文件夹=分区标题；子控件按顺序排在后面
				local item = { kind = "folder", o = o }
				if FLUSHED[title] then
					pcall(function() (host or WIN):Section({ Title = o.text or "" }) end)
				else
					QUEUES[title][#QUEUES[title] + 1] = item
				end
				local folder = {}
				function folder.new(k2, o2) return tab.new(k2, o2) end
				folder.event = newSignal()
				folder.open = function() end
				folder.close = function() end
				folder.toggle = function() end
				function folder:Destroy() end
				return folder
			end

			-- 控件对象先行创建（回调此刻就已挂上），渲染延后
			if kind == "switch" then el.on = o.on and true or false end
			if kind == "slider" then el.value = o.value or o.min or 0 end
			if kind == "dropdown" then
				el.values = {}
				function el.new(name)
					el.values[#el.values + 1] = tostring(name)
					local wd = el._wd
					if wd and wd.Refresh then pcall(function() wd:Refresh(el.values) end) end
					local opt = {}
					local dummy = Instance.new("Folder")
					dummy.Name = "VoltraOpt_" .. tostring(name)
					opt.object = dummy
					function opt:Select()
						local w = el._wd
						if w and w.Select then pcall(function() w:Select(tostring(name)) end) end
						el.event:Fire(tostring(name))
					end
					function opt:Destroy()
						for i, v in ipairs(el.values) do
							if v == tostring(name) then table.remove(el.values, i) break end
						end
						local w = el._wd
						if w and w.Refresh then pcall(function() w:Refresh(el.values) end) end
						pcall(function() dummy:Destroy() end)
					end
					return opt
				end
			end
			if kind == "label" then
				function el.Set(t)
					local para = el._para
					if para and para.SetTitle then pcall(function() para:SetTitle(tostring(t)) end) end
				end
			end

			if FLUSHED[title] then
				-- 页面已渲染过（如刷新文件列表时新增的控件）：立即渲染
				pcall(function() render(kind, o, el, host or WIN) end)
			else
				QUEUES[title][#QUEUES[title] + 1] = { kind = kind, o = o, el = el }
			end

			function el:Destroy() end
			return el
		end

		return tab
	end

	return win
end

-- 供复制船页的功能按钮调用：渲染指定页（分批渲染防卡）
getgenv().BabyVoltraLoadPage = function(title)
	local q = QUEUES[title]
	local target = getgenv().BabyVoltraHostTab or WIN
	if not q then
		pcall(function()
			WindUI:Notify({ Title = "复制船", Content = "核心还没下载：先点「点我下载复制船核心」", Duration = 6 })
		end)
		return false
	end
	if FLUSHED[title] then
		pcall(function()
			WindUI:Notify({ Title = "复制船", Content = "「" .. title .. "」已经加载过了", Duration = 5 })
		end)
		return true
	end
	FLUSHED[title] = true
	task.spawn(function()
		if target and target.Section then
			pcall(function() target:Section({ Title = "── " .. title .. " ──" }) end)
		end
		local n = #q
		for i, item in ipairs(q) do
			pcall(function() render(item.kind, item.o, item.el, target) end)
			if i % 6 == 0 then task.wait() end
		end
		pcall(function()
			WindUI:Notify({ Title = "复制船", Content = "「" .. title .. "」加载完成（" .. n .. " 个控件）", Duration = 5 })
		end)
	end)
	return true
end

return library
