--[[
	MiniUI.lua  v1.0.0
	Compact UI library for Roblox Luau (made for Android executors, works on desktop too).
	Style: Fluent UI + Orion. Pure Instance.new, no external assets, no file saving.

	API summary
	-----------
	local UI = loadstring(readfile("MiniUI.lua"))()
	local Window = UI:CreateWindow({ Title, Size, Position, ToggleKey, Scale, Bubble, CloseDestroys, OnClose, OnDestroy })
	  Window:CreateTab(name) -> Tab
	  Window:SelectTab(tab|index|name)  Window:Show() Hide() Toggle() IsVisible()
	  Window:SetTitle(t)  Window:SetScale(n)  Window:Notify(cfg)  Window:Destroy()  Window:IsDestroyed()
	UI:Notify({ Title, Content, Duration, Type })   Type: Info | Success | Warning | Error
	UI:Destroy()   -- destroys every window + notifications

	Tab / Section / Collapsible all share these constructors:
	  CreateSection, CreateLabel, CreateParagraph, CreateDivider, CreateButton, CreateToggle,
	  CreateCheckbox, CreateSlider, CreateInput, CreateTextbox, CreateDropdown, CreateMultiDropdown,
	  CreateRadioGroup, CreateKeybind, CreateColorPicker, CreateProgressBar, CreateCounter,
	  CreateKeyValue, CreateSearchBox, CreateItemList, CreateDataTable, CreateCollapsible, CreateConsole

	Conventions
	  * Every element returns an object with :Set(value, silent) / :Get() (where it makes sense),
	    :SetVisible(bool), :SetCallback(fn), :Destroy().
	  * Callbacks fire on user interaction and on :Set() (unless silent == true).
	    The Default value never fires the callback unless you pass FireOnCreate = true.
	  * Invalid defaults are handled: numbers are clamped, Dropdown/Radio ignore unknown defaults.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Library = {}
Library.Version = "1.0.0"
Library.Debug = false -- true = errors inside constructors are thrown instead of warned
Library._windows = {}

Library.Theme = {
	Background = Color3.fromRGB(16, 16, 22),
	Topbar = Color3.fromRGB(22, 22, 30),
	Surface = Color3.fromRGB(24, 24, 32),
	Element = Color3.fromRGB(32, 32, 42),
	ElementHover = Color3.fromRGB(40, 40, 52),
	ElementPress = Color3.fromRGB(26, 26, 34),
	Stroke = Color3.fromRGB(52, 52, 68),
	Accent = Color3.fromRGB(86, 140, 255),
	Text = Color3.fromRGB(236, 236, 246),
	SubText = Color3.fromRGB(150, 150, 172),
	Success = Color3.fromRGB(70, 200, 120),
	Warning = Color3.fromRGB(240, 185, 60),
	Danger = Color3.fromRGB(235, 85, 95),
	Font = Enum.Font.GothamMedium,
	FontBold = Enum.Font.GothamBold,
	TextSize = 13,
}

-- Change colors/fonts BEFORE creating a window.
function Library:SetTheme(overrides)
	if type(overrides) == "table" then
		for k, v in pairs(overrides) do
			Library.Theme[k] = v
		end
	end
end

----------------------------------------------------------------------
-- Utilities
----------------------------------------------------------------------

local XL, XC, XR = Enum.TextXAlignment.Left, Enum.TextXAlignment.Center, Enum.TextXAlignment.Right
local AUTO_Y, AUTO_X, AUTO_NONE = Enum.AutomaticSize.Y, Enum.AutomaticSize.X, Enum.AutomaticSize.None
local TRUNCATE = Enum.TextTruncate.AtEnd

local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_SLOW = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local Dead = setmetatable({}, {
	__index = function()
		return function() end
	end,
})

local function copyTable(t)
	local out = {}
	for k, v in pairs(t) do
		out[k] = v
	end
	return out
end

local function norm(cfg, key)
	if type(cfg) == "table" then
		return cfg
	end
	if cfg == nil then
		return {}
	end
	return { [key] = cfg }
end

local function isPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function shade(c, amount)
	if amount >= 0 then
		return c:Lerp(Color3.new(1, 1, 1), amount)
	end
	return c:Lerp(Color3.new(0, 0, 0), -amount)
end

local function to255(c)
	return math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)
end

local function toHex(c)
	local r, g, b = to255(c)
	return string.format("#%02X%02X%02X", r, g, b)
end

local function decimalsOf(n)
	local s = string.format("%.8f", n)
	s = s:gsub("0+$", "")
	local frac = s:match("%.(%d*)$")
	return frac and #frac or 0
end

local function escapeRich(s)
	s = s:gsub("&", "&amp;")
	s = s:gsub("<", "&lt;")
	s = s:gsub(">", "&gt;")
	return s
end

local function indexOf(list, value)
	for i, v in ipairs(list) do
		if v == value then
			return i
		end
	end
	return nil
end

local function tween(inst, props, info)
	if inst and inst.Parent then
		local t = TweenService:Create(inst, info or TWEEN_FAST, props)
		t:Play()
		return t
	end
	return nil
end

local function new(class, props)
	local inst = Instance.new(class)
	if inst:IsA("GuiObject") then
		inst.BorderSizePixel = 0
	end
	if inst:IsA("GuiButton") then
		inst.AutoButtonColor = false
	end
	if inst:IsA("TextButton") or inst:IsA("TextLabel") or inst:IsA("TextBox") then
		inst.Text = ""
	end
	local parent
	if props then
		for k, v in pairs(props) do
			if k == "Parent" then
				parent = v
			else
				inst[k] = v
			end
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function corner(parent, radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius), Parent = parent })
end

local function stroke(parent, color, thickness, transparency)
	return new("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function padding(parent, l, t, r, b)
	return new("UIPadding", {
		PaddingLeft = UDim.new(0, l or 0),
		PaddingTop = UDim.new(0, t or 0),
		PaddingRight = UDim.new(0, r or 0),
		PaddingBottom = UDim.new(0, b or 0),
		Parent = parent,
	})
end

local function listLayout(parent, pad, direction)
	return new("UIListLayout", {
		Padding = UDim.new(0, pad or 0),
		FillDirection = direction or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

local function textLabel(T, props)
	local p = {
		BackgroundTransparency = 1,
		Font = T.Font,
		TextSize = T.TextSize,
		TextColor3 = T.Text,
		TextXAlignment = XL,
		TextYAlignment = Enum.TextYAlignment.Center,
	}
	for k, v in pairs(props) do
		p[k] = v
	end
	return new("TextLabel", p)
end

local function fire(ctx, fn, ...)
	if type(fn) ~= "function" or ctx.Destroyed then
		return
	end
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[MiniUI] Callback error: " .. tostring(err))
	end
end

local function protectGui(gui)
	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(gui)
		end
	end)
end

local function resolveParent()
	if type(gethui) == "function" then
		local ok, h = pcall(gethui)
		if ok and typeof(h) == "Instance" then
			return h
		end
	end
	local ok, core = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok and core then
		local writable = pcall(function()
			local f = Instance.new("Folder")
			f.Parent = core
			f:Destroy()
			-- some executors can parent to CoreGui but not read it back
			core:FindFirstChild("__MiniUI_Probe")
		end)
		if writable then
			return core
		end
	end
	local lp = Players.LocalPlayer
	if lp then
		return lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 5)
	end
	return nil
end

local function getRegistry()
	local ok, env = pcall(function()
		return getgenv and getgenv() or nil
	end)
	if ok and type(env) == "table" then
		env.__MiniUI_Registry = env.__MiniUI_Registry or {}
		return env.__MiniUI_Registry
	end
	return nil
end

local function makeScreenGui(name, order)
	local gui = new("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = order,
		IgnoreGuiInset = true,
	})
	pcall(function()
		gui.ScreenInsets = Enum.ScreenInsets.None
	end)
	protectGui(gui)
	return gui
end

----------------------------------------------------------------------
-- Maid (connection / instance cleanup)
----------------------------------------------------------------------

local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({ _tasks = {}, _dead = false }, Maid)
end

local function cleanItem(item)
	local t = typeof(item)
	if t == "RBXScriptConnection" then
		item:Disconnect()
	elseif t == "Instance" then
		item:Destroy()
	elseif t == "function" then
		pcall(item)
	elseif t == "table" then
		local f = item.Destroy or item.Cleanup
		if f then
			pcall(f, item)
		end
	end
end

function Maid:Add(item)
	if self._dead then
		cleanItem(item)
		return item
	end
	self._tasks[#self._tasks + 1] = item
	return item
end

function Maid:Cleanup()
	local tasks = self._tasks
	self._tasks = {}
	for i = #tasks, 1, -1 do
		cleanItem(tasks[i])
	end
end

function Maid:Destroy()
	self._dead = true
	self:Cleanup()
end

----------------------------------------------------------------------
-- Interaction helpers
----------------------------------------------------------------------

-- colors: {Normal, Hover, Press} or a function returning that table.
local function bindFeedback(maid, hit, target, colors)
	local hovering, pressing = false, false
	local function refresh()
		local c = type(colors) == "function" and colors() or colors
		local color = pressing and c.Press or (hovering and c.Hover or c.Normal)
		tween(target, { BackgroundColor3 = color }, TWEEN_FAST)
	end
	maid:Add(hit.MouseEnter:Connect(function()
		hovering = true
		refresh()
	end))
	maid:Add(hit.MouseLeave:Connect(function()
		hovering = false
		pressing = false
		refresh()
	end))
	maid:Add(hit.InputBegan:Connect(function(input)
		if isPress(input) then
			pressing = true
			refresh()
		end
	end))
	maid:Add(hit.InputEnded:Connect(function(input)
		if isPress(input) then
			pressing = false
			refresh()
		end
	end))
	return refresh
end

local function makeDraggable(maid, handle, target, gui, onTap)
	local dragInput, moved = nil, false
	local startMouse, startPos = Vector2.zero, Vector2.zero
	local current, goal = nil, nil
	local loop
	-- only tap-able handles (bubble) need a dead zone; the title bar follows the finger at once
	local THRESH = onTap and 6 or 0
	local SMOOTH = 32 -- higher = snappier, lower = floatier

	local function stopLoop()
		if loop then
			loop:Disconnect()
			loop = nil
		end
	end
	local function startLoop()
		if loop then
			return
		end
		loop = RunService.RenderStepped:Connect(function(dt)
			if not goal or not target.Parent then
				stopLoop()
				return
			end
			current = current:Lerp(goal, 1 - math.exp(-dt * SMOOTH))
			if (goal - current).Magnitude < 0.4 then
				current = goal
				if not dragInput then
					stopLoop()
				end
			end
			target.Position = UDim2.fromOffset(math.floor(current.X + 0.5), math.floor(current.Y + 0.5))
		end)
	end
	maid:Add(stopLoop)

	maid:Add(handle.InputBegan:Connect(function(input)
		if dragInput or not isPress(input) then
			return
		end
		dragInput = input
		moved = false
		startMouse = Vector2.new(input.Position.X, input.Position.Y)
		startPos = target.AbsolutePosition
		current = startPos
		goal = startPos
	end))
	maid:Add(UserInputService.InputChanged:Connect(function(input)
		if not dragInput then
			return
		end
		local t = input.UserInputType
		if t == Enum.UserInputType.Touch then
			if input ~= dragInput then
				return -- ignore other fingers
			end
		elseif t ~= Enum.UserInputType.MouseMovement then
			return
		end
		local p = Vector2.new(input.Position.X, input.Position.Y)
		if not moved then
			if (p - startMouse).Magnitude < THRESH then
				return
			end
			-- re-base so the window does not jump when the dead zone is crossed
			moved = true
			startMouse = p
			startPos = target.AbsolutePosition
			current = startPos
			startLoop()
			return
		end
		local d = p - startMouse
		local screen = gui.AbsoluteSize
		local size = target.AbsoluteSize
		goal = Vector2.new(
			math.clamp(startPos.X + d.X, 60 - size.X, screen.X - 60),
			math.clamp(startPos.Y + d.Y, 0, math.max(0, screen.Y - 40))
		)
	end))
	maid:Add(UserInputService.InputEnded:Connect(function(input)
		if not dragInput then
			return
		end
		local isSame
		if dragInput.UserInputType == Enum.UserInputType.Touch then
			isSame = input == dragInput
		else
			isSame = input.UserInputType == Enum.UserInputType.MouseButton1
		end
		if isSame then
			dragInput = nil
			if not moved and onTap then
				onTap()
			end
		end
	end))
end

-- A nested ScrollingFrame that has nothing to scroll must not swallow the page's touch drag.
local function autoToggleScroll(em, scroll)
	local function update()
		scroll.ScrollingEnabled = scroll.AbsoluteCanvasSize.Y > scroll.AbsoluteSize.Y + 1
	end
	em:Add(scroll:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(update))
	em:Add(scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(update))
	update()
end

-- run fn once on the next frame no matter how many times the scheduler is called
local function coalesce(obj, fn)
	local queued = false
	return function()
		if queued then
			return
		end
		queued = true
		task.defer(function()
			queued = false
			if not obj._dead then
				fn()
			end
		end)
	end
end

----------------------------------------------------------------------
-- Container (shared by Tab, Section, Collapsible)
----------------------------------------------------------------------

local Container = {}
local ContainerMT = { __index = Container }

function Container:_add(frame)
	self._order = self._order + 1
	frame.LayoutOrder = self._order
	frame.Parent = self._frame
	if self._onChild then
		self._onChild()
	end
	return frame
end

local function newMaid(ctx)
	local em = Maid.new()
	ctx.Maid:Add(em)
	return em
end

-- boxed element frame (rounded, stroke). height == nil -> auto height
local function baseElement(self, height, name, class)
	local ctx = self._ctx
	local T = ctx.Theme
	local em = newMaid(ctx)
	local props = {
		Name = name,
		BackgroundColor3 = T.Element,
		Size = UDim2.new(1, 0, 0, height or 0),
		AutomaticSize = height and AUTO_NONE or AUTO_Y,
	}
	local frame = new(class or "Frame", props)
	corner(frame, 8)
	stroke(frame, T.Stroke, 1, 0.5)
	self:_add(frame)
	em:Add(frame)
	return frame, em, T, ctx
end

-- adds common methods and returns an emit(...) function
local function bindHandle(ctx, obj, frame, em, cfg)
	obj.Frame = frame
	obj._cb = cfg and cfg.Callback
	em:Add(function()
		obj._dead = true
	end)
	function obj:SetVisible(v)
		frame.Visible = v ~= false
	end
	function obj:SetCallback(fn)
		obj._cb = fn
	end
	function obj:Destroy()
		em:Cleanup()
	end
	function obj:IsDestroyed()
		return obj._dead == true
	end
	return function(...)
		if not obj._dead then
			fire(ctx, obj._cb, ...)
		end
	end
end

local function titleOf(cfg, default)
	local t = cfg.Title or cfg.Text or cfg.Name
	if t == nil then
		return default or ""
	end
	return tostring(t)
end

----------------------------------------------------------------------
-- Shared building blocks: slider track + option list
----------------------------------------------------------------------

local function buildTrack(ctx, em, parent, o)
	local T = ctx.Theme
	local min, max, inc = o.Min, o.Max, o.Inc
	local decimals = decimalsOf(inc)
	local color = o.Color or T.Accent

	local hit = new("TextButton", {
		Name = "Track",
		BackgroundTransparency = 1,
		Position = o.Position,
		Size = o.Size,
		Parent = parent,
	})
	local bar = new("Frame", {
		BackgroundColor3 = Color3.fromRGB(52, 52, 68),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 0, 6),
		Parent = hit,
	})
	corner(bar, 3)
	local fill = new("Frame", { BackgroundColor3 = color, Size = UDim2.new(0, 0, 1, 0), Parent = bar })
	corner(fill, 3)
	local knob = new("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		Parent = bar,
	})
	corner(knob, 9)
	stroke(knob, color, 2, 0)

	local tr = { Hit = hit }
	local value = min
	local dragging = false

	local function snap(v)
		v = math.clamp(v, min, max)
		if inc > 0 then
			v = min + math.floor((v - min) / inc + 0.5) * inc
		end
		v = math.clamp(v, min, max)
		return tonumber(string.format("%." .. decimals .. "f", v))
	end

	local function render(animate)
		local a = (max > min) and (value - min) / (max - min) or 0
		if animate then
			tween(fill, { Size = UDim2.new(a, 0, 1, 0) }, TWEEN_FAST)
			tween(knob, { Position = UDim2.new(a, 0, 0.5, 0) }, TWEEN_FAST)
		else
			fill.Size = UDim2.new(a, 0, 1, 0)
			knob.Position = UDim2.new(a, 0, 0.5, 0)
		end
	end

	value = snap(tonumber(o.Default) or min)
	render(false)

	function tr.Set(v, silent)
		v = tonumber(v)
		if v == nil then
			return
		end
		v = snap(v)
		local changed = v ~= value
		value = v
		render(true)
		if changed and o.OnChange then
			o.OnChange(value, silent == true)
		end
	end

	function tr.Get()
		return value
	end

	local function fromInput(pos)
		local w = bar.AbsoluteSize.X
		local a = w > 0 and math.clamp((pos.X - bar.AbsolutePosition.X) / w, 0, 1) or 0
		local v = snap(min + a * (max - min))
		if v ~= value then
			value = v
			render(false)
			if o.OnChange then
				o.OnChange(value, false)
			end
		end
	end

	local pending, pendInput, pendStart = false, nil, Vector2.zero
	local function beginDrag()
		dragging = true
		pending = false
		ctx.LockScroll(true)
		tween(knob, { Size = UDim2.fromOffset(18, 18) }, TWEEN_FAST)
	end

	em:Add(hit.InputBegan:Connect(function(input)
		if not isPress(input) or dragging or pending then
			return
		end
		if input.UserInputType == Enum.UserInputType.Touch then
			-- wait to see if the finger goes sideways (slide) or up/down (scroll the page)
			pending = true
			pendInput = input
			pendStart = Vector2.new(input.Position.X, input.Position.Y)
		else
			beginDrag()
			fromInput(input.Position)
		end
	end))
	em:Add(UserInputService.InputChanged:Connect(function(input)
		local t = input.UserInputType
		if pending and t == Enum.UserInputType.Touch and input == pendInput then
			local d = Vector2.new(input.Position.X, input.Position.Y) - pendStart
			local ax, ay = math.abs(d.X), math.abs(d.Y)
			if ax > 4 and ax > ay then
				beginDrag()
				fromInput(input.Position)
			elseif ay > 8 then
				pending = false -- it is a page scroll, leave it alone
			end
			return
		end
		if dragging and (t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.Touch) then
			fromInput(input.Position)
		end
	end))
	em:Add(UserInputService.InputEnded:Connect(function(input)
		if pending and input == pendInput then
			pending = false
			fromInput(input.Position) -- plain tap on the track
			render(true)
			return
		end
		if dragging and isPress(input) then
			dragging = false
			ctx.LockScroll(false)
			tween(knob, { Size = UDim2.fromOffset(14, 14) }, TWEEN_FAST)
			render(true)
		end
	end))
	em:Add(function()
		pending = false
		if dragging then
			dragging = false
			ctx.LockScroll(false)
		end
	end)
	return tr
end

local function createOptionList(ctx, em, parent, o)
	local T = ctx.Theme
	local ROW_H, GAP = 28, 2
	local maxHeight = o.MaxHeight or 140
	local list = {}
	local rowMaid = Maid.new()
	em:Add(rowMaid)

	local scroll = new("ScrollingFrame", {
		Name = "Options",
		BackgroundColor3 = T.Surface,
		Size = UDim2.new(1, 0, 0, ROW_H + 6),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = AUTO_Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = T.Stroke,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		VerticalScrollBarInset = Enum.ScrollBarInset.None,
		LayoutOrder = o.LayoutOrder or 1,
		Parent = parent,
	})
	corner(scroll, 6)
	stroke(scroll, T.Stroke, 1, 0.6)
	padding(scroll, 3, 3, 3, 3)
	listLayout(scroll, GAP)
	autoToggleScroll(em, scroll)
	local empty = textLabel(T, {
		Name = "Empty",
		Text = o.EmptyText or "No options",
		TextColor3 = T.SubText,
		TextXAlignment = XC,
		Size = UDim2.new(1, 0, 0, ROW_H),
		LayoutOrder = 1000000,
		Visible = false,
		Parent = scroll,
	})

	local options, rows, sel, query = {}, {}, {}, ""

	local function updateHeight()
		local count = 0
		for _, r in ipairs(rows) do
			if r.Btn.Visible then
				count = count + 1
			end
		end
		empty.Visible = count == 0
		local shown = math.max(count, 1)
		local h = shown * ROW_H + (shown - 1) * GAP + 6
		scroll.Size = UDim2.new(1, 0, 0, math.min(h, maxHeight))
	end

	local function style(row)
		local on = sel[row.Value] == true
		row.Label.TextColor3 = on and T.Text or T.SubText
		if o.Multi then
			row.Mark.BackgroundColor3 = on and T.Accent or T.Element
		else
			row.Mark.Visible = on
		end
		row.refresh()
	end

	function list:SetFilter(q)
		query = (q == nil) and "" or string.lower(tostring(q))
		for _, r in ipairs(rows) do
			r.Btn.Visible = query == "" or string.find(r.Text, query, 1, true) ~= nil
		end
		updateHeight()
	end

	function list:SetSelected(set)
		sel = set or {}
		for _, r in ipairs(rows) do
			style(r)
		end
	end

	function list:SetOptions(newOptions)
		rowMaid:Cleanup()
		for _, r in ipairs(rows) do
			r.Btn:Destroy()
		end
		rows = {}
		options = {}
		if type(newOptions) == "table" then
			for _, v in ipairs(newOptions) do
				options[#options + 1] = v
			end
		end
		for i, v in ipairs(options) do
			local btn = new("TextButton", {
				Name = "Option",
				BackgroundColor3 = T.Surface,
				Size = UDim2.new(1, 0, 0, ROW_H),
				LayoutOrder = i,
				Parent = scroll,
			})
			corner(btn, 5)
			local label = textLabel(T, {
				Text = tostring(v),
				TextColor3 = T.SubText,
				TextTruncate = TRUNCATE,
				Position = UDim2.new(0, o.Multi and 10 or 12, 0, 0),
				Size = UDim2.new(1, -34, 1, 0),
				Parent = btn,
			})
			local mark
			if o.Multi then
				mark = new("Frame", {
					BackgroundColor3 = T.Element,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -8, 0.5, 0),
					Size = UDim2.fromOffset(14, 14),
					Parent = btn,
				})
				corner(mark, 4)
				stroke(mark, T.Stroke, 1, 0)
			else
				mark = new("Frame", {
					BackgroundColor3 = T.Accent,
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 2, 0.5, 0),
					Size = UDim2.new(0, 3, 0.6, 0),
					Visible = false,
					Parent = btn,
				})
				corner(mark, 2)
			end
			local row = { Btn = btn, Label = label, Mark = mark, Value = v, Text = string.lower(tostring(v)) }
			row.refresh = bindFeedback(rowMaid, btn, btn, function()
				local on = sel[v] == true
				local base = on and T.Surface:Lerp(T.Accent, 0.2) or T.Surface
				return { Normal = base, Hover = shade(base, 0.08), Press = shade(base, -0.12) }
			end)
			rowMaid:Add(btn.Activated:Connect(function()
				if o.OnPick then
					o.OnPick(v)
				end
			end))
			rows[i] = row
			style(row)
		end
		list:SetFilter(query)
	end

	function list:GetOptions()
		return options
	end

	list.Scroll = scroll
	list:SetOptions(o.Options or {})
	return list
end

----------------------------------------------------------------------
-- Elements: text & layout
----------------------------------------------------------------------

function Container:CreateSection(cfg)
	cfg = norm(cfg, "Title")
	local ctx = self._ctx
	local T = ctx.Theme
	local em = newMaid(ctx)
	local header = new("Frame", { Name = "SectionHeader", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24) })
	local lbl = textLabel(T, {
		Text = string.upper(titleOf(cfg, "Section")),
		Font = T.FontBold,
		TextSize = 11,
		TextColor3 = T.Accent,
		Position = UDim2.new(0, 4, 0, 0),
		Size = UDim2.new(1, -8, 1, -2),
		Parent = header,
	})
	new("Frame", {
		BackgroundColor3 = T.Stroke,
		BackgroundTransparency = 0.4,
		Position = UDim2.new(0, 4, 1, -1),
		Size = UDim2.new(1, -8, 0, 1),
		Parent = header,
	})
	local box = new("Frame", {
		Name = "SectionBody",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = AUTO_Y,
		Visible = false,
	})
	listLayout(box, 6)
	self:_add(header)
	self:_add(box)
	em:Add(header)
	em:Add(box)

	local sec = setmetatable({ _ctx = ctx, _frame = box, _order = 0 }, ContainerMT)
	sec._onChild = function()
		box.Visible = true
	end
	bindHandle(ctx, sec, box, em, cfg)
	function sec:SetVisible(v)
		header.Visible = v ~= false
		box.Visible = (v ~= false) and sec._order > 0
	end
	function sec:SetTitle(t)
		lbl.Text = string.upper(tostring(t))
	end
	return sec
end

function Container:CreateLabel(cfg)
	cfg = norm(cfg, "Text")
	local ctx = self._ctx
	local T = ctx.Theme
	local em = newMaid(ctx)
	local lbl = textLabel(T, {
		Name = "Label",
		Text = titleOf(cfg, ""),
		TextColor3 = cfg.Color or T.Text,
		TextWrapped = true,
		AutomaticSize = AUTO_Y,
		Size = UDim2.new(1, 0, 0, 0),
	})
	padding(lbl, 4, 3, 4, 3)
	self:_add(lbl)
	em:Add(lbl)
	local obj = {}
	bindHandle(ctx, obj, lbl, em, cfg)
	function obj:Set(text)
		lbl.Text = tostring(text)
	end
	function obj:Get()
		return lbl.Text
	end
	function obj:SetColor(c)
		lbl.TextColor3 = c
	end
	return obj
end

function Container:CreateParagraph(cfg)
	cfg = norm(cfg, "Content")
	local frame, em, T, ctx = baseElement(self, nil, "Paragraph")
	padding(frame, 10, 8, 10, 8)
	listLayout(frame, 3)
	local hasTitle = cfg.Title ~= nil and tostring(cfg.Title) ~= ""
	local titleLbl = textLabel(T, {
		Name = "Title",
		Text = tostring(cfg.Title or ""),
		Font = T.FontBold,
		TextWrapped = true,
		AutomaticSize = AUTO_Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = 1,
		Visible = hasTitle,
		Parent = frame,
	})
	local body = textLabel(T, {
		Name = "Content",
		Text = tostring(cfg.Content or cfg.Text or ""),
		TextColor3 = T.SubText,
		TextSize = 12,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		AutomaticSize = AUTO_Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = 2,
		Parent = frame,
	})
	local obj = {}
	bindHandle(ctx, obj, frame, em, cfg)
	function obj:SetTitle(t)
		titleLbl.Text = tostring(t or "")
		titleLbl.Visible = t ~= nil and tostring(t) ~= ""
	end
	function obj:SetContent(c)
		body.Text = tostring(c or "")
	end
	function obj:Set(content)
		obj:SetContent(content)
	end
	function obj:Get()
		return body.Text
	end
	return obj
end

function Container:CreateDivider(cfg)
	cfg = norm(cfg, "Title")
	local ctx = self._ctx
	local T = ctx.Theme
	local em = newMaid(ctx)
	local frame = new("Frame", { Name = "Divider", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 12) })
	new("Frame", {
		BackgroundColor3 = T.Stroke,
		BackgroundTransparency = 0.3,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 4, 0.5, 0),
		Size = UDim2.new(1, -8, 0, 1),
		Parent = frame,
	})
	local text = cfg.Title or cfg.Text
	if text and tostring(text) ~= "" then
		local lbl = textLabel(T, {
			Text = tostring(text),
			TextSize = 11,
			TextColor3 = T.SubText,
			BackgroundTransparency = 0,
			BackgroundColor3 = T.Background,
			AutomaticSize = AUTO_X,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 0, 1, 0),
			TextXAlignment = XC,
			Parent = frame,
		})
		padding(lbl, 6, 0, 6, 0)
	end
	self:_add(frame)
	em:Add(frame)
	local obj = {}
	bindHandle(ctx, obj, frame, em, cfg)
	return obj
end

----------------------------------------------------------------------
-- Elements: buttons & toggles
----------------------------------------------------------------------

function Container:CreateButton(cfg)
	cfg = norm(cfg, "Title")
	local btn, em, T, ctx = baseElement(self, 34, "Button", "TextButton")
	local primary = cfg.Style == "Primary" or cfg.Primary == true
	local normal = primary and T.Accent or T.Element
	btn.BackgroundColor3 = normal
	btn.Text = titleOf(cfg, "Button")
	btn.Font = T.Font
	btn.TextSize = T.TextSize
	btn.TextColor3 = primary and Color3.new(1, 1, 1) or T.Text
	local obj = {}
	local emit = bindHandle(ctx, obj, btn, em, cfg)
	local enabled = true
	bindFeedback(em, btn, btn, { Normal = normal, Hover = shade(normal, 0.08), Press = shade(normal, -0.15) })
	em:Add(btn.Activated:Connect(function()
		if enabled then
			emit()
		end
	end))
	function obj:SetTitle(t)
		btn.Text = tostring(t)
	end
	function obj:SetEnabled(v)
		enabled = v ~= false
		btn.TextTransparency = enabled and 0 or 0.5
	end
	function obj:Click()
		if enabled then
			emit()
		end
	end
	return obj
end

function Container:CreateToggle(cfg)
	cfg = norm(cfg, "Title")
	local row, em, T, ctx = baseElement(self, 34, "Toggle", "TextButton")
	local titleLbl = textLabel(T, {
		Text = titleOf(cfg, "Toggle"),
		TextTruncate = TRUNCATE,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -64, 1, 0),
		Parent = row,
	})
	local OFF = Color3.fromRGB(58, 58, 76)
	local track = new("Frame", {
		BackgroundColor3 = OFF,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(38, 20),
		Parent = row,
	})
	corner(track, 10)
	local knob = new("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		Parent = track,
	})
	corner(knob, 7)

	local value = cfg.Default == true
	local obj = {}
	local emit = bindHandle(ctx, obj, row, em, cfg)

	local function render(instant)
		local pos = UDim2.new(0, value and 21 or 3, 0.5, 0)
		local col = value and T.Accent or OFF
		if instant then
			knob.Position = pos
			track.BackgroundColor3 = col
		else
			tween(knob, { Position = pos })
			tween(track, { BackgroundColor3 = col })
		end
	end
	render(true)
	bindFeedback(em, row, row, { Normal = T.Element, Hover = T.ElementHover, Press = T.ElementPress })

	function obj:Set(v, silent)
		v = not not v
		if v == value then
			return
		end
		value = v
		render(false)
		if not silent then
			emit(value)
		end
	end
	function obj:Get()
		return value
	end
	function obj:Toggle()
		obj:Set(not value)
	end
	function obj:SetTitle(t)
		titleLbl.Text = tostring(t)
	end
	em:Add(row.Activated:Connect(function()
		obj:Set(not value)
	end))
	if cfg.FireOnCreate then
		emit(value)
	end
	return obj
end

function Container:CreateCheckbox(cfg)
	cfg = norm(cfg, "Title")
	local row, em, T, ctx = baseElement(self, 34, "Checkbox", "TextButton")
	local box = new("Frame", {
		BackgroundColor3 = T.Surface,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(18, 18),
		Parent = row,
	})
	corner(box, 5)
	local boxStroke = stroke(box, T.Stroke, 1.5, 0)
	-- check mark built from two rotated bars
	local white = Color3.new(1, 1, 1)
	local short = new("Frame", {
		BackgroundColor3 = white,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(6, 11),
		Size = UDim2.fromOffset(2, 5),
		Rotation = -45,
		Parent = box,
	})
	local long = new("Frame", {
		BackgroundColor3 = white,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(11, 9),
		Size = UDim2.fromOffset(2, 9),
		Rotation = 45,
		Parent = box,
	})
	local titleLbl = textLabel(T, {
		Text = titleOf(cfg, "Checkbox"),
		TextTruncate = TRUNCATE,
		Position = UDim2.new(0, 38, 0, 0),
		Size = UDim2.new(1, -48, 1, 0),
		Parent = row,
	})
	local value = cfg.Default == true
	local obj = {}
	local emit = bindHandle(ctx, obj, row, em, cfg)

	local function render(instant)
		local fillColor = value and T.Accent or T.Surface
		local strokeColor = value and T.Accent or T.Stroke
		local tr = value and 0 or 1
		if instant then
			box.BackgroundColor3 = fillColor
			boxStroke.Color = strokeColor
			short.BackgroundTransparency = tr
			long.BackgroundTransparency = tr
		else
			tween(box, { BackgroundColor3 = fillColor })
			tween(boxStroke, { Color = strokeColor })
			tween(short, { BackgroundTransparency = tr })
			tween(long, { BackgroundTransparency = tr })
		end
	end
	render(true)
	bindFeedback(em, row, row, { Normal = T.Element, Hover = T.ElementHover, Press = T.ElementPress })

	function obj:Set(v, silent)
		v = not not v
		if v == value then
			return
		end
		value = v
		render(false)
		if not silent then
			emit(value)
		end
	end
	function obj:Get()
		return value
	end
	function obj:Toggle()
		obj:Set(not value)
	end
	function obj:SetTitle(t)
		titleLbl.Text = tostring(t)
	end
	em:Add(row.Activated:Connect(function()
		obj:Set(not value)
	end))
	if cfg.FireOnCreate then
		emit(value)
	end
	return obj
end

----------------------------------------------------------------------
-- Elements: numeric
----------------------------------------------------------------------

function Container:CreateSlider(cfg)
	cfg = norm(cfg, "Title")
	local min = tonumber(cfg.Min) or 0
	local max = tonumber(cfg.Max) or 100
	if min > max then
		min, max = max, min
	end
	local inc = tonumber(cfg.Increment) or ((max - min) <= 1 and 0.01 or 1)
	if inc <= 0 then
		inc = 1
	end
	local frame, em, T, ctx = baseElement(self, 52, "Slider")
	local titleLbl = textLabel(T, {
		Text = titleOf(cfg, "Slider"),
		TextTruncate = TRUNCATE,
		Position = UDim2.new(0, 10, 0, 6),
		Size = UDim2.new(1, -90, 0, 18),
		Parent = frame,
	})
	local valueLbl = textLabel(T, {
		Text = "",
		TextColor3 = T.Accent,
		TextXAlignment = XR,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 6),
		Size = UDim2.new(0, 76, 0, 18),
		Parent = frame,
	})
	local suffix = cfg.Suffix and tostring(cfg.Suffix) or ""
	local obj = {}
	local emit = bindHandle(ctx, obj, frame, em, cfg)
	local track
	track = buildTrack(ctx, em, frame, {
		Min = min,
		Max = max,
		Inc = inc,
		Default = cfg.Default,
		Position = UDim2.new(0, 10, 0, 26),
		Size = UDim2.new(1, -20, 0, 22),
		OnChange = function(v, silent)
			valueLbl.Text = tostring(v) .. suffix
			if not silent then
				emit(v)
			end
		end,
	})
	valueLbl.Text = tostring(track.Get()) .. suffix
	function obj:Set(v, silent)
		track.Set(v, silent)
	end
	function obj:Get()
		return track.Get()
	end
	function obj:SetTitle(t)
		titleLbl.Text = tostring(t)
	end
	if cfg.FireOnCreate then
		emit(track.Get())
	end
	return obj
end

function Container:CreateCounter(cfg)
	cfg = norm(cfg, "Title")
	local frame, em, T, ctx = baseElement(self, 36, "Counter")
	local min = tonumber(cfg.Min) or -math.huge
	local max = tonumber(cfg.Max) or math.huge
	if min > max then
		min, max = max, min
	end
	local step = tonumber(cfg.Step) or tonumber(cfg.Increment) or 1
	if step <= 0 then
		step = 1
	end
	local decimals = decimalsOf(step)
	local value = math.clamp(tonumber(cfg.Default) or 0, min, max)

	local titleLbl = textLabel(T, {
		Text = titleOf(cfg, "Counter"),
		TextTruncate = TRUNCATE,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -126, 1, 0),
		Parent = frame,
	})
	local right = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.fromOffset(104, 26),
		Parent = frame,
	})
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = right,
	})
	local function makeBtn(text, order)
		local b = new("TextButton", {
			Text = text,
			Font = T.FontBold,
			TextSize = 16,
			TextColor3 = T.Text,
			BackgroundColor3 = T.Surface,
			Size = UDim2.fromOffset(26, 26),
			LayoutOrder = order,
			Parent = right,
		})
		corner(b, 6)
		stroke(b, T.Stroke, 1, 0.4)
		bindFeedback(em, b, b, { Normal = T.Surface, Hover = T.ElementHover, Press = T.ElementPress })
		return b
	end
	local minus = makeBtn("-", 1)
	local valueLbl = textLabel(T, { Text = "", TextXAlignment = XC, Size = UDim2.fromOffset(44, 26), LayoutOrder = 2, Parent = right })
	local plus = makeBtn("+", 3)

	local obj = {}
	local emit = bindHandle(ctx, obj, frame, em, cfg)

	local function render()
		valueLbl.Text = string.format("%." .. decimals .. "f", value)
		minus.TextTransparency = value <= min and 0.6 or 0
		plus.TextTransparency = value >= max and 0.6 or 0
	end
	render()

	local function setValue(v, silent)
		v = math.clamp(v, min, max)
		v = tonumber(string.format("%." .. decimals .. "f", v))
		if v == value then
			return
		end
		value = v
		render()
		if not silent then
			emit(value)
		end
	end

	-- tap = one step, hold = repeat
	local token = 0
	local function bindStep(btn, delta)
		local repeated = false
		em:Add(btn.InputBegan:Connect(function(input)
			if not isPress(input) then
				return
			end
			token = token + 1
			local my = token
			repeated = false
			task.spawn(function()
				task.wait(0.45)
				if token ~= my or obj._dead then
					return
				end
				repeated = true
				while token == my and not obj._dead do
					setValue(value + delta * step)
					task.wait(0.08)
				end
			end)
		end))
		em:Add(btn.Activated:Connect(function()
			if repeated then
				repeated = false
			else
				setValue(value + delta * step)
			end
		end))
	end
	bindStep(minus, -1)
	bindStep(plus, 1)
	em:Add(UserInputService.InputEnded:Connect(function(input)
		if isPress(input) then
			token = token + 1
		end
	end))

	function obj:Set(v, silent)
		v = tonumber(v)
		if v ~= nil then
			setValue(v, silent)
		end
	end
	function obj:Get()
		return value
	end
	function obj:SetTitle(t)
		titleLbl.Text = tostring(t)
	end
	if cfg.FireOnCreate then
		emit(value)
	end
	return obj
end

function Container:CreateProgressBar(cfg)
	cfg = norm(cfg, "Title")
	local frame, em, T, ctx = baseElement(self, 44, "ProgressBar")
	local min = tonumber(cfg.Min) or 0
	local max = tonumber(cfg.Max) or 100
	if min > max then
		min, max = max, min
	end
	local titleLbl = textLabel(T, {
		Text = titleOf(cfg, "Progress"),
		TextTruncate = TRUNCATE,
		Position = UDim2.new(0, 10, 0, 5),
		Size = UDim2.new(1, -90, 0, 18),
		Parent = frame,
	})
	local valueLbl = textLabel(T, {
		Text = "",
		TextColor3 = T.SubText,
		TextXAlignment = XR,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 5),
		Size = UDim2.new(0, 76, 0, 18),
		Parent = frame,
	})
	local bar = new("Frame", {
		BackgroundColor3 = Color3.fromRGB(52, 52, 68),
		Position = UDim2.new(0, 10, 0, 28),
		Size = UDim2.new(1, -20, 0, 8),
		Parent = frame,
	})
	corner(bar, 4)
	local fill = new("Frame", { BackgroundColor3 = cfg.Color or T.Accent, Size = UDim2.new(0, 0, 1, 0), Parent = bar })
	corner(fill, 4)

	local value = min
	local customText
	local obj = {}
	bindHandle(ctx, obj, frame, em, cfg)

	local function alpha()
		return (max > min) and math.clamp((value - min) / (max - min), 0, 1) or 0
	end
	local function render(instant)
		local a = alpha()
		if instant then
			fill.Size = UDim2.new(a, 0, 1, 0)
		else
			tween(fill, { Size = UDim2.new(a, 0, 1, 0) }, TWEEN_SLOW)
		end
		valueLbl.Text = customText or (tostring(math.floor(a * 100 + 0.5)) .. "%")
	end
	value = math.clamp(tonumber(cfg.Default or cfg.Value) or min, min, max)
	render(true)

	function obj:Set(v)
		v = tonumber(v)
		if v == nil then
			return
		end
		value = math.clamp(v, min, max)
		render(false)
	end
	function obj:Get()
		return value
	end
	function obj:SetText(t)
		customText = t ~= nil and tostring(t) or nil
		render(true)
	end
	function obj:SetColor(c)
		tween(fill, { BackgroundColor3 = c })
	end
	function obj:SetTitle(t)
		titleLbl.Text = tostring(t)
	end
	return obj
end

function Container:CreateKeyValue(cfg)
	cfg = norm(cfg, "Title")
	local frame, em, T, ctx = baseElement(self, 30, "KeyValue")
	local keyLbl = textLabel(T, {
		Text = titleOf(cfg, "Key"),
		TextColor3 = T.SubText,
		TextTruncate = TRUNCATE,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(0.45, -10, 1, 0),
		Parent = frame,
	})
	local valueLbl = textLabel(T, {
		Text = tostring(cfg.Value == nil and "" or cfg.Value),
		TextColor3 = cfg.Color or T.Text,
		TextXAlignment = XR,
		TextTruncate = TRUNCATE,
		Position = UDim2.new(0.45, 0, 0, 0),
		Size = UDim2.new(0.55, -10, 1, 0),
		Parent = frame,
	})
	local obj = {}
	bindHandle(ctx, obj, frame, em, cfg)
	function obj:Set(v)
		valueLbl.Text = tostring(v == nil and "" or v)
	end
	function obj:Get()
		return valueLbl.Text
	end
	function obj:SetTitle(t)
		keyLbl.Text = tostring(t)
	end
	function obj:SetColor(c)
		valueLbl.TextColor3 = c
	end
	return obj
end

----------------------------------------------------------------------
-- Elements: text input
----------------------------------------------------------------------

function Container:CreateInput(cfg)
	cfg = norm(cfg, "Title")
	local frame, em, T, ctx = baseElement(self, 36, "Input")
	local hasTitle = cfg.Title ~= nil and tostring(cfg.Title) ~= ""
	local titleLbl
	if hasTitle then
		titleLbl = textLabel(T, {
			Text = tostring(cfg.Title),
			TextTruncate = TRUNCATE,
			Position = UDim2.new(0, 10, 0, 0),
			Size = UDim2.new(0.4, -10, 1, 0),
			Parent = frame,
		})
	end
	local box = new("TextBox", {
		Name = "Box",
		BackgroundColor3 = T.Surface,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = hasTitle and UDim2.new(0.6, -10, 0, 26) or UDim2.new(1, -12, 0, 26),
		Font = T.Font,
		TextSize = T.TextSize,
		TextColor3 = T.Text,
		PlaceholderText = tostring(cfg.Placeholder or "Type here..."),
		PlaceholderColor3 = T.SubText,
		ClearTextOnFocus = false,
		TextXAlignment = XL,
		ClipsDescendants = true,
		Parent = frame,
	})
	corner(box, 6)
	local bs = stroke(box, T.Stroke, 1, 0.3)
	padding(box, 8, 0, 8, 0)

	local numeric = cfg.Numeric == true
	local maxLen = tonumber(cfg.MaxLength)
	local value
	if numeric then
		value = tonumber(cfg.Default)
		box.Text = value ~= nil and tostring(value) or ""
	else
		value = tostring(cfg.Default or "")
		box.Text = value
	end

	local obj = {}
	local emit = bindHandle(ctx, obj, frame, em, cfg)

	local function commit(enter)
		local text = box.Text
		if maxLen and #text > maxLen then
			text = string.sub(text, 1, maxLen)
		end
		local newValue = text
		if numeric then
			local n = tonumber(text)
			if n == nil then
				box.Text = value ~= nil and tostring(value) or ""
				return
			end
			if cfg.Min then
				n = math.max(n, cfg.Min)
			end
			if cfg.Max then
				n = math.min(n, cfg.Max)
			end
			newValue = n
			text = tostring(n)
		end
		box.Text = text
		local changed = newValue ~= value
		value = newValue
		if changed or enter then
			emit(value)
		end
	end

	em:Add(box.Focused:Connect(function()
		tween(bs, { Color = T.Accent })
	end))
	em:Add(box.FocusLost:Connect(function(enter)
		tween(bs, { Color = T.Stroke })
		commit(enter)
	end))

	function obj:Set(v, silent)
		if numeric then
			v = tonumber(v)
			if v == nil then
				return
			end
		else
			v = tostring(v == nil and "" or v)
		end
		local changed = v ~= value
		value = v
		box.Text = tostring(v)
		if changed and not silent then
			emit(value)
		end
	end
	function obj:Get()
		return value
	end
	function obj:SetPlaceholder(t)
		box.PlaceholderText = tostring(t)
	end
	function obj:SetTitle(t)
		if titleLbl then
			titleLbl.Text = tostring(t)
		end
	end
	function obj:Focus()
		box:CaptureFocus()
	end
	if cfg.FireOnCreate then
		emit(value)
	end
	return obj
end

function Container:CreateTextbox(cfg)
	cfg = norm(cfg, "Title")
	local boxHeight = math.clamp(tonumber(cfg.Height) or 90, 50, 300)
	local hasTitle = cfg.Title ~= nil and tostring(cfg.Title) ~= ""
	local titleH = hasTitle and 26 or 6
	local frame, em, T, ctx = baseElement(self, titleH + boxHeight + 8, "Textbox")
	local titleLbl
	if hasTitle then
		titleLbl = textLabel(T, {
			Text = tostring(cfg.Title),
			TextTruncate = TRUNCATE,
			Position = UDim2.new(0, 10, 0, 0),
			Size = UDim2.new(1, -20, 0, 26),
			Parent = frame,
		})
	end
	local box = new("TextBox", {
		Name = "Box",
		BackgroundColor3 = T.Surface,
		Position = UDim2.new(0, 8, 0, titleH),
		Size = UDim2.new(1, -16, 0, boxHeight),
		Font = T.Font,
		TextSize = 12,
		TextColor3 = T.Text,
		PlaceholderText = tostring(cfg.Placeholder or "Type here..."),
		PlaceholderColor3 = T.SubText,
		ClearTextOnFocus = false,
		MultiLine = true,
		TextWrapped = true,
		TextXAlignment = XL,
		TextYAlignment = Enum.TextYAlignment.Top,
		ClipsDescendants = true,
		Text = tostring(cfg.Default or ""),
		Parent = frame,
	})
	corner(box, 6)
	local bs = stroke(box, T.Stroke, 1, 0.3)
	padding(box, 8, 6, 8, 6)
	local value = box.Text
	local obj = {}
	local emit = bindHandle(ctx, obj, frame, em, cfg)
	em:Add(box.Focused:Connect(function()
		tween(bs, { Color = T.Accent })
	end))
	em:Add(box.FocusLost:Connect(function()
		tween(bs, { Color = T.Stroke })
		if box.Text ~= value then
			value = box.Text
			emit(value)
		end
	end))
	function obj:Set(v, silent)
		v = tostring(v == nil and "" or v)
		local changed = v ~= value
		value = v
		box.Text = v
		if changed and not silent then
			emit(value)
		end
	end
	function obj:Get()
		return value
	end
	function obj:SetTitle(t)
		if titleLbl then
			titleLbl.Text = tostring(t)
		end
	end
	function obj:Clear(silent)
		obj:Set("", silent)
	end
	if cfg.FireOnCreate then
		emit(value)
	end
	return obj
end

function Container:CreateSearchBox(cfg)
	cfg = norm(cfg, "Placeholder")
	local frame, em, T, ctx = baseElement(self, 36, "SearchBox")
	local box = new("TextBox", {
		Name = "Box",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, -30, 1, 0),
		Font = T.Font,
		TextSize = T.TextSize,
		TextColor3 = T.Text,
		PlaceholderText = tostring(cfg.Placeholder or "Search..."),
		PlaceholderColor3 = T.SubText,
		ClearTextOnFocus = false,
		TextXAlignment = XL,
		ClipsDescendants = true,
		Text = tostring(cfg.Default or ""),
		Parent = frame,
	})
	padding(box, 12, 0, 4, 0)
	local clearBtn = new("TextButton", {
		Text = "x",
		Font = T.FontBold,
		TextSize = 13,
		TextColor3 = T.SubText,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -4, 0.5, 0),
		Size = UDim2.fromOffset(26, 26),
		Visible = box.Text ~= "",
		Parent = frame,
	})
	local obj = {}
	local emit = bindHandle(ctx, obj, frame, em, cfg)
	local debounce = tonumber(cfg.Debounce) or 0.2
	local token = 0

	local function run(text)
		if obj._dead then
			return
		end
		if cfg.Target and type(cfg.Target.SetFilter) == "function" then
			pcall(cfg.Target.SetFilter, cfg.Target, text)
		end
		emit(text)
	end

	em:Add(box:GetPropertyChangedSignal("Text"):Connect(function()
		clearBtn.Visible = box.Text ~= ""
		token = token + 1
		local my = token
		task.delay(debounce, function()
			if token == my then
				run(box.Text)
			end
		end)
	end))
	em:Add(box.FocusLost:Connect(function(enter)
		if enter then
			token = token + 1
			run(box.Text)
		end
	end))
	em:Add(clearBtn.Activated:Connect(function()
		box.Text = ""
	end))
	local fs = stroke(frame, T.Accent, 1, 1)
	em:Add(box.Focused:Connect(function()
		tween(fs, { Transparency = 0.3 })
	end))
	em:Add(box.FocusLost:Connect(function()
		tween(fs, { Transparency = 1 })
	end))

	function obj:Get()
		return box.Text
	end
	function obj:Set(text)
		box.Text = tostring(text == nil and "" or text)
	end
	function obj:Clear()
		box.Text = ""
	end
	function obj:Focus()
		box:CaptureFocus()
	end
	return obj
end

----------------------------------------------------------------------
-- Elements: choice (Dropdown, MultiDropdown, RadioGroup, ItemList)
----------------------------------------------------------------------

local function sameSet(a, b)
	for k in pairs(a) do
		if not b[k] then
			return false
		end
	end
	for k in pairs(b) do
		if not a[k] then
			return false
		end
	end
	return true
end

local function createDropdown(self, cfg, multi)
	cfg = norm(cfg, "Title")
	local root, em, T, ctx = baseElement(self, nil, multi and "MultiDropdown" or "Dropdown")
	root.ClipsDescendants = true
	listLayout(root, 0)

	local header = new("TextButton", {
		Name = "Header",
		BackgroundColor3 = T.Element,
		Size = UDim2.new(1, 0, 0, 34),
		LayoutOrder = 1,
		Parent = root,
	})
	corner(header, 8)
	local titleLbl = textLabel(T, {
		Text = titleOf(cfg, multi and "Select options" or "Select option"),
		TextTruncate = TRUNCATE,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(0.4, -10, 1, 0),
		Parent = header,
	})
	local placeholder = tostring(cfg.Placeholder or (multi and "None" or "Select..."))
	local valueLbl = textLabel(T, {
		Text = placeholder,
		TextColor3 = T.SubText,
		TextXAlignment = XR,
		TextTruncate = TRUNCATE,
		Position = UDim2.new(0.4, 0, 0, 0),
		Size = UDim2.new(0.6, -34, 1, 0),
		Parent = header,
	})
	local chevron = textLabel(T, {
		Text = ">",
		Font = T.FontBold,
		TextSize = 14,
		TextColor3 = T.SubText,
		TextXAlignment = XC,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		Parent = header,
	})
	bindFeedback(em, header, header, { Normal = T.Element, Hover = T.ElementHover, Press = T.ElementPress })

	local body = new("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = AUTO_Y,
		LayoutOrder = 2,
		Visible = false,
		Parent = root,
	})
	padding(body, 6, 0, 6, 6)

	local obj = {}
	local emit = bindHandle(ctx, obj, root, em, cfg)
	local options, selected = {}, {}
	local open = false
	local list

	local function ordered()
		local out = {}
		for _, v in ipairs(options) do
			if selected[v] then
				out[#out + 1] = v
			end
		end
		return out
	end
	local function getValue()
		local sel = ordered()
		if multi then
			return sel
		end
		return sel[1]
	end
	local function updateHeader()
		local sel = ordered()
		if #sel == 0 then
			valueLbl.Text = placeholder
			valueLbl.TextColor3 = T.SubText
		else
			local names = {}
			for i, v in ipairs(sel) do
				names[i] = tostring(v)
			end
			valueLbl.Text = table.concat(names, ", ")
			valueLbl.TextColor3 = T.Accent
		end
	end
	local function apply(newSel, silent)
		local changed = not sameSet(selected, newSel)
		selected = newSel
		list:SetSelected(selected)
		updateHeader()
		if changed and not silent then
			emit(getValue())
		end
	end
	local function setOpen(v)
		open = v
		body.Visible = v
		tween(chevron, { Rotation = v and 90 or 0 })
	end

	list = createOptionList(ctx, em, body, {
		Multi = multi,
		MaxHeight = cfg.MaxHeight or 140,
		Options = {},
		EmptyText = "No options",
		OnPick = function(v)
			if multi then
				local newSel = copyTable(selected)
				if newSel[v] then
					newSel[v] = nil
				else
					newSel[v] = true
				end
				apply(newSel, false)
			else
				apply({ [v] = true }, false)
				setOpen(false)
			end
		end,
	})

	em:Add(header.Activated:Connect(function()
		setOpen(not open)
	end))

	function obj:SetOptions(opts, keepSelection)
		options = {}
		if type(opts) == "table" then
			for _, v in ipairs(opts) do
				options[#options + 1] = v
			end
		end
		list:SetOptions(options)
		local newSel = {}
		if keepSelection ~= false then
			for v in pairs(selected) do
				if indexOf(options, v) then
					newSel[v] = true
				end
			end
		end
		apply(newSel, true)
	end
	obj.Refresh = obj.SetOptions

	function obj:Set(v, silent)
		local newSel = {}
		if multi then
			if type(v) == "table" then
				for _, x in ipairs(v) do
					if indexOf(options, x) then
						newSel[x] = true
					end
				end
			end
		else
			if v ~= nil then
				if not indexOf(options, v) then
					return
				end
				newSel[v] = true
			end
		end
		apply(newSel, silent)
	end
	function obj:Get()
		return getValue()
	end
	function obj:GetOptions()
		return options
	end
	function obj:Clear(silent)
		apply({}, silent)
	end
	function obj:SelectAll(silent)
		if multi then
			local newSel = {}
			for _, v in ipairs(options) do
				newSel[v] = true
			end
			apply(newSel, silent)
		end
	end
	function obj:Open()
		setOpen(true)
	end
	function obj:Close()
		setOpen(false)
	end
	function obj:SetTitle(t)
		titleLbl.Text = tostring(t)
	end

	obj:SetOptions(cfg.Options)
	if multi then
		if type(cfg.Default) == "table" then
			obj:Set(cfg.Default, true)
		end
	elseif cfg.Default ~= nil then
		obj:Set(cfg.Default, true)
	end
	if cfg.FireOnCreate then
		emit(getValue())
	end
	return obj
end

function Container:CreateDropdown(cfg)
	return createDropdown(self, cfg, false)
end

function Container:CreateMultiDropdown(cfg)
	return createDropdown(self, cfg, true)
end

function Container:CreateRadioGroup(cfg)
	cfg = norm(cfg, "Title")
	local root, em, T, ctx = baseElement(self, nil, "RadioGroup")
	padding(root, 0, 0, 0, 4)
	listLayout(root, 0)
	local hasTitle = cfg.Title ~= nil and tostring(cfg.Title) ~= ""
	local titleLbl = textLabel(T, {
		Text = hasTitle and tostring(cfg.Title) or "",
		Size = UDim2.new(1, 0, 0, 30),
		LayoutOrder = 0,
		Visible = hasTitle,
		TextTruncate = TRUNCATE,
		Parent = root,
	})
	padding(titleLbl, 10, 0, 10, 0)
	local rowsFrame = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = AUTO_Y,
		LayoutOrder = 1,
		Parent = root,
	})
	listLayout(rowsFrame, 0)
	local emptyLbl = textLabel(T, {
		Text = "No options",
		TextColor3 = T.SubText,
		Size = UDim2.new(1, 0, 0, 28),
		LayoutOrder = 2,
		Visible = false,
		Parent = root,
	})
	padding(emptyLbl, 10, 0, 10, 0)

	local obj = {}
	local emit = bindHandle(ctx, obj, root, em, cfg)
	local rowMaid = Maid.new()
	em:Add(rowMaid)
	local options, rows, selected = {}, {}, nil

	local function style(r, instant)
		local on = selected ~= nil and r.Value == selected
		r.Label.TextColor3 = on and T.Text or T.SubText
		if instant then
			r.Dot.BackgroundTransparency = on and 0 or 1
			r.RingStroke.Color = on and T.Accent or T.Stroke
		else
			tween(r.Dot, { BackgroundTransparency = on and 0 or 1 })
			tween(r.RingStroke, { Color = on and T.Accent or T.Stroke })
		end
	end

	local function build()
		rowMaid:Cleanup()
		for _, r in ipairs(rows) do
			r.Btn:Destroy()
		end
		rows = {}
		emptyLbl.Visible = #options == 0
		for i, v in ipairs(options) do
			local btn = new("TextButton", {
				Name = "Radio",
				BackgroundColor3 = T.ElementHover,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 28),
				LayoutOrder = i,
				Parent = rowsFrame,
			})
			local ring = new("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 12, 0.5, 0),
				Size = UDim2.fromOffset(16, 16),
				Parent = btn,
			})
			corner(ring, 8)
			local ringStroke = stroke(ring, T.Stroke, 1.5, 0)
			local dot = new("Frame", {
				BackgroundColor3 = T.Accent,
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.fromOffset(8, 8),
				Parent = ring,
			})
			corner(dot, 4)
			local lbl = textLabel(T, {
				Text = tostring(v),
				TextTruncate = TRUNCATE,
				Position = UDim2.new(0, 38, 0, 0),
				Size = UDim2.new(1, -48, 1, 0),
				Parent = btn,
			})
			rowMaid:Add(btn.MouseEnter:Connect(function()
				tween(btn, { BackgroundTransparency = 0.6 })
			end))
			rowMaid:Add(btn.MouseLeave:Connect(function()
				tween(btn, { BackgroundTransparency = 1 })
			end))
			rowMaid:Add(btn.InputBegan:Connect(function(input)
				if isPress(input) then
					tween(btn, { BackgroundTransparency = 0.6 })
				end
			end))
			rowMaid:Add(btn.InputEnded:Connect(function(input)
				if isPress(input) then
					tween(btn, { BackgroundTransparency = 1 })
				end
			end))
			rowMaid:Add(btn.Activated:Connect(function()
				obj:Set(v)
			end))
			local row = { Btn = btn, Value = v, Label = lbl, Dot = dot, RingStroke = ringStroke }
			rows[i] = row
			style(row, true)
		end
	end

	function obj:SetOptions(opts)
		options = {}
		if type(opts) == "table" then
			for _, v in ipairs(opts) do
				options[#options + 1] = v
			end
		end
		if selected ~= nil and not indexOf(options, selected) then
			selected = nil
		end
		build()
	end
	function obj:Set(v, silent)
		if v ~= nil and not indexOf(options, v) then
			return
		end
		if v == selected then
			return
		end
		selected = v
		for _, r in ipairs(rows) do
			style(r, false)
		end
		if not silent then
			emit(selected)
		end
	end
	function obj:Get()
		return selected
	end
	function obj:GetOptions()
		return options
	end
	function obj:SetTitle(t)
		titleLbl.Text = tostring(t)
		titleLbl.Visible = tostring(t) ~= ""
	end

	obj:SetOptions(cfg.Options)
	if cfg.Default ~= nil and indexOf(options, cfg.Default) then
		selected = cfg.Default
		for _, r in ipairs(rows) do
			style(r, true)
		end
	end
	if cfg.FireOnCreate then
		emit(selected)
	end
	return obj
end

function Container:CreateItemList(cfg)
	cfg = norm(cfg, "Title")
	local multi = cfg.Multi == true
	local root, em, T, ctx = baseElement(self, nil, "ItemList")
	padding(root, 6, 6, 6, 6)
	listLayout(root, 4)
	local hasTitle = cfg.Title ~= nil and tostring(cfg.Title) ~= ""
	local titleLbl = textLabel(T, {
		Text = hasTitle and tostring(cfg.Title) or "",
		Size = UDim2.new(1, 0, 0, 20),
		LayoutOrder = 0,
		Visible = hasTitle,
		TextTruncate = TRUNCATE,
		Parent = root,
	})
	padding(titleLbl, 4, 0, 4, 0)

	local obj = {}
	local emit = bindHandle(ctx, obj, root, em, cfg)
	local items, selected = {}, {}
	local list

	local function ordered()
		local out = {}
		for _, v in ipairs(items) do
			if selected[v] then
				out[#out + 1] = v
			end
		end
		return out
	end
	local function getValue()
		local sel = ordered()
		if multi then
			return sel
		end
		return sel[1]
	end
	local function apply(newSel, silent)
		local changed = not sameSet(selected, newSel)
		selected = newSel
		list:SetSelected(selected)
		if changed and not silent then
			emit(getValue())
		end
	end

	list = createOptionList(ctx, em, root, {
		Multi = multi,
		MaxHeight = cfg.MaxHeight or 150,
		EmptyText = "No items",
		LayoutOrder = 1,
		OnPick = function(v)
			if multi then
				local newSel = copyTable(selected)
				if newSel[v] then
					newSel[v] = nil
				else
					newSel[v] = true
				end
				apply(newSel, false)
			else
				if selected[v] and cfg.AllowDeselect then
					apply({}, false)
				else
					apply({ [v] = true }, false)
				end
			end
		end,
	})

	local function rebuild()
		list:SetOptions(items)
		local newSel = {}
		for v in pairs(selected) do
			if indexOf(items, v) then
				newSel[v] = true
			end
		end
		apply(newSel, true)
	end
	local scheduleRebuild = coalesce(obj, rebuild)

	function obj:SetItems(newItems)
		items = {}
		if type(newItems) == "table" then
			for _, v in ipairs(newItems) do
				items[#items + 1] = v
			end
		end
		rebuild()
	end
	function obj:AddItem(v)
		if v ~= nil then
			items[#items + 1] = v
			scheduleRebuild()
		end
	end
	function obj:RemoveItem(v)
		local i = indexOf(items, v)
		if i then
			table.remove(items, i)
			scheduleRebuild()
		end
	end
	function obj:Clear()
		items = {}
		rebuild()
	end
	function obj:GetItems()
		return items
	end
	function obj:Set(v, silent)
		local newSel = {}
		if multi then
			if type(v) == "table" then
				for _, x in ipairs(v) do
					if indexOf(items, x) then
						newSel[x] = true
					end
				end
			end
		elseif v ~= nil then
			if not indexOf(items, v) then
				return
			end
			newSel[v] = true
		end
		apply(newSel, silent)
	end
	function obj:Get()
		return getValue()
	end
	function obj:SetFilter(q)
		list:SetFilter(q)
	end
	function obj:SetTitle(t)
		titleLbl.Text = tostring(t)
		titleLbl.Visible = tostring(t) ~= ""
	end

	obj:SetItems(cfg.Items)
	if cfg.Default ~= nil then
		obj:Set(cfg.Default, true)
	end
	if cfg.FireOnCreate then
		emit(getValue())
	end
	return obj
end

----------------------------------------------------------------------
-- Elements: Keybind
----------------------------------------------------------------------

local function resolveKey(v)
	if typeof(v) == "EnumItem" and v.EnumType == Enum.KeyCode then
		return v
	end
	if type(v) == "string" then
		local ok, key = pcall(function()
			return Enum.KeyCode[v]
		end)
		if ok then
			return key
		end
	end
	return nil
end

function Container:CreateKeybind(cfg)
	cfg = norm(cfg, "Title")
	local frame, em, T, ctx = baseElement(self, 34, "Keybind")
	local titleLbl = textLabel(T, {
		Text = titleOf(cfg, "Keybind"),
		TextTruncate = TRUNCATE,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -112, 1, 0),
		Parent = frame,
	})
	local btn = new("TextButton", {
		BackgroundColor3 = T.Surface,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -6, 0.5, 0),
		Size = UDim2.fromOffset(96, 24),
		Font = Enum.Font.Code,
		TextSize = 12,
		TextColor3 = T.Accent,
		Parent = frame,
	})
	corner(btn, 6)
	stroke(btn, T.Stroke, 1, 0.3)
	bindFeedback(em, btn, btn, { Normal = T.Surface, Hover = T.ElementHover, Press = T.ElementPress })

	local obj = {}
	local emit = bindHandle(ctx, obj, frame, em, cfg)
	local key = resolveKey(cfg.Default)
	local listening = false

	local function render()
		if listening then
			btn.Text = "Press key..."
		elseif not UserInputService.KeyboardEnabled then
			btn.Text = "Tap to run"
		else
			btn.Text = key and key.Name or "None"
		end
	end
	render()
	em:Add(UserInputService:GetPropertyChangedSignal("KeyboardEnabled"):Connect(render))

	local function setKey(k, silent)
		if k == key then
			return
		end
		key = k
		if not silent and type(cfg.OnChanged) == "function" then
			fire(ctx, cfg.OnChanged, key)
		end
	end

	em:Add(btn.Activated:Connect(function()
		if not UserInputService.KeyboardEnabled then
			-- fallback for touch-only devices: the button just runs the action
			emit(key)
			return
		end
		listening = not listening
		render()
	end))

	em:Add(UserInputService.InputBegan:Connect(function(input, processed)
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.Escape then
					-- cancel
				elseif input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then
					setKey(nil, false)
				else
					setKey(input.KeyCode, false)
				end
				listening = false
				render()
			end
			return
		end
		if processed or not key then
			return
		end
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == key then
			emit(key)
		end
	end))

	function obj:Set(v, silent)
		setKey(resolveKey(v), silent)
		render()
	end
	function obj:Get()
		return key
	end
	function obj:Press()
		emit(key)
	end
	function obj:SetTitle(t)
		titleLbl.Text = tostring(t)
	end
	return obj
end

----------------------------------------------------------------------
-- Elements: ColorPicker
----------------------------------------------------------------------

function Container:CreateColorPicker(cfg)
	cfg = norm(cfg, "Title")
	local root, em, T, ctx = baseElement(self, nil, "ColorPicker")
	root.ClipsDescendants = true
	listLayout(root, 0)
	local header = new("TextButton", {
		Name = "Header",
		BackgroundColor3 = T.Element,
		Size = UDim2.new(1, 0, 0, 34),
		LayoutOrder = 1,
		Parent = root,
	})
	corner(header, 8)
	local titleLbl = textLabel(T, {
		Text = titleOf(cfg, "Color"),
		TextTruncate = TRUNCATE,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -90, 1, 0),
		Parent = header,
	})
	local swatch = new("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -34, 0.5, 0),
		Size = UDim2.fromOffset(34, 18),
		Parent = header,
	})
	corner(swatch, 5)
	stroke(swatch, T.Stroke, 1, 0.2)
	local chevron = textLabel(T, {
		Text = ">",
		Font = T.FontBold,
		TextSize = 14,
		TextColor3 = T.SubText,
		TextXAlignment = XC,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		Parent = header,
	})
	bindFeedback(em, header, header, { Normal = T.Element, Hover = T.ElementHover, Press = T.ElementPress })

	local body = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = AUTO_Y,
		LayoutOrder = 2,
		Visible = false,
		Parent = root,
	})
	padding(body, 10, 2, 10, 10)
	listLayout(body, 6)

	local obj = {}
	local emit = bindHandle(ctx, obj, root, em, cfg)

	local startColor = typeof(cfg.Default) == "Color3" and cfg.Default or T.Accent
	local r0, g0, b0 = to255(startColor)
	local channels = { r0, g0, b0 }
	local color = startColor
	local valueLabels, tracks = {}, {}
	local hexBox

	local function refresh()
		color = Color3.fromRGB(channels[1], channels[2], channels[3])
		swatch.BackgroundColor3 = color
		for i = 1, 3 do
			valueLabels[i].Text = tostring(channels[i])
		end
		if hexBox then
			hexBox.Text = toHex(color)
		end
	end

	local defs = {
		{ "R", Color3.fromRGB(235, 85, 95) },
		{ "G", Color3.fromRGB(70, 200, 120) },
		{ "B", Color3.fromRGB(86, 140, 255) },
	}
	for i, def in ipairs(defs) do
		local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = i, Parent = body })
		textLabel(T, { Text = def[1], Font = T.FontBold, TextSize = 12, TextColor3 = def[2], Size = UDim2.new(0, 14, 1, 0), Parent = row })
		valueLabels[i] = textLabel(T, {
			Text = "0",
			TextSize = 12,
			TextColor3 = T.SubText,
			TextXAlignment = XR,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.new(0, 30, 1, 0),
			Parent = row,
		})
		tracks[i] = buildTrack(ctx, em, row, {
			Min = 0,
			Max = 255,
			Inc = 1,
			Default = channels[i],
			Color = def[2],
			Position = UDim2.new(0, 20, 0, 0),
			Size = UDim2.new(1, -56, 1, 0),
			OnChange = function(v, silent)
				channels[i] = v
				refresh()
				if not silent then
					emit(color)
				end
			end,
		})
	end

	local hexRow = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 4, Parent = body })
	textLabel(T, { Text = "HEX", Font = T.FontBold, TextSize = 12, TextColor3 = T.SubText, Size = UDim2.new(0, 34, 1, 0), Parent = hexRow })
	hexBox = new("TextBox", {
		BackgroundColor3 = T.Surface,
		Position = UDim2.new(0, 34, 0, 0),
		Size = UDim2.new(1, -34, 1, 0),
		Font = Enum.Font.Code,
		TextSize = 12,
		TextColor3 = T.Text,
		ClearTextOnFocus = false,
		TextXAlignment = XL,
		Parent = hexRow,
	})
	corner(hexBox, 6)
	stroke(hexBox, T.Stroke, 1, 0.3)
	padding(hexBox, 8, 0, 8, 0)
	refresh()

	em:Add(hexBox.FocusLost:Connect(function()
		local hex = (hexBox.Text:gsub("[#%s]", ""))
		if #hex == 6 and hex:match("^%x+$") then
			local r = tonumber(string.sub(hex, 1, 2), 16)
			local g = tonumber(string.sub(hex, 3, 4), 16)
			local b = tonumber(string.sub(hex, 5, 6), 16)
			obj:Set(Color3.fromRGB(r, g, b))
		else
			hexBox.Text = toHex(color)
		end
	end))

	local open = false
	em:Add(header.Activated:Connect(function()
		open = not open
		body.Visible = open
		tween(chevron, { Rotation = open and 90 or 0 })
	end))

	function obj:Set(c, silent)
		if typeof(c) ~= "Color3" then
			return
		end
		local before = color
		local r, g, b = to255(c)
		tracks[1].Set(r, true)
		tracks[2].Set(g, true)
		tracks[3].Set(b, true)
		refresh()
		if not silent and color ~= before then
			emit(color)
		end
	end
	function obj:Get()
		return color
	end
	function obj:GetHex()
		return toHex(color)
	end
	function obj:SetTitle(t)
		titleLbl.Text = tostring(t)
	end
	if cfg.FireOnCreate then
		emit(color)
	end
	return obj
end

----------------------------------------------------------------------
-- Elements: DataTable
----------------------------------------------------------------------

function Container:CreateDataTable(cfg)
	cfg = norm(cfg, "Title")
	local root, em, T, ctx = baseElement(self, nil, "DataTable")
	padding(root, 6, 6, 6, 6)
	listLayout(root, 4)
	local hasTitle = cfg.Title ~= nil and tostring(cfg.Title) ~= ""
	local titleLbl = textLabel(T, {
		Text = hasTitle and tostring(cfg.Title) or "",
		Size = UDim2.new(1, 0, 0, 20),
		LayoutOrder = 0,
		Visible = hasTitle,
		TextTruncate = TRUNCATE,
		Parent = root,
	})
	padding(titleLbl, 4, 0, 4, 0)

	local ROW_H, GAP = 24, 2
	local maxHeight = tonumber(cfg.MaxHeight) or 160
	local columns, data, query = {}, {}, ""
	local widths = type(cfg.Widths) == "table" and cfg.Widths or nil

	local header = new("Frame", { BackgroundColor3 = T.Surface, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 1, Parent = root })
	corner(header, 6)
	local scroll = new("ScrollingFrame", {
		BackgroundColor3 = T.Surface,
		Size = UDim2.new(1, 0, 0, ROW_H + 6),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = AUTO_Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = T.Stroke,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		VerticalScrollBarInset = Enum.ScrollBarInset.None,
		LayoutOrder = 2,
		Parent = root,
	})
	corner(scroll, 6)
	stroke(scroll, T.Stroke, 1, 0.6)
	padding(scroll, 3, 3, 3, 3)
	listLayout(scroll, GAP)
	autoToggleScroll(em, scroll)
	local empty = textLabel(T, {
		Text = "No data",
		TextColor3 = T.SubText,
		TextXAlignment = XC,
		Size = UDim2.new(1, 0, 0, ROW_H),
		LayoutOrder = 1000000,
		Visible = false,
		Parent = scroll,
	})

	local obj = {}
	local emit = bindHandle(ctx, obj, root, em, cfg)
	local rowMaid = Maid.new()
	em:Add(rowMaid)
	local rowFrames, headerLabels = {}, {}

	local function layout()
		local n = math.max(#columns, 1)
		local ws, total = {}, 0
		for i = 1, n do
			local w = widths and tonumber(widths[i]) or 1
			if not w or w <= 0 then
				w = 1
			end
			ws[i] = w
			total = total + w
		end
		local out, acc = {}, 0
		for i = 1, n do
			out[i] = { acc / total, ws[i] / total }
			acc = acc + ws[i]
		end
		return out
	end

	local function buildHeader()
		for _, l in ipairs(headerLabels) do
			l:Destroy()
		end
		headerLabels = {}
		local lay = layout()
		for i, name in ipairs(columns) do
			headerLabels[i] = textLabel(T, {
				Text = tostring(name),
				Font = T.FontBold,
				TextSize = 12,
				TextColor3 = T.Accent,
				TextTruncate = TRUNCATE,
				Position = UDim2.new(lay[i][1], 0, 0, 0),
				Size = UDim2.new(lay[i][2], 0, 1, 0),
				Parent = header,
			})
			padding(headerLabels[i], 8, 0, 4, 0)
		end
		header.Visible = #columns > 0
	end

	local function buildRows()
		rowMaid:Cleanup()
		for _, f in ipairs(rowFrames) do
			f:Destroy()
		end
		rowFrames = {}
		local lay = layout()
		local shown = 0
		for idx, row in ipairs(data) do
			local cells, joined = {}, {}
			for i = 1, math.max(#columns, #row) do
				local v = row[i]
				cells[i] = tostring(v == nil and "" or v)
				joined[i] = cells[i]
			end
			local hay = string.lower(table.concat(joined, " "))
			if query == "" or string.find(hay, query, 1, true) then
				shown = shown + 1
				local base = (shown % 2 == 0) and shade(T.Surface, 0.03) or T.Surface
				local btn = new("TextButton", {
					Name = "Row",
					BackgroundColor3 = base,
					Size = UDim2.new(1, 0, 0, ROW_H),
					LayoutOrder = shown,
					Parent = scroll,
				})
				corner(btn, 4)
				for i = 1, math.max(#columns, 1) do
					local l = lay[i] or lay[#lay]
					local cell = textLabel(T, {
						Text = cells[i] or "",
						TextSize = 12,
						TextColor3 = T.Text,
						TextTruncate = TRUNCATE,
						Position = UDim2.new(l[1], 0, 0, 0),
						Size = UDim2.new(l[2], 0, 1, 0),
						Parent = btn,
					})
					padding(cell, 8, 0, 4, 0)
				end
				bindFeedback(rowMaid, btn, btn, { Normal = base, Hover = shade(base, 0.08), Press = shade(base, -0.12) })
				rowMaid:Add(btn.Activated:Connect(function()
					emit(data[idx], idx)
				end))
				rowFrames[#rowFrames + 1] = btn
			end
		end
		empty.Visible = shown == 0
		local count = math.max(shown, 1)
		local h = count * ROW_H + (count - 1) * GAP + 6
		scroll.Size = UDim2.new(1, 0, 0, math.min(h, maxHeight))
	end
	local scheduleRows = coalesce(obj, buildRows)

	function obj:SetColumns(cols)
		columns = {}
		if type(cols) == "table" then
			for _, c in ipairs(cols) do
				columns[#columns + 1] = c
			end
		end
		buildHeader()
		scheduleRows()
	end
	function obj:SetRows(rows)
		data = {}
		if type(rows) == "table" then
			for _, r in ipairs(rows) do
				if type(r) == "table" then
					data[#data + 1] = r
				end
			end
		end
		scheduleRows()
	end
	function obj:AddRow(row)
		if type(row) == "table" then
			data[#data + 1] = row
			scheduleRows()
		end
	end
	function obj:Clear()
		data = {}
		scheduleRows()
	end
	function obj:GetRows()
		return data
	end
	function obj:SetFilter(q)
		query = (q == nil) and "" or string.lower(tostring(q))
		scheduleRows()
	end
	function obj:SetTitle(t)
		titleLbl.Text = tostring(t)
		titleLbl.Visible = tostring(t) ~= ""
	end

	obj:SetColumns(cfg.Columns)
	obj:SetRows(cfg.Rows)
	return obj
end

----------------------------------------------------------------------
-- Elements: Collapsible, Console
----------------------------------------------------------------------

function Container:CreateCollapsible(cfg)
	cfg = norm(cfg, "Title")
	local root, em, T, ctx = baseElement(self, nil, "Collapsible")
	root.ClipsDescendants = true
	listLayout(root, 0)
	local header = new("TextButton", {
		Name = "Header",
		BackgroundColor3 = T.Element,
		Size = UDim2.new(1, 0, 0, 34),
		LayoutOrder = 1,
		Parent = root,
	})
	corner(header, 8)
	local titleLbl = textLabel(T, {
		Text = titleOf(cfg, "Collapsible"),
		Font = T.FontBold,
		TextTruncate = TRUNCATE,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -40, 1, 0),
		Parent = header,
	})
	local chevron = textLabel(T, {
		Text = ">",
		Font = T.FontBold,
		TextSize = 14,
		TextColor3 = T.SubText,
		TextXAlignment = XC,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		Parent = header,
	})
	bindFeedback(em, header, header, { Normal = T.Element, Hover = T.ElementHover, Press = T.ElementPress })
	local body = new("Frame", {
		Name = "Body",
		BackgroundColor3 = T.Surface,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = AUTO_Y,
		LayoutOrder = 2,
		Visible = false,
		Parent = root,
	})
	padding(body, 6, 6, 6, 6)
	listLayout(body, 6)

	local col = setmetatable({ _ctx = ctx, _frame = body, _order = 0 }, ContainerMT)
	bindHandle(ctx, col, root, em, cfg)
	local open = false
	local function setOpen(v, instant)
		open = v
		body.Visible = v
		if instant then
			chevron.Rotation = v and 90 or 0
		else
			tween(chevron, { Rotation = v and 90 or 0 })
		end
	end
	em:Add(header.Activated:Connect(function()
		setOpen(not open)
	end))
	function col:SetOpen(v)
		setOpen(v == true)
	end
	function col:Open()
		setOpen(true)
	end
	function col:Close()
		setOpen(false)
	end
	function col:Toggle()
		setOpen(not open)
	end
	function col:IsOpen()
		return open
	end
	function col:SetTitle(t)
		titleLbl.Text = tostring(t)
	end
	setOpen(cfg.Open == true, true)
	return col
end

local CONSOLE_COLORS = {
	Info = Color3.fromRGB(215, 215, 230),
	Success = Color3.fromRGB(70, 200, 120),
	Warn = Color3.fromRGB(240, 185, 60),
	Error = Color3.fromRGB(235, 85, 95),
}

function Container:CreateConsole(cfg)
	cfg = norm(cfg, "Title")
	local root, em, T, ctx = baseElement(self, nil, "Console")
	padding(root, 6, 6, 6, 6)
	listLayout(root, 4)
	local height = math.clamp(tonumber(cfg.Height) or 140, 60, 400)
	local maxLines = math.clamp(tonumber(cfg.MaxLines) or 100, 10, 500)

	local head = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 1, Parent = root })
	local titleLbl = textLabel(T, {
		Text = titleOf(cfg, "Console"),
		Font = T.FontBold,
		TextSize = 12,
		Position = UDim2.new(0, 4, 0, 0),
		Size = UDim2.new(1, -60, 1, 0),
		Parent = head,
	})
	local clearBtn = new("TextButton", {
		Text = "Clear",
		Font = T.Font,
		TextSize = 11,
		TextColor3 = T.SubText,
		BackgroundColor3 = T.Surface,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(52, 20),
		Parent = head,
	})
	corner(clearBtn, 5)
	bindFeedback(em, clearBtn, clearBtn, { Normal = T.Surface, Hover = T.ElementHover, Press = T.ElementPress })

	local scroll = new("ScrollingFrame", {
		BackgroundColor3 = T.Surface,
		Size = UDim2.new(1, 0, 0, height),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = AUTO_Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = T.Stroke,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		VerticalScrollBarInset = Enum.ScrollBarInset.None,
		LayoutOrder = 2,
		Parent = root,
	})
	corner(scroll, 6)
	stroke(scroll, T.Stroke, 1, 0.6)
	autoToggleScroll(em, scroll)
	padding(scroll, 6, 4, 6, 4)
	local text = new("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = AUTO_Y,
		Font = Enum.Font.Code,
		TextSize = 12,
		TextColor3 = T.Text,
		TextXAlignment = XL,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		RichText = true,
		Text = "",
		Parent = scroll,
	})

	local obj = {}
	bindHandle(ctx, obj, root, em, cfg)
	local lines = {}
	local stick = true

	local function atBottom()
		return scroll.CanvasPosition.Y + scroll.AbsoluteSize.Y >= scroll.AbsoluteCanvasSize.Y - 14
	end
	local refreshText = coalesce(obj, function()
		text.Text = table.concat(lines, "\n")
		if stick then
			task.wait()
			if not obj._dead then
				scroll.CanvasPosition = Vector2.new(0, math.max(0, scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteSize.Y))
			end
		end
	end)

	function obj:Log(message, kind)
		local color = CONSOLE_COLORS[kind or "Info"] or CONSOLE_COLORS.Info
		local s = tostring(message)
		if #s > 400 then
			s = string.sub(s, 1, 400) .. "..."
		end
		s = escapeRich(s)
		if cfg.Timestamp then
			s = os.date("%H:%M:%S") .. " " .. s
		end
		lines[#lines + 1] = string.format('<font color="%s">%s</font>', toHex(color), s)
		while #lines > maxLines do
			table.remove(lines, 1)
		end
		local total = 0
		for _, l in ipairs(lines) do
			total = total + #l + 1
		end
		while total > 14000 and #lines > 1 do
			total = total - (#lines[1] + 1)
			table.remove(lines, 1)
		end
		stick = atBottom() or #lines <= 1
		refreshText()
	end
	function obj:Info(m)
		obj:Log(m, "Info")
	end
	function obj:Success(m)
		obj:Log(m, "Success")
	end
	function obj:Warn(m)
		obj:Log(m, "Warn")
	end
	function obj:Error(m)
		obj:Log(m, "Error")
	end
	function obj:Clear()
		lines = {}
		stick = true
		refreshText()
	end
	function obj:SetMaxLines(n)
		maxLines = math.clamp(tonumber(n) or maxLines, 10, 500)
	end
	function obj:SetTitle(t)
		titleLbl.Text = tostring(t)
	end
	em:Add(clearBtn.Activated:Connect(function()
		obj:Clear()
	end))
	return obj
end

-- Wrap every Create* constructor: dead-window safe + errors never crash the host script
for name, fn in pairs(Container) do
	if type(fn) == "function" and string.sub(name, 1, 6) == "Create" then
		Container[name] = function(self, ...)
			if self._ctx.Destroyed or self._dead then
				return Dead
			end
			if Library.Debug then
				return fn(self, ...)
			end
			local ok, result = pcall(fn, self, ...)
			if ok then
				return result
			end
			warn("[MiniUI] " .. name .. " failed: " .. tostring(result))
			return Dead
		end
	end
end

----------------------------------------------------------------------
-- Notifications (library level, independent from windows)
----------------------------------------------------------------------

local function getNotifyHolder()
	local n = Library._notify
	if n and n.Gui.Parent then
		return n
	end
	local parent = resolveParent()
	if not parent then
		return nil
	end
	local gui = makeScreenGui("MiniUI_Notifications", 1001)
	gui.Parent = parent
	local holder = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.new(0, 240, 1, -20),
		Parent = gui,
	})
	new("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Parent = holder,
	})
	n = { Gui = gui, Holder = holder, Counter = 0, Active = {} }
	Library._notify = n
	return n
end

function Library:Notify(cfg)
	cfg = type(cfg) == "table" and cfg or { Content = tostring(cfg == nil and "" or cfg) }
	local n = getNotifyHolder()
	if not n then
		return Dead
	end
	local T = Library.Theme
	local colors = { Info = T.Accent, Success = T.Success, Warning = T.Warning, Error = T.Danger }
	local color = colors[cfg.Type or "Info"] or T.Accent
	local duration = tonumber(cfg.Duration) or 3

	while #n.Active >= 4 do
		n.Active[1].Close()
	end

	n.Counter = n.Counter + 1
	local wrapper = new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = AUTO_Y,
		LayoutOrder = n.Counter,
		Parent = n.Holder,
	})
	local card = new("Frame", {
		BackgroundColor3 = T.Topbar,
		Position = UDim2.new(0, 270, 0, 0),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = AUTO_Y,
		Parent = wrapper,
	})
	corner(card, 8)
	stroke(card, T.Stroke, 1, 0.3)
	local inner = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = AUTO_Y, Parent = card })
	padding(inner, 14, 8, 10, 10)
	listLayout(inner, 2)
	local hasTitle = cfg.Title ~= nil and tostring(cfg.Title) ~= ""
	if hasTitle then
		textLabel(T, {
			Text = tostring(cfg.Title),
			Font = T.FontBold,
			TextColor3 = color,
			TextWrapped = true,
			AutomaticSize = AUTO_Y,
			Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = 1,
			Parent = inner,
		})
	end
	textLabel(T, {
		Text = tostring(cfg.Content or ""),
		TextColor3 = T.SubText,
		TextSize = 12,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		AutomaticSize = AUTO_Y,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = 2,
		Parent = inner,
	})
	local sideBar = new("Frame", { BackgroundColor3 = color, Size = UDim2.new(0, 3, 1, -12), Position = UDim2.new(0, 5, 0, 6), Parent = card })
	corner(sideBar, 2)
	local closeBtn = new("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 5, Parent = card })

	local closed = false
	local entry = {}
	local function close()
		if closed then
			return
		end
		closed = true
		for i, e in ipairs(n.Active) do
			if e == entry then
				table.remove(n.Active, i)
				break
			end
		end
		tween(card, { Position = UDim2.new(0, 270, 0, 0) }, TWEEN_FAST)
		task.delay(0.2, function()
			wrapper:Destroy()
		end)
	end
	entry.Close = close
	n.Active[#n.Active + 1] = entry

	closeBtn.Activated:Connect(close)
	tween(card, { Position = UDim2.new(0, 0, 0, 0) }, TWEEN_SLOW)
	if duration > 0 then
		local timer = new("Frame", {
			BackgroundColor3 = color,
			BackgroundTransparency = 0.4,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 10, 1, -4), -- inset so it stays inside the rounded card
			Size = UDim2.new(1, -20, 0, 2),
			Parent = card,
		})
		corner(timer, 1)
		tween(timer, { Size = UDim2.new(0, 0, 0, 2) }, TweenInfo.new(duration, Enum.EasingStyle.Linear))
		task.delay(duration, close)
	end

	local handle = {}
	function handle:Close()
		close()
	end
	return handle
end

----------------------------------------------------------------------
-- Window
----------------------------------------------------------------------

function Library:CreateWindow(cfg)
	if type(cfg) == "string" then
		cfg = { Title = cfg }
	end
	cfg = type(cfg) == "table" and cfg or {}

	local T = copyTable(Library.Theme)
	local title = tostring(cfg.Title or "Mini UI")
	local guiName = "MiniUI_" .. (title:gsub("[^%w_]", ""))

	local registry = getRegistry()
	if registry and registry[guiName] then
		pcall(function()
			registry[guiName]:Destroy()
		end)
	end
	local parent = resolveParent()
	if not parent then
		error("[MiniUI] Could not find a place to put the UI", 2)
	end
	local okOld, old = pcall(function()
		return parent:FindFirstChild(guiName)
	end)
	if okOld and old then
		pcall(function()
			old:Destroy()
		end)
	end

	local maid = Maid.new()
	local ctx = { Maid = maid, Theme = T, Destroyed = false, Pages = {}, LockCount = 0 }
	function ctx.LockScroll(lock)
		ctx.LockCount = math.max(0, ctx.LockCount + (lock and 1 or -1))
		for _, page in ipairs(ctx.Pages) do
			page.ScrollingEnabled = ctx.LockCount == 0
		end
	end

	local gui = makeScreenGui(guiName, 1000)
	gui.Parent = parent
	maid:Add(gui)
	ctx.Gui = gui

	-- size / position (clamped to the screen so it fits phones)
	local camera = workspace.CurrentCamera
	local vp = camera and camera.ViewportSize or Vector2.new(800, 400)
	local reqSize = typeof(cfg.Size) == "UDim2" and cfg.Size or UDim2.fromOffset(460, 320)
	local w = reqSize.X.Offset + reqSize.X.Scale * vp.X
	local h = reqSize.Y.Offset + reqSize.Y.Scale * vp.Y
	w = math.clamp(w, math.min(280, vp.X - 16), math.max(vp.X - 16, 100))
	h = math.clamp(h, math.min(200, vp.Y - 16), math.max(vp.Y - 16, 100))

	local main = new("Frame", {
		Name = "Main",
		BackgroundColor3 = T.Background,
		Size = UDim2.fromOffset(w, h),
		Position = typeof(cfg.Position) == "UDim2" and cfg.Position
			or UDim2.fromOffset(math.floor((vp.X - w) / 2), math.floor((vp.Y - h) / 2)),
		Parent = gui,
	})
	corner(main, 10)
	stroke(main, T.Stroke, 1, 0.2)
	local scaleTarget = math.clamp(tonumber(cfg.Scale) or 1, 0.5, 2)
	local uiScale = new("UIScale", { Scale = scaleTarget, Parent = main })

	-- title bar
	local topbar = new("Frame", { Name = "Topbar", BackgroundColor3 = T.Topbar, Size = UDim2.new(1, 0, 0, 38), Parent = main })
	corner(topbar, 10)
	new("Frame", { BackgroundColor3 = T.Topbar, Position = UDim2.new(0, 0, 1, -10), Size = UDim2.new(1, 0, 0, 10), Parent = topbar })
	new("Frame", { BackgroundColor3 = T.Stroke, BackgroundTransparency = 0.4, Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), Parent = topbar })
	local dot = new("Frame", {
		BackgroundColor3 = T.Accent,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(8, 8),
		Parent = topbar,
	})
	corner(dot, 4)
	local titleLbl = textLabel(T, {
		Text = title,
		Font = T.FontBold,
		TextSize = 14,
		TextTruncate = TRUNCATE,
		Position = UDim2.new(0, 28, 0, 0),
		Size = UDim2.new(1, -90, 1, 0),
		Parent = topbar,
	})

	local function topButton(offsetX, hoverColor)
		local b = new("TextButton", {
			BackgroundColor3 = T.Topbar,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, offsetX, 0.5, 0),
			Size = UDim2.fromOffset(28, 28),
			Parent = topbar,
		})
		corner(b, 7)
		bindFeedback(maid, b, b, { Normal = T.Topbar, Hover = hoverColor, Press = shade(hoverColor, -0.15) })
		return b
	end
	local minBtn = topButton(-38, T.ElementHover)
	new("Frame", {
		BackgroundColor3 = T.Text,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(10, 2),
		Parent = minBtn,
	})
	local closeBtn = topButton(-6, T.Danger)
	textLabel(T, {
		Text = "\195\151", -- multiplication sign
		Font = T.FontBold,
		TextSize = 20,
		TextXAlignment = XC,
		Size = UDim2.new(1, 0, 1, 0),
		Parent = closeBtn,
	})

	-- body: tab bar + pages
	local body = new("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 38),
		Size = UDim2.new(1, 0, 1, -38),
		Parent = main,
	})
	local tabBar = new("Frame", { BackgroundColor3 = T.Surface, Size = UDim2.new(1, 0, 0, 36), Parent = body })
	new("Frame", { BackgroundColor3 = T.Stroke, BackgroundTransparency = 0.5, Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), Parent = tabBar })
	local tabScroll = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = AUTO_X,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		Parent = tabBar,
	})
	padding(tabScroll, 6, 0, 6, 0)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Parent = tabScroll,
	})
	local pages = new("Frame", {
		Name = "Pages",
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Position = UDim2.new(0, 0, 0, 36),
		Size = UDim2.new(1, 0, 1, -36),
		Parent = body,
	})

	-- floating bubble (shown while the window is minimized)
	local bubbleEnabled = cfg.Bubble ~= false
	local bubble = new("TextButton", {
		Name = "Bubble",
		Text = string.upper(string.sub(title, 1, 1)),
		Font = T.FontBold,
		TextSize = 17,
		TextColor3 = T.Accent,
		BackgroundColor3 = T.Topbar,
		Size = UDim2.fromOffset(44, 44),
		Position = UDim2.fromOffset(14, math.floor(vp.Y * 0.4)),
		Visible = false,
		Parent = gui,
	})
	corner(bubble, 22)
	stroke(bubble, T.Accent, 1.5, 0.2)

	-- show / hide
	local visible = true
	local animToken = 0
	local function setVisible(v, instant)
		if ctx.Destroyed then
			return
		end
		visible = v
		animToken = animToken + 1
		local token = animToken
		if v then
			bubble.Visible = false
			main.Visible = true
			if not instant then
				uiScale.Scale = scaleTarget * 0.9
				tween(uiScale, { Scale = scaleTarget }, TWEEN_SLOW)
			end
		else
			bubble.Visible = bubbleEnabled
			if instant then
				main.Visible = false
			else
				tween(uiScale, { Scale = scaleTarget * 0.9 }, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
				task.delay(0.13, function()
					if animToken == token and not ctx.Destroyed then
						main.Visible = false
					end
				end)
			end
		end
	end

	makeDraggable(maid, topbar, main, gui, nil)
	makeDraggable(maid, bubble, bubble, gui, function()
		setVisible(true)
	end)

	-- Window object
	local Window = { Gui = gui, Main = main, Tabs = {}, Name = title }
	ctx.Window = Window
	local tabs = Window.Tabs
	local currentTab

	local function selectTab(tab)
		if not tab or ctx.Destroyed then
			return
		end
		currentTab = tab
		for _, t in ipairs(tabs) do
			local on = t == tab
			t.Page.Visible = on
			tween(t.Button, { TextColor3 = on and T.Text or T.SubText, BackgroundTransparency = on and 0 or 1 })
			tween(t.Line, { BackgroundTransparency = on and 0 or 1 })
		end
	end

	function Window:CreateTab(name)
		if ctx.Destroyed then
			return Dead
		end
		if type(name) == "table" then
			name = name.Title or name.Name
		end
		name = tostring(name or "Tab")
		local btn = new("TextButton", {
			Name = "Tab_" .. name,
			Text = name,
			Font = T.Font,
			TextSize = T.TextSize,
			TextColor3 = T.SubText,
			BackgroundColor3 = T.Element,
			BackgroundTransparency = 1,
			AutomaticSize = AUTO_X,
			Size = UDim2.new(0, 0, 0, 26),
			LayoutOrder = #tabs + 1,
			Parent = tabScroll,
		})
		corner(btn, 7)
		padding(btn, 12, 0, 12, 0)
		local line = new("Frame", {
			BackgroundColor3 = T.Accent,
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 8, 1, -2),
			Size = UDim2.new(1, -16, 0, 2),
			Parent = btn,
		})
		corner(line, 1)

		local page = new("ScrollingFrame", {
			Name = "Page_" .. name,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = AUTO_Y,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = T.Stroke,
			ScrollBarImageTransparency = 0.3,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			VerticalScrollBarInset = Enum.ScrollBarInset.None,
			ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
			Visible = false,
			Parent = pages,
		})
		padding(page, 8, 8, 10, 8)
		listLayout(page, 6)
		ctx.Pages[#ctx.Pages + 1] = page
		page.ScrollingEnabled = ctx.LockCount == 0

		local tab = setmetatable({ _ctx = ctx, _frame = page, _order = 0 }, ContainerMT)
		tab.Name = name
		tab.Button = btn
		tab.Page = page
		tab.Line = line
		function tab:Select()
			selectTab(tab)
		end
		tabs[#tabs + 1] = tab

		maid:Add(btn.MouseEnter:Connect(function()
			if currentTab ~= tab then
				tween(btn, { TextColor3 = T.Text })
			end
		end))
		maid:Add(btn.MouseLeave:Connect(function()
			if currentTab ~= tab then
				tween(btn, { TextColor3 = T.SubText })
			end
		end))
		maid:Add(btn.Activated:Connect(function()
			selectTab(tab)
		end))
		if #tabs == 1 then
			selectTab(tab)
		end
		return tab
	end

	function Window:SelectTab(t)
		if type(t) == "number" then
			t = tabs[t]
		elseif type(t) == "string" then
			local found
			for _, x in ipairs(tabs) do
				if x.Name == t then
					found = x
					break
				end
			end
			t = found
		end
		selectTab(t)
	end
	function Window:Show()
		setVisible(true)
	end
	function Window:Hide()
		setVisible(false)
	end
	function Window:Toggle()
		setVisible(not visible)
	end
	function Window:IsVisible()
		return visible
	end
	function Window:SetTitle(t)
		title = tostring(t)
		titleLbl.Text = title
		bubble.Text = string.upper(string.sub(title, 1, 1))
	end
	function Window:SetScale(s)
		scaleTarget = math.clamp(tonumber(s) or scaleTarget, 0.5, 2)
		if visible then
			tween(uiScale, { Scale = scaleTarget })
		end
	end
	function Window:Notify(c)
		return Library:Notify(c)
	end
	function Window:IsDestroyed()
		return ctx.Destroyed
	end
	function Window:Destroy()
		if ctx.Destroyed then
			return
		end
		ctx.Destroyed = true
		if registry and registry[guiName] == Window then
			registry[guiName] = nil
		end
		for i, w2 in ipairs(Library._windows) do
			if w2 == Window then
				table.remove(Library._windows, i)
				break
			end
		end
		maid:Destroy()
		if type(cfg.OnDestroy) == "function" then
			pcall(cfg.OnDestroy)
		end
	end

	maid:Add(minBtn.Activated:Connect(function()
		setVisible(false)
	end))
	maid:Add(closeBtn.Activated:Connect(function()
		if type(cfg.OnClose) == "function" then
			fire(ctx, cfg.OnClose)
		end
		if cfg.CloseDestroys == false then
			setVisible(false)
		else
			Window:Destroy()
		end
	end))
	if typeof(cfg.ToggleKey) == "EnumItem" then
		maid:Add(UserInputService.InputBegan:Connect(function(input, processed)
			if not processed and input.KeyCode == cfg.ToggleKey then
				setVisible(not visible)
			end
		end))
	end

	Library._windows[#Library._windows + 1] = Window
	if registry then
		registry[guiName] = Window
	end
	setVisible(true)
	return Window
end

function Library:Destroy()
	local copy = {}
	for i, w in ipairs(Library._windows) do
		copy[i] = w
	end
	for _, w in ipairs(copy) do
		w:Destroy()
	end
	if Library._notify then
		pcall(function()
			Library._notify.Gui:Destroy()
		end)
		Library._notify = nil
	end
end
Library.DestroyAll = Library.Destroy

return Library
