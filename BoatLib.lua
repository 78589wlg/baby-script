-- ============================================================
-- BoatLib v3 · 接口适配层（嵌入版）
-- 对外：完全兼容 Voltra 原来的 libtest 接口（mainmod 无需改动）
-- 对内：不再弹出独立窗口！Voltra 的全部界面（主菜单/图片/加载器/
--       3D 模型/调整）直接渲染到造船寻宝脚本的「刷钱」页下方，
--       每个原页签变成一个分区标题，控件平铺在分区下面。
-- 适配的接口（Voltra 实际用到的全部）：
--   library.new(窗口配置) -> 窗口对象（open 为空操作）
--   窗口:new({text=页名}) -> 「页签」适配对象（实际是刷钱页上的一个分区）
--   页签:show()           空操作（都在同一页里）
--   页签:new("类型", 属性) -> 控件对象
--     button  {text}                        -> event:Fire()
--     switch  {text, on}                    -> event:Fire(布尔)
--     slider  {text, min, max, value}       -> event:Fire(数值)
--     input   {text, placeholder}           -> event:Fire(文本)
--     dropdown{text}                        -> event:Fire(选项名)
--       选项.new(名字) / 选项.object / 选项:Destroy()
--     label   {text}                        -> 段落
--     folder  {text}                        -> 小分区标题，子控件平铺在后面
--     兼容兜底：textbox->input、checkbox->switch、number->slider、
--               spacer/separator->分隔、其余->段落
-- 宿主：getgenv().BabyVoltraHostTab 必须先由 Boat_v37 设置为刷钱页；
--       没设置时兜底弹独立窗口（保证 Voltra 永远能用）。
-- ============================================================
local WindUI = loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua"))()

-- 小型信号器（对应 libtest 的 event 对象）
local function newSignal()
	local conns = {}
	local sig = {}
	function sig:Connect(fn)
		if type(fn) ~= "function" then return { Disconnect = function() end } end
		conns[#conns + 1] = fn
		return { Disconnect = function() end }
	end
	function sig:Fire(...)
		for _, f in ipairs(conns) do
			task.spawn(f, ...)
		end
	end
	return sig
end

-- 独立窗口兜底用（宿主页没设置时才创建）
local WIN
local library = {}

function library.new(cfg)
	local win = {}
	local host = getgenv().BabyVoltraHostTab   -- 刷钱页（Boat_v37 注入）

	if not host then
		-- 兜底：宿主缺失时弹独立窗口，功能不丢
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
		-- 嵌入模式下没有独立窗口要开；兜底窗口模式下保持打开
		if not host and WIN and WIN.Toggle then pcall(function() WIN:Toggle(true) end) end
	end

	-- Voltra 的每个「页签」= 刷钱页上的一个分区标题
	function win.new(tabCfg)
		local title = (tabCfg and tabCfg.text) or "Main"
		local target = host or WIN

		if host then
			pcall(function() host:Section({ Title = "── " .. title .. " ──" }) end)
		end

		local tab = {}

		function tab.show()
			-- 全部嵌入同一页，无需切换
		end

		-- 控件创建：渲染到 target（宿主页或兜底窗口）
		function tab.new(kind, o)
			o = o or {}
			local el = { event = newSignal() }
			kind = tostring(kind or "")

			-- folder -> 小分区标题；子控件平铺在后面
			if kind == "folder" then
				pcall(function() target:Section({ Title = o.text or "" }) end)
				local folder = {}
				function folder.new(k2, o2)
					return tab.new(k2, o2)
				end
				folder.event = newSignal()
				-- Voltra 会调用 folder.open()（点调用，展开分组）；WindUI 里内容常显，空操作即可
				folder.open = function() end
				folder.close = function() end
				folder.toggle = function() end
				function folder:Destroy() end
				return folder
			end

			-- 兼容别名
			if kind == "textbox" then kind = "input" end
			if kind == "checkbox" then kind = "switch" end
			if kind == "number" then kind = "slider" end

			if kind == "button" then
				pcall(function()
					target:Button({
						Title = o.text or "按钮",
						Callback = function() el.event:Fire() end,
					})
				end)
				function el:Destroy() end
				return el
			end

			if kind == "switch" then
				el.on = o.on and true or false
				pcall(function()
					target:Toggle({
						Title = o.text or "开关",
						Value = el.on,
						Callback = function(v)
							el.on = v
							el.event:Fire(v)
						end,
					})
				end)
				function el:Destroy() end
				return el
			end

			if kind == "slider" then
				el.value = o.value or o.min or 0
				pcall(function()
					target:Slider({
						Title = o.text or "滑条",
						Value = {
							Min = o.min or 0,
							Max = o.max or 100,
							Default = o.value or o.min or 0,
						},
						Callback = function(v)
							el.value = v
							el.event:Fire(v)
						end,
					})
				end)
				function el:Destroy() end
				return el
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
				function el:Destroy() end
				return el
			end

			if kind == "dropdown" then
				-- 动态选项：Voltra 会一个一个往里加（文件列表），用 Refresh 重建
				el.values = {}
				local wd
				pcall(function()
					wd = target:Dropdown({
						Title = o.text or "选择",
						Values = el.values,
						AllowNull = true,
						Callback = function(name) el.event:Fire(name) end,
					})
				end)
				function el.new(name)
					el.values[#el.values + 1] = tostring(name)
					if wd and wd.Refresh then pcall(function() wd:Refresh(el.values) end) end
					local opt = {}
					-- 兼容：Voltra 移除选项时把 object.Parent 置 nil 再 Destroy()
					local dummy = Instance.new("Folder")
					dummy.Name = "VoltraOpt_" .. tostring(name)
					opt.object = dummy
					-- Voltra 用 opt:Select() 设置默认选中（如队伍 "My Team"、速度 "Auto"），
					-- 必须同步触发 dropdown 的 event，否则对应变量是空，保存等功能失效
					function opt:Select()
						if wd and wd.Select then pcall(function() wd:Select(tostring(name)) end) end
						el.event:Fire(tostring(name))
					end
					function opt:Destroy()
						for i, v in ipairs(el.values) do
							if v == tostring(name) then table.remove(el.values, i) break end
						end
						if wd and wd.Refresh then pcall(function() wd:Refresh(el.values) end) end
						pcall(function() dummy:Destroy() end)
					end
					return opt
				end
				function el:Destroy() end
				return el
			end

			if kind == "label" then
				local para
				pcall(function()
					para = target:Paragraph({ Title = o.text or "", Desc = "" })
				end)
				function el.Set(t)
					if para and para.SetTitle then pcall(function() para:SetTitle(tostring(t)) end) end
				end
				function el:Destroy() end
				return el
			end

			if kind == "spacer" or kind == "separator" then
				pcall(function() target:Divider() end)
				function el:Destroy() end
				return el
			end

			-- 未知类型兜底：显示成段落，功能不受影响
			pcall(function()
				target:Paragraph({ Title = o.text or tostring(kind), Desc = "" })
			end)
			function el:Destroy() end
			return el
		end

		return tab
	end

	return win
end

return library
