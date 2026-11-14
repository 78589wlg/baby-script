-- ============================================================
-- BoatLib v2 · 接口适配层
-- 对外：完全兼容 Voltra 原来的 libtest 接口（mainmod 无需改动）
-- 对内：全部渲染到主脚本同款 WindUI（手机可拖动、界面风格与婴儿脚本一致）
-- 适配的接口（Voltra 实际用到的全部）：
--   library.new(窗口配置) -> 窗口对象
--   窗口:open()           打开窗口
--   窗口:new({text=页名}) -> 页签对象
--   页签:show()           切到该页
--   页签:new("类型", 属性) -> 控件对象
--     button  {text}                        -> event:Fire()
--     switch  {text, on}                    -> event:Fire(布尔)
--     slider  {text, min, max, value}       -> event:Fire(数值)
--     input   {text, placeholder}           -> event:Fire(文本)
--     dropdown{text}                        -> event:Fire(选项名)
--       选项.new(名字) / 选项.object / 选项:Destroy()
--     label   {text}                        -> 段落
--     folder  {text}                        -> 分区标题，子控件平铺在页内
--     兼容兜底：textbox->input、checkbox->switch、number->slider、
--               spacer/separator->分隔、其余->段落
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

-- 重复加载（用户点「重新加载网上源码」）时复用同一个窗口，避免页签堆积
local WIN, TABMAP
TABMAP = getgenv().BabyVoltraTabs
if not TABMAP then
	TABMAP = setmetatable({}, { __mode = "v" })
	getgenv().BabyVoltraTabs = TABMAP
end

local library = {}

function library.new(cfg)
	local win = {}

	if not WIN then
		local ok = pcall(function()
			WIN = WindUI:CreateWindow({
				Title = (cfg and cfg.text) or "Voltra 自动建造",
				Icon = "hammer",
				Size = UDim2.fromOffset(400, 580),
				Theme = "Dark",
				Folder = "VoltraAutoBuild",
			})
			pcall(function() WIN:SetTheme("Dark") end)
		end)
		if not ok or not WIN then
			-- 极端兜底：最小配置再建一次
			WIN = WindUI:CreateWindow({ Title = (cfg and cfg.text) or "Voltra 自动建造" })
		end
	end
	if WIN and WIN.SetTheme then pcall(function() WIN:SetTheme("Dark") end) end

	function win.open()
		if WIN and WIN.Toggle then pcall(function() WIN:Toggle() end) end
	end

	function win.new(tabCfg)
		local title = (tabCfg and tabCfg.text) or "Main"
		local wtab = TABMAP[title]
		if not wtab then
			wtab = WIN:Tab({ Title = title, Icon = "hammer" })
			TABMAP[title] = wtab
		end

		local tab = {}

		function tab.show()
			if wtab and wtab.Select then pcall(function() wtab:Select() end) end
		end

		-- 控件创建：wtab 是 WindUI 的页签对象
		function tab.new(kind, o)
			o = o or {}
			local el = { event = newSignal() }
			kind = tostring(kind or "")

			-- folder -> 分区标题；子控件平铺在当前页
			if kind == "folder" then
				pcall(function() wtab:Section({ Title = o.text or "" }) end)
				local folder = {}
				function folder.new(k2, o2)
					return tab.new(k2, o2)
				end
				folder.event = newSignal()
				function folder:Destroy() end
				return folder
			end

			-- 兼容别名
			if kind == "textbox" then kind = "input" end
			if kind == "checkbox" then kind = "switch" end
			if kind == "number" then kind = "slider" end

			if kind == "button" then
				pcall(function()
					wtab:Button({
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
					wtab:Toggle({
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
					wtab:Slider({
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
					wtab:Input({
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
					wd = wtab:Dropdown({
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
					para = wtab:Paragraph({ Title = o.text or "", Desc = "" })
				end)
				function el.Set(t)
					if para and para.SetTitle then pcall(function() para:SetTitle(tostring(t)) end) end
				end
				function el:Destroy() end
				return el
			end

			if kind == "spacer" or kind == "separator" then
				pcall(function() wtab:Divider() end)
				function el:Destroy() end
				return el
			end

			-- 未知类型兜底：显示成段落，功能不受影响
			pcall(function()
				wtab:Paragraph({ Title = o.text or tostring(kind), Desc = "" })
			end)
			function el:Destroy() end
			return el
		end

		return tab
	end

	return win
end

return library
