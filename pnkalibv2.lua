IKAI = true
if IKAI then
	local UIConnections = {}
	local function Track(conn)
		table.insert(UIConnections, conn)
		return conn
	end
	local UI_GUI_NAMES = {"RippleHUBLIB", "Ripple", "RippleNotify", "RippleToggleBtn"}
	local function CleanupUI()
		for _, c in ipairs(UIConnections) do
			pcall(function() c:Disconnect() end)
		end
		UIConnections = {}
		local cg = game:GetService("CoreGui")
		for _, name in ipairs(UI_GUI_NAMES) do
			local g = cg:FindFirstChild(name)
			while g do
				g:Destroy()
				g = cg:FindFirstChild(name)
			end
		end
	end
	if getgenv and getgenv().SwitchUI_Cleanup then
		pcall(getgenv().SwitchUI_Cleanup)
	end
	CleanupUI()
	if getgenv then getgenv().SwitchUI_Cleanup = CleanupUI end
	local UserInputService = game:GetService("UserInputService")
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")
	local LocalPlayer = game:GetService("Players").LocalPlayer
	local Mouse = LocalPlayer:GetMouse()
	local tween = game:GetService("TweenService")
	local Red = {RainbowColorValue = 0, HueSelectionPosition = 0}
	local LogoButton = [[7040391851]]
	local function Tween(instance, properties,style,wa)
		if style == nil or "" then
			return Back
		end
		tween:Create(instance,TweenInfo.new(wa,Enum.EasingStyle[style]),{properties}):Play()
	end
	local ActualTypes = {
		RoundFrame = "ImageLabel",
		Shadow = "ImageLabel",
		Circle = "ImageLabel",
		CircleButton = "ImageButton",
		Frame = "Frame",
		Label = "TextLabel",
		Button = "TextButton",
		SmoothButton = "ImageButton",
		Box = "TextBox",
		ScrollingFrame = "ScrollingFrame",
		Menu = "ImageButton",
		NavBar = "ImageButton"
	}
	local Properties = {
		RoundFrame = {
			BackgroundTransparency = 1,
			Image = "http://www.roblox.com/asset/?id=5554237731",
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(3,3,297,297)
		},
		SmoothButton = {
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Image = "http://www.roblox.com/asset/?id=5554237731",
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(3,3,297,297)
		},
		Shadow = {
			Name = "Shadow",
			BackgroundTransparency = 1,
			Image = "http://www.roblox.com/asset/?id=5554236805",
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(23,23,277,277),
			Size = UDim2.fromScale(1,1) + UDim2.fromOffset(30,30),
			Position = UDim2.fromOffset(-15,-15)
		},
		Circle = {
			BackgroundTransparency = 1,
			Image = "http://www.roblox.com/asset/?id=5554831670"
		},
		CircleButton = {
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Image = "http://www.roblox.com/asset/?id=5554831670"
		},
		Frame = {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1,1)
		},
		Label = {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(5,0),
			Size = UDim2.fromScale(1,1) - UDim2.fromOffset(5,0),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left
		},
		Button = {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(5,0),
			Size = UDim2.fromScale(1,1) - UDim2.fromOffset(5,0),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left
		},
		Box = {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(5,0),
			Size = UDim2.fromScale(1,1) - UDim2.fromOffset(5,0),
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left
		},
		ScrollingFrame = {
			BackgroundTransparency = 1,
			ScrollBarThickness = 0,
			CanvasSize = UDim2.fromScale(0,0),
			Size = UDim2.fromScale(1,1)
		},
		Menu = {
			Name = "More",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Image = "http://www.roblox.com/asset/?id=5555108481",
			Size = UDim2.fromOffset(20,20),
			Position = UDim2.fromScale(1,0.5) - UDim2.fromOffset(25,10)
		},
		NavBar = {
			Name = "SheetToggle",
			Image = "http://www.roblox.com/asset/?id=5576439039",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(20,20),
			Position = UDim2.fromOffset(5,5),
			AutoButtonColor = false
		}
	}
	local Types = {
		"RoundFrame",
		"Shadow",
		"Circle",
		"CircleButton",
		"Frame",
		"Label",
		"Button",
		"SmoothButton",
		"Box",
		"ScrollingFrame",
		"Menu",
		"NavBar"
	}
	function FindType(String)
		for _, Type in next, Types do
			if Type:sub(1, #String):lower() == String:lower() then
				return Type
			end
		end
		return false
	end
	local Objects = {}
	function Objects.new(Type)
		local TargetType = FindType(Type)
		if TargetType then
			local NewImage = Instance.new(ActualTypes[TargetType])
			if Properties[TargetType] then
				for Property, Value in next, Properties[TargetType] do
					NewImage[Property] = Value
				end
			end
			return NewImage
		else
			return Instance.new(Type)
		end
	end
	local function GetXY(GuiObject)
		local Max, May = GuiObject.AbsoluteSize.X, GuiObject.AbsoluteSize.Y
		local Px, Py = math.clamp(Mouse.X - GuiObject.AbsolutePosition.X, 0, Max), math.clamp(Mouse.Y - GuiObject.AbsolutePosition.Y, 0, May)
		return Px/Max, Py/May
	end
	local function CircleAnim(GuiObject, EndColour, StartColour)
		local PX, PY = GetXY(GuiObject)
		local Circle = Objects.new("Circle")
		Circle.Size = UDim2.fromScale(0,0)
		Circle.Position = UDim2.fromScale(PX,PY)
		Circle.ImageColor3 = StartColour or GuiObject.ImageColor3
		Circle.ZIndex = 200
		Circle.Parent = GuiObject
		local Size = GuiObject.AbsoluteSize.X
		TweenService:Create(Circle, TweenInfo.new(0.5), {Position = UDim2.fromScale(PX,PY) - UDim2.fromOffset(Size/2,Size/2), ImageTransparency = 1, ImageColor3 = EndColour, Size = UDim2.fromOffset(Size,Size)}):Play()
		spawn(function()
			wait(0.5)
			Circle:Destroy()
		end)
	end
	local function MakeDraggable(topbarobject, object)
		local Dragging = nil
		local DragInput = nil
		local DragStart = nil
		local StartPosition = nil
		local function Update(input)
			local Delta = input.Position - DragStart
			local pos =
				UDim2.new(
					StartPosition.X.Scale,
					StartPosition.X.Offset + Delta.X,
					StartPosition.Y.Scale,
					StartPosition.Y.Offset + Delta.Y
				)
			local Tween = TweenService:Create(object, TweenInfo.new(0.2), {Position = pos})
			Tween:Play()
		end
		topbarobject.InputBegan:Connect(
			function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					Dragging = true
					DragStart = input.Position
					StartPosition = object.Position
					input.Changed:Connect(
						function()
							if input.UserInputState == Enum.UserInputState.End then
								Dragging = false
							end
						end
					)
				end
			end
		)
		topbarobject.InputChanged:Connect(
			function(input)
				if
					input.UserInputType == Enum.UserInputType.MouseMovement or
					input.UserInputType == Enum.UserInputType.Touch
				then
					DragInput = input
				end
			end
		)
		Track(UserInputService.InputChanged:Connect(
			function(input)
				if input == DragInput and Dragging then
					Update(input)
				end
			end
		))
	end
	local LucideIcons = {
		["lucide-activity"] = "rbxassetid://10709752035",
		["lucide-anchor"] = "rbxassetid://10709761530",
		["lucide-axe"] = "rbxassetid://10709769508",
		["lucide-bomb"] = "rbxassetid://10709781460",
		["lucide-bug"] = "rbxassetid://10709782845",
		["lucide-check"] = "rbxassetid://10709790644",
		["lucide-cog"] = "rbxassetid://10709810948",
		["lucide-coins"] = "rbxassetid://10709811110",
		["lucide-compass"] = "rbxassetid://10709811445",
		["lucide-crown"] = "rbxassetid://10709818626",
		["lucide-droplet"] = "rbxassetid://10723344432",
		["lucide-droplets"] = "rbxassetid://10734883356",
		["lucide-electricity"] = "rbxassetid://10723345749",
		["lucide-eye"] = "rbxassetid://10723346959",
		["lucide-flame"] = "rbxassetid://10723376114",
		["lucide-gem"] = "rbxassetid://10723396000",
		["lucide-ghost"] = "rbxassetid://10723396107",
		["lucide-gift"] = "rbxassetid://10723396402",
		["lucide-globe"] = "rbxassetid://10723404337",
		["lucide-hand"] = "rbxassetid://10723405649",
		["lucide-hand-metal"] = "rbxassetid://10723405508",
		["lucide-home"] = "rbxassetid://10723407389",
		["lucide-info"] = "rbxassetid://10723415903",
		["lucide-key"] = "rbxassetid://10723416652",
		["lucide-layout-dashboard"] = "rbxassetid://10723424646",
		["lucide-list"] = "rbxassetid://10723433811",
		["lucide-lock"] = "rbxassetid://10723434711",
		["lucide-map"] = "rbxassetid://10734886202",
		["lucide-map-pin"] = "rbxassetid://10734886004",
		["lucide-mountain"] = "rbxassetid://10734897956",
		["lucide-package"] = "rbxassetid://10734909540",
		["lucide-play"] = "rbxassetid://10734923549",
		["lucide-power"] = "rbxassetid://10734930466",
		["lucide-refresh-cw"] = "rbxassetid://10734933222",
		["lucide-rocket"] = "rbxassetid://10734934585",
		["lucide-sailboat"] = "rbxassetid://10734941354",
		["lucide-search"] = "rbxassetid://10734943674",
		["lucide-settings"] = "rbxassetid://10734950309",
		["lucide-shield"] = "rbxassetid://10734951847",
		["lucide-shopping-cart"] = "rbxassetid://10734952479",
		["lucide-skull"] = "rbxassetid://10734962068",
		["lucide-star"] = "rbxassetid://10734966248",
		["lucide-sword"] = "rbxassetid://10734975486",
		["lucide-swords"] = "rbxassetid://10734975692",
		["lucide-target"] = "rbxassetid://10734977012",
		["lucide-trophy"] = "rbxassetid://10747363809",
		["lucide-user"] = "rbxassetid://10747373176",
		["lucide-users"] = "rbxassetid://10747373426",
		["lucide-waves"] = "rbxassetid://10747376931",
		["lucide-wifi"] = "rbxassetid://10747382504",
		["lucide-wrench"] = "rbxassetid://10747383470",
		["lucide-x"] = "rbxassetid://10747384394",
	}
	local LucideFull = nil
	local function ResolveIcon(icon)
		if icon == nil or icon == "" then return "" end
		local s = tostring(icon)
		if LucideIcons[s] then return LucideIcons[s] end
		if s:sub(1, 7) == "lucide-" then
			if LucideFull == nil then
				LucideFull = {}
				pcall(function()
					LucideFull = loadstring(game:HttpGet("https://raw.githubusercontent.com/Van1a/neriumR/refs/heads/main/components/icons.lua"))().assets or {}
				end)
			end
			return LucideFull[s] or ""
		end
		if s:find("rbxassetid://", 1, true) or s:find("http", 1, true) then return s end
		return "rbxassetid://" .. s
	end
	library = {}
	function library:Destroy()
		CleanupUI()
	end
	library.Icons = LucideIcons
	library.ResolveIcon = ResolveIcon
	local StarterGui = game:GetService("StarterGui")
	function library:Notify(title, content, duration, opts)
		opts = opts or {}
		local function ParseButton(b)
			if b == nil then return nil, nil end
			if type(b) == "table" then return tostring(b[1] or ""), b[2] end
			return tostring(b), nil
		end
		local payload = {
			Title = tostring(title or ""),
			Text = tostring(content or ""),
			Duration = duration or 4,
			Icon = opts.Icon,
		}
		local b1, cb1 = ParseButton(opts.Button1)
		local b2, cb2 = ParseButton(opts.Button2)
		if b1 or b2 then
			local bf = Instance.new("BindableFunction")
			bf.OnInvoke = function(pressed)
				if b1 and pressed == b1 and cb1 then pcall(cb1)
				elseif b2 and pressed == b2 and cb2 then pcall(cb2) end
			end
			payload.Callback = bf
			payload.Button1 = b1
			payload.Button2 = b2
		end
		pcall(function()
			StarterGui:SetCore("SendNotification", payload)
		end)
		local n = {}
		function n:Close() end
		return n
	end
	function library:Window(text,text2,text3,logo,keybind)
		local uihide = false
		local abc = false
		local logo = logo or 0
		local currentpage = ""
		local keybind = keybind or Enum.KeyCode.RightControl
		local yoo = string.gsub(tostring(keybind),"Enum.KeyCode.","")
		CleanupUI()
		local RippleHUBLIB = Instance.new("ScreenGui")
		RippleHUBLIB.Name = "RippleHUBLIB"
		RippleHUBLIB.Parent = game.CoreGui
		RippleHUBLIB.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		local Main = Instance.new("Frame")
		Main.Name = "Main"
		Main.Parent = RippleHUBLIB
		Main.ClipsDescendants = true
		Main.AnchorPoint = Vector2.new(0.5,0.5)
		Main.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		Main.Position = UDim2.new(0.5, 0, 0.5, 0)
		Main.Size = UDim2.new(0, 0, 0, 0)
		Main:TweenSize(UDim2.new(0, 656, 0, 300),"Out","Quad",0.4,true)
		local MCNR = Instance.new("UICorner")
		MCNR.Name = "MCNR"
		MCNR.Parent = Main
		local Top = Instance.new("Frame")
		Top.Name = "Top"
		Top.Parent = Main
		Top.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
		Top.Size = UDim2.new(0, 656, 0, 27)
		local TCNR = Instance.new("UICorner")
		TCNR.Name = "TCNR"
		TCNR.Parent = Top
		local Logo = Instance.new("ImageLabel")
		Logo.Name = "Logo"
		Logo.Parent = Top
		Logo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Logo.BackgroundTransparency = 1.000
		Logo.Position = UDim2.new(0, 14, 0, 2)
		Logo.Size = UDim2.new(0, 23, 0, 23)
		Logo.Image = ResolveIcon(logo)
		local Name = Instance.new("TextLabel")
		Name.Name = "Name"
		Name.Parent = Top
		Name.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Name.BackgroundTransparency = 1.000
		Name.Position = UDim2.new(0.0609756112, 5, 0, 0.5)
		Name.Size = UDim2.new(0, 61, 0, 27)
		Name.Font = Enum.Font.GothamSemibold
		Name.Text = text
		Name.TextColor3 = Color3.fromRGB(225, 225, 225)
		Name.TextSize = 16.000
		local Hub = Instance.new("TextLabel")
		Hub.Name = "Hub"
		Hub.Parent = Top
		Hub.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Hub.BackgroundTransparency = 1.000
		Hub.Position = UDim2.new(0, 105, 0, 0.5)
		Hub.Size = UDim2.new(0, 81, 0, 27)
		Hub.Font = Enum.Font.GothamSemibold
		Hub.Text = text2
		Hub.TextColor3 = _G.Color
		Hub.TextSize = 16.000
		Hub.TextXAlignment = Enum.TextXAlignment.Left
		local Ver = Instance.new("TextLabel")
		Ver.Name = "Ver"
		Ver.Parent = Top
		Ver.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Ver.BackgroundTransparency = 1.000
		Ver.Position = UDim2.new(0.847561002, 0, 0, 1)
		Ver.Size = UDim2.new(0, 47, 0, 27)
		Ver.Font = Enum.Font.GothamSemibold
		Ver.Text = text3
		Ver.TextColor3 = _G.Color
		Ver.TextSize = 15.000
		local BindButton = Instance.new("TextButton")
		BindButton.Name = "BindButton"
		BindButton.Parent = Top
		BindButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		BindButton.BackgroundTransparency = 1.000
		BindButton.Position = UDim2.new(0.227561002, 0, 0, 1)
		BindButton.Size = UDim2.new(0, 100, 0, 27)
		BindButton.Font = Enum.Font.GothamSemibold
		BindButton.Text = "[ "..string.gsub(tostring(keybind),"Enum.KeyCode.","").." ]"
		BindButton.TextColor3 = Color3.fromRGB(100, 100, 100)
		BindButton.TextSize = 11.000
		BindButton.MouseButton1Click:Connect(function ()
			BindButton.Text = "[ ... ]"
			local inputwait = game:GetService("UserInputService").InputBegan:wait()
			local shiba = inputwait.KeyCode == Enum.KeyCode.Unknown and inputwait.UserInputType or inputwait.KeyCode
			if shiba.Name ~= "Focus" and shiba.Name ~= "MouseMovement" then
				BindButton.Text = "[ "..shiba.Name.." ]"
				yoo = shiba.Name
			end
		end)
		do  local ui =  game:GetService("CoreGui"):FindFirstChild("Ripple")  if ui then ui:Destroy() end end
		local Luna = Instance.new("ScreenGui")
		local ToggleFrameUi = Instance.new("Frame")
		local UICorner = Instance.new("UICorner")
		local ToggleImgUi = Instance.new("ImageLabel")
		local Uitoggle = Instance.new("TextLabel")
		local Yedhee = Instance.new("TextLabel")
		local SearchStroke = Instance.new("UIStroke")
		Luna.Name = "Ripple"
		Luna.Parent = game.CoreGui
		Luna.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		Luna.Enabled = false
		ToggleFrameUi.Name = "ToggleFrameUi"
		ToggleFrameUi.Parent = Luna
		ToggleFrameUi.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
		ToggleFrameUi.Position = UDim2.new(0.883, -60,0.282, 0)
		ToggleFrameUi.Size = UDim2.new(0, 198, 0, 48)
		SearchStroke.Thickness = 1
		SearchStroke.Name = ""
		SearchStroke.Parent = ToggleFrameUi
		SearchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		SearchStroke.LineJoinMode = Enum.LineJoinMode.Round
		SearchStroke.Color = _G.Color
		SearchStroke.Transparency = 0
		UICorner.CornerRadius = UDim.new(0, 4)
		UICorner.Parent = ToggleFrameUi
		ToggleImgUi.Name = "ToggleImgUi"
		ToggleImgUi.Parent = ToggleFrameUi
		ToggleImgUi.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
		ToggleImgUi.BackgroundTransparency = 1
		ToggleImgUi.Position = UDim2.new(0.0454545468, 0, 0.125000313, 0)
		ToggleImgUi.Size = UDim2.new(0, 35, 0, 35)
		ToggleImgUi.Image = "rbxassetid://9606070311"
		Uitoggle.Name = "Uitoggle"
		Uitoggle.Parent = ToggleFrameUi
		Uitoggle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Uitoggle.BackgroundTransparency = 1.000
		Uitoggle.Position = UDim2.new(0.25757575, 0, 0, 0)
		Uitoggle.Size = UDim2.new(0, 137, 0, 25)
		Uitoggle.Font = Enum.Font.GothamSemibold
		Uitoggle.Text = "Ui Toggle :"
		Uitoggle.TextColor3 = Color3.fromRGB(255, 255, 255)
		Uitoggle.TextSize = 12.000
		Yedhee.Name = "Yedhee"
		Yedhee.Parent = ToggleFrameUi
		Yedhee.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Yedhee.BackgroundTransparency = 1.000
		Yedhee.Position = UDim2.new(0.25757575, 0, 0.479166657, 0)
		Yedhee.Size = UDim2.new(0, 137, 0, 25)
		Yedhee.Font = Enum.Font.GothamSemibold
		Yedhee.Text = "Lable"
		Yedhee.TextColor3 = Color3.fromRGB(255, 255, 255)
		Yedhee.TextSize = 12.000
		spawn(function()
			while Yedhee.Parent and wait() do
				Yedhee.Text = '['..yoo..']'
			end
		end)
	Yedhee.TextTransparency = 1
		Uitoggle.TextTransparency = 1
		ToggleImgUi.ImageTransparency = 1
		ToggleFrameUi.BackgroundTransparency = 1.000
		SearchStroke.Transparency = 1
		local function SetUIHidden(hide)
			hide = hide and true or false
			if hide == uihide then return end
			uihide = hide
			if hide then
				Main:TweenSize(UDim2.new(0, 0, 0, 0), "In", "Quad", 0.4, true)
			else
				Main:TweenSize(UDim2.new(0, 656, 0, 300), "Out", "Quad", 0.4, true)
			end
		end
		Track(UserInputService.InputBegan:Connect(function(input)
			if input.KeyCode == Enum.KeyCode[yoo] then
				SetUIHidden(not uihide)
			end
		end))
		local ToggleBtnGui = Instance.new("ScreenGui")
		ToggleBtnGui.Name = "RippleToggleBtn"
		ToggleBtnGui.Parent = game:GetService("CoreGui")
		ToggleBtnGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		local ToggleBtn = Instance.new("TextButton")
		ToggleBtn.Name = "ToggleBtn"
		ToggleBtn.Parent = ToggleBtnGui
		ToggleBtn.Size = UDim2.new(0, 40, 0, 40)
		ToggleBtn.Position = UDim2.new(0, 10, 0.5, -20)
		ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
		ToggleBtn.Font = Enum.Font.GothamBold
		ToggleBtn.Text = "UI"
		ToggleBtn.TextSize = 12
		ToggleBtn.TextColor3 = _G.Color or Color3.fromRGB(68, 202, 186)
		local TBCorner = Instance.new("UICorner")
		TBCorner.CornerRadius = UDim.new(0, 8)
		TBCorner.Parent = ToggleBtn
		local TBStroke = Instance.new("UIStroke")
		TBStroke.Color = _G.Color or Color3.fromRGB(68, 202, 186)
		TBStroke.Thickness = 1
		TBStroke.Parent = ToggleBtn
		ToggleBtn.MouseButton1Click:Connect(function() SetUIHidden(not uihide) end)
		MakeDraggable(ToggleBtn, ToggleBtn)
		MakeDraggable(ToggleFrameUi,ToggleFrameUi)
		local Tab = Instance.new("Frame")
		Tab.Name = "Tab"
		Tab.Parent = Main
		Tab.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
		Tab.Position = UDim2.new(0, 5, 0, 30)
		Tab.Size = UDim2.new(0, 150, 0, 265)
		local TCNR = Instance.new("UICorner")
		TCNR.Name = "TCNR"
		TCNR.Parent = Tab
		local ScrollTab = Instance.new("ScrollingFrame")
		ScrollTab.Name = "ScrollTab"
		ScrollTab.Parent = Tab
		ScrollTab.Active = true
		ScrollTab.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ScrollTab.BackgroundTransparency = 1.000
		ScrollTab.Size = UDim2.new(0, 150, 0, 265)
		ScrollTab.CanvasSize = UDim2.new(0, 0, 0, 0)
		ScrollTab.ScrollBarThickness = 0
		local PLL = Instance.new("UIListLayout")
		PLL.Name = "PLL"
		PLL.Parent = ScrollTab
		PLL.SortOrder = Enum.SortOrder.LayoutOrder
		PLL.Padding = UDim.new(0, 15)
		local PPD = Instance.new("UIPadding")
		PPD.Name = "PPD"
		PPD.Parent = ScrollTab
		PPD.PaddingLeft = UDim.new(0, 10)
		PPD.PaddingTop = UDim.new(0, 10)
		local Page = Instance.new("Frame")
		Page.Name = "Page"
		Page.Parent = Main
		Page.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
		Page.Position = UDim2.new(0.245426834, 0, 0, 30)
		Page.Size = UDim2.new(0, 490, 0, 265)
		local PCNR = Instance.new("UICorner")
		PCNR.Name = "PCNR"
		PCNR.Parent = Page
		local MainPage = Instance.new("Frame")
		MainPage.Name = "MainPage"
		MainPage.Parent = Page
		MainPage.ClipsDescendants = true
		MainPage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		MainPage.BackgroundTransparency = 1.000
		MainPage.Size = UDim2.new(0, 490, 0, 365)
		local PageList = Instance.new("Folder")
		PageList.Name = "PageList"
		PageList.Parent = MainPage
		local UIPageLayout = Instance.new("UIPageLayout")
		UIPageLayout.Parent = PageList
		UIPageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UIPageLayout.EasingDirection = Enum.EasingDirection.InOut
		UIPageLayout.EasingStyle = Enum.EasingStyle.Quad
		UIPageLayout.FillDirection = Enum.FillDirection.Vertical
		UIPageLayout.Padding = UDim.new(0, 15)
		UIPageLayout.TweenTime = 0.400
		UIPageLayout.GamepadInputEnabled = false
		UIPageLayout.ScrollWheelInputEnabled = false
		UIPageLayout.TouchInputEnabled = false
		MakeDraggable(Top,Main)
		local uitab = {}
		function uitab:Destroy()
			CleanupUI()
		end
		function uitab:Close()
			CleanupUI()
		end
		function uitab:Show() SetUIHidden(false) end
		function uitab:Hide() SetUIHidden(true) end
		function uitab:Toggle() SetUIHidden(not uihide) end
		function uitab:IsOpen() return not uihide end
		function uitab:GetToggleButton() return ToggleBtn end
		function uitab:Notify(title, content, duration, opts)
			return library:Notify(title, content, duration, opts)
		end
		function uitab:Dialog(title, content, buttons)
			local accent = _G.Color or Color3.fromRGB(68, 202, 186)
			if type(buttons) ~= "table" or #buttons == 0 then buttons = {{"OK"}} end
			local Overlay = Instance.new("TextButton")
			local Box = Instance.new("Frame")
			local BoxCorner = Instance.new("UICorner")
			local BoxStroke = Instance.new("UIStroke")
			local TitleL = Instance.new("TextLabel")
			local ContentL = Instance.new("TextLabel")
			local Row = Instance.new("Frame")
			local RowLayout = Instance.new("UIListLayout")
			Overlay.Name = "DialogOverlay"
			Overlay.Parent = Main
			Overlay.AutoButtonColor = false
			Overlay.Text = ""
			Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			Overlay.BackgroundTransparency = 1
			Overlay.BorderSizePixel = 0
			Overlay.Size = UDim2.new(1, 0, 1, 0)
			Overlay.ZIndex = 100
			Box.Name = "Box"
			Box.Parent = Overlay
			Box.AnchorPoint = Vector2.new(0.5, 0.5)
			Box.Position = UDim2.new(0.5, 0, 0.5, 0)
			Box.Size = UDim2.new(0, 320, 0, 130)
			Box.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
			Box.BackgroundTransparency = 1
			Box.BorderSizePixel = 0
			Box.ZIndex = 101
			BoxCorner.CornerRadius = UDim.new(0, 6)
			BoxCorner.Parent = Box
			BoxStroke.Parent = Box
			BoxStroke.Color = accent
			BoxStroke.Thickness = 1
			BoxStroke.Transparency = 1
			TitleL.Name = "Title"
			TitleL.Parent = Box
			TitleL.BackgroundTransparency = 1
			TitleL.Position = UDim2.new(0, 14, 0, 8)
			TitleL.Size = UDim2.new(1, -28, 0, 22)
			TitleL.Font = Enum.Font.GothamBold
			TitleL.Text = tostring(title or "")
			TitleL.TextColor3 = accent
			TitleL.TextSize = 16
			TitleL.TextXAlignment = Enum.TextXAlignment.Left
			TitleL.TextTransparency = 1
			TitleL.ZIndex = 102
			ContentL.Name = "Content"
			ContentL.Parent = Box
			ContentL.BackgroundTransparency = 1
			ContentL.Position = UDim2.new(0, 14, 0, 34)
			ContentL.Size = UDim2.new(1, -28, 0, 50)
			ContentL.Font = Enum.Font.GothamSemibold
			ContentL.Text = tostring(content or "")
			ContentL.TextColor3 = Color3.fromRGB(225, 225, 225)
			ContentL.TextSize = 13
			ContentL.TextWrapped = true
			ContentL.TextXAlignment = Enum.TextXAlignment.Left
			ContentL.TextYAlignment = Enum.TextYAlignment.Top
			ContentL.TextTransparency = 1
			ContentL.ZIndex = 102
			Row.Name = "Buttons"
			Row.Parent = Box
			Row.BackgroundTransparency = 1
			Row.Position = UDim2.new(0, 14, 1, -42)
			Row.Size = UDim2.new(1, -28, 0, 30)
			Row.ZIndex = 102
			RowLayout.Parent = Row
			RowLayout.FillDirection = Enum.FillDirection.Horizontal
			RowLayout.SortOrder = Enum.SortOrder.LayoutOrder
			RowLayout.Padding = UDim.new(0, 8)
			RowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
			local fade = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local closed = false
			local dlg = {}
			function dlg:Close()
				if closed then return end
				closed = true
				TweenService:Create(Overlay, fade, {BackgroundTransparency = 1}):Play()
				TweenService:Create(Box, fade, {BackgroundTransparency = 1}):Play()
				TweenService:Create(BoxStroke, fade, {Transparency = 1}):Play()
				task.delay(0.25, function() pcall(function() Overlay:Destroy() end) end)
			end
			local btnWidth = math.floor((320 - 28 - 8 * (#buttons - 1)) / #buttons)
			btnWidth = math.min(btnWidth, 120)
			for i, spec in ipairs(buttons) do
				local label, cb
				if type(spec) == "table" then label, cb = spec[1] or spec.Text, spec[2] or spec.Callback else label = spec end
				local B = Instance.new("TextButton")
				local BC = Instance.new("UICorner")
				B.Name = "DialogButton"
				B.Parent = Row
				B.LayoutOrder = i
				B.AutoButtonColor = false
				B.BackgroundColor3 = (i == #buttons) and accent or Color3.fromRGB(55, 55, 55)
				B.Size = UDim2.new(0, btnWidth, 0, 30)
				B.Font = Enum.Font.GothamSemibold
				B.Text = tostring(label or "OK")
				B.TextColor3 = Color3.fromRGB(255, 255, 255)
				B.TextSize = 14
				B.ZIndex = 103
				BC.CornerRadius = UDim.new(0, 5)
				BC.Parent = B
				B.MouseButton1Click:Connect(function()
					dlg:Close()
					if cb then pcall(cb) end
				end)
			end
			TweenService:Create(Overlay, fade, {BackgroundTransparency = 0.45}):Play()
			TweenService:Create(Box, fade, {BackgroundTransparency = 0}):Play()
			TweenService:Create(BoxStroke, fade, {Transparency = 0}):Play()
			TweenService:Create(TitleL, fade, {TextTransparency = 0}):Play()
			TweenService:Create(ContentL, fade, {TextTransparency = 0}):Play()
			return dlg
		end
		function uitab:Tab(text,logo1)
			local TabButton = Instance.new("TextButton")
			TabButton.Parent = ScrollTab
			TabButton.Name = text.."Server"
			TabButton.Text = text
			TabButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			TabButton.BackgroundTransparency = 1.000
			TabButton.Size = UDim2.new(0, 130, 0, 23)
			TabButton.Font = Enum.Font.GothamSemibold
			TabButton.TextColor3 = Color3.fromRGB(225, 225, 225)
			TabButton.TextSize = 15.000
			TabButton.TextTransparency = 0.500
			local IDK = Instance.new("ImageLabel")
			IDK.Name = "LogoIDK"
			IDK.Parent = TabButton
			IDK.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			IDK.BackgroundTransparency = 1.000
			IDK.Position = UDim2.new(0, 0, 0, 1)
			IDK.Size = UDim2.new(0, 20, 0, 20)
			IDK.Image = ResolveIcon(logo1)
			local MainFramePage = Instance.new("ScrollingFrame")
			MainFramePage.Name = text.."_Page"
			MainFramePage.Parent = PageList
			MainFramePage.Active = true
			MainFramePage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			MainFramePage.BackgroundTransparency = 1.000
			MainFramePage.BorderSizePixel = 0
			MainFramePage.Size = UDim2.new(0, 490, 0, 265)
			MainFramePage.CanvasSize = UDim2.new(0, 0, 0, 0)
			MainFramePage.ScrollBarThickness = 0
			local UIPadding = Instance.new("UIPadding")
			local UIListLayout = Instance.new("UIListLayout")
			UIPadding.Parent = MainFramePage
			UIPadding.PaddingLeft = UDim.new(0, 10)
			UIPadding.PaddingTop = UDim.new(0, 10)
			UIListLayout.Padding = UDim.new(0,15)
			UIListLayout.Parent = MainFramePage
			UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
			TabButton.MouseButton1Click:Connect(function()
				for i,v in next, ScrollTab:GetChildren() do
					if v:IsA("TextButton") then
						TweenService:Create(
							v,
							TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
							{TextTransparency = 0.5}
						):Play()
					end
					TweenService:Create(
						TabButton,
						TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
						{TextTransparency = 0}
					):Play()
				end
				for i,v in next, PageList:GetChildren() do
					currentpage = string.gsub(TabButton.Name,"Server","").."_Page"
					if v.Name == currentpage then
						UIPageLayout:JumpTo(v)
					end
				end
			end)
			if abc == false then
				for i,v in next, ScrollTab:GetChildren() do
					if v:IsA("TextButton") then
						TweenService:Create(
							v,
							TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
							{TextTransparency = 0.5}
						):Play()
					end
					TweenService:Create(
						TabButton,
						TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
						{TextTransparency = 0}
					):Play()
				end
				UIPageLayout:JumpToIndex(1)
				abc = true
			end
			Track(game:GetService("RunService").Stepped:Connect(function()
				pcall(function()
					MainFramePage.CanvasSize = UDim2.new(0,0,0,UIListLayout.AbsoluteContentSize.Y + 20)
					ScrollTab.CanvasSize = UDim2.new(0,0,0,PLL.AbsoluteContentSize.Y + 20)
				end)
			end))
			local main = {}
			function main:Button(text,callback)
				local Button = Instance.new("Frame")
				local UICorner = Instance.new("UICorner")
				local TextBtn = Instance.new("TextButton")
				local UICorner_2 = Instance.new("UICorner")
				local Black = Instance.new("Frame")
				local UICorner_3 = Instance.new("UICorner")
				local IMGBUTTON = Instance.new("ImageLabel")
				Button.Name = "Button"
				Button.Parent = MainFramePage
				Button.BackgroundColor3 = _G.Color
				Button.Size = UDim2.new(0, 470, 0, 31)
				UICorner.CornerRadius = UDim.new(0, 5)
				UICorner.Parent = Button
				TextBtn.Name = "TextBtn"
				TextBtn.Parent = Button
				TextBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
				TextBtn.Position = UDim2.new(0, 1, 0, 1)
				TextBtn.Size = UDim2.new(0, 468, 0, 29)
				TextBtn.AutoButtonColor = false
				TextBtn.Font = Enum.Font.GothamSemibold
				TextBtn.Text = text
				TextBtn.TextColor3 = Color3.fromRGB(225, 225, 225)
				TextBtn.TextSize = 15.000
				TextBtn.ClipsDescendants = true
				UICorner_2.CornerRadius = UDim.new(0, 5)
				UICorner_2.Parent = TextBtn
				IMGBUTTON.Name = "IconB"
				IMGBUTTON.Parent = TextBtn
				IMGBUTTON.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				IMGBUTTON.BackgroundTransparency = 1.000
				IMGBUTTON.Position = UDim2.new(0, 10, 0, 5)
				IMGBUTTON.Size = UDim2.new(0, 20, 0, 20)
				IMGBUTTON.Image = "http://www.roblox.com/asset/?id=9606312215"
				Black.Name = "Black"
				Black.Parent = Button
				Black.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				Black.BackgroundTransparency = 1.000
				Black.BorderSizePixel = 0
				Black.Position = UDim2.new(0, 1, 0, 1)
				Black.Size = UDim2.new(0, 468, 0, 29)
				UICorner_3.CornerRadius = UDim.new(0, 5)
				UICorner_3.Parent = Black
				TextBtn.MouseEnter:Connect(function()
					TweenService:Create(
						Black,
						TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
						{BackgroundTransparency = 0.7}
					):Play()
				end)
				TextBtn.MouseLeave:Connect(function()
					TweenService:Create(
						Black,
						TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
						{BackgroundTransparency = 1}
					):Play()
				end)
				TextBtn.MouseButton1Click:Connect(function()
					CircleAnim(TextBtn, Color3.fromRGB(255,255,255), Color3.fromRGB(255,255,255))
					TextBtn.TextSize = 1
					TweenService:Create(
						TextBtn,
						TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
						{TextSize = 15}
					):Play()
					callback()
				end)
				local btn = {}
				function btn:SetTitle(t) TextBtn.Text = tostring(t) end
				function btn:Fire() pcall(callback) end
				return btn
			end
			function main:Toggle(text,Imgidicon,config,callback)
				config = config or false
				local toggled = config
				local Toggle = Instance.new("Frame")
				local UICorner = Instance.new("UICorner")
				local Button = Instance.new("TextButton")
				local UICorner_2 = Instance.new("UICorner")
				local Label = Instance.new("TextLabel")
				local ToggleImage = Instance.new("Frame")
				local UICorner_3 = Instance.new("UICorner")
				local Circle = Instance.new("Frame")
				local UICorner_4 = Instance.new("UICorner")
				local imgLabelIcon = Instance.new("ImageLabel")
				Toggle.Name = "Toggle"
				Toggle.Parent = MainFramePage
				Toggle.BackgroundColor3 = Color3.fromRGB(255, 46, 46)
				Toggle.Size = UDim2.new(0, 470, 0, 31)
				UICorner.CornerRadius = UDim.new(0, 5)
				UICorner.Parent = Toggle
				Button.Name = "Button"
				Button.Parent = Toggle
				Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
				Button.Position = UDim2.new(0, 1, 0, 1)
				Button.Size = UDim2.new(0, 468, 0, 29)
				Button.AutoButtonColor = false
				Button.Font = Enum.Font.SourceSans
				Button.Text = ""
				Button.TextColor3 = Color3.fromRGB(0, 0, 0)
				Button.TextSize = 11.000
				UICorner_2.CornerRadius = UDim.new(0, 5)
				UICorner_2.Parent = Button
				Label.Name = "Label"
				Label.Parent = Toggle
				Label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Label.BackgroundTransparency = 1.000
				Label.Position = UDim2.new(0, 1, 0, 1)
				Label.Size = UDim2.new(0, 468, 0, 29)
				Label.Font = Enum.Font.GothamSemibold
				Label.Text = text
				Label.TextColor3 = Color3.fromRGB(225, 225, 225)
				Label.TextSize = 15.000
				ToggleImage.Name = "ToggleImage"
				ToggleImage.Parent = Toggle
				ToggleImage.BackgroundColor3 = Color3.fromRGB(225, 225, 225)
				ToggleImage.Position = UDim2.new(0, 415, 0, 5)
				ToggleImage.Size = UDim2.new(0, 45, 0, 20)
				UICorner_3.CornerRadius = UDim.new(0, 10)
				UICorner_3.Parent = ToggleImage
				Circle.Name = "Circle"
				Circle.Parent = ToggleImage
				Circle.BackgroundColor3 = Color3.fromRGB(255, 46, 46)
				Circle.Position = UDim2.new(0, 2, 0, 2)
				Circle.Size = UDim2.new(0, 16, 0, 16)
				UICorner_4.CornerRadius = UDim.new(0, 10)
				UICorner_4.Parent = Circle
				imgLabelIcon.Name = "Icon"
				imgLabelIcon.Parent = Toggle
				imgLabelIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				imgLabelIcon.BackgroundTransparency = 1.000
				imgLabelIcon.Position = UDim2.new(0, 10, 0, 5)
				imgLabelIcon.Size = UDim2.new(0, 20, 0, 20)
				imgLabelIcon.Image = ResolveIcon(Imgidicon)
				local function ApplyToggle(target)
					if target ~= nil and toggled == target then return end
					if toggled == false then
						toggled = true
						Circle:TweenPosition(UDim2.new(0,27,0,2),"Out","Sine",0.2,true)
						TweenService:Create(
							Toggle,
							TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
							{BackgroundColor3 = _G.Color}
						):Play()
						TweenService:Create(
							Circle,
							TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
							{BackgroundColor3 = _G.Color}
						):Play()
					else
						toggled = false
						Circle:TweenPosition(UDim2.new(0,2,0,2),"Out","Sine",0.2,true)
						TweenService:Create(
							Toggle,
							TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
							{BackgroundColor3 = Color3.fromRGB(255, 46, 46)}
						):Play()
						TweenService:Create(
							Circle,
							TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
							{BackgroundColor3 = Color3.fromRGB(255, 46, 46)}
						):Play()
					end
					pcall(callback,toggled)
				end
				Button.MouseButton1Click:Connect(function() ApplyToggle() end)
				if config == true then
					toggled = true
					Circle:TweenPosition(UDim2.new(0,27,0,2),"Out","Sine",0.4,true)
					TweenService:Create(
						Toggle,
						TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
						{BackgroundColor3 = _G.Color}
					):Play()
					TweenService:Create(
						Circle,
						TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
						{BackgroundColor3 = _G.Color}
					):Play()
					pcall(callback,toggled)
				end
				local tog = {}
				function tog:SetStage(v) ApplyToggle(v and true or false) end
				tog.Set = tog.SetStage
				function tog:Get() return toggled end
				return tog
			end
			function main:Dropdown(text,old,option,callback)
				local isdropping = false
				local Current = (type(old) == "string") and old or nil
				local Dropdown = Instance.new("Frame")
				local UICorner = Instance.new("UICorner")
				local DropTitle = Instance.new("TextLabel")
				local DropScroll = Instance.new("ScrollingFrame")
				local UIListLayout = Instance.new("UIListLayout")
				local UIPadding = Instance.new("UIPadding")
				local DropButton = Instance.new("TextButton")
				local DropImage = Instance.new("ImageLabel")
				Dropdown.Name = "Dropdown"
				Dropdown.Parent = MainFramePage
				Dropdown.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
				Dropdown.ClipsDescendants = true
				Dropdown.Size = UDim2.new(0, 470, 0, 31)
				UICorner.CornerRadius = UDim.new(0, 5)
				UICorner.Parent = Dropdown
				if type(old) == "string" then
					DropTitle.Name = "DropTitle"
					DropTitle.Parent = Dropdown
					DropTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					DropTitle.BackgroundTransparency = 1.000
					DropTitle.Size = UDim2.new(0, 470, 0, 31)
					DropTitle.Font = Enum.Font.GothamSemibold
					DropTitle.Text = text.. " : "..old
					DropTitle.TextColor3 = Color3.fromRGB(225, 225, 225)
					DropTitle.TextSize = 15.000
				else
					DropTitle.Name = "DropTitle"
					DropTitle.Parent = Dropdown
					DropTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					DropTitle.BackgroundTransparency = 1.000
					DropTitle.Size = UDim2.new(0, 470, 0, 31)
					DropTitle.Font = Enum.Font.GothamSemibold
					DropTitle.Text = text.. " : "
					DropTitle.TextColor3 = Color3.fromRGB(225, 225, 225)
					DropTitle.TextSize = 15.000
				end
				DropScroll.Name = "DropScroll"
				DropScroll.Parent = DropTitle
				DropScroll.Active = true
				DropScroll.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				DropScroll.BackgroundTransparency = 1.000
				DropScroll.BorderSizePixel = 0
				DropScroll.Position = UDim2.new(0, 0, 0, 31)
				DropScroll.Size = UDim2.new(0, 470, 0, 100)
				DropScroll.CanvasSize = UDim2.new(0, 0, 0, 2)
				DropScroll.ScrollBarThickness = 3
				UIListLayout.Parent = DropScroll
				UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
				UIListLayout.Padding = UDim.new(0, 5)
				UIPadding.Parent = DropScroll
				UIPadding.PaddingLeft = UDim.new(0, 5)
				UIPadding.PaddingTop = UDim.new(0, 5)
				DropImage.Name = "DropImage"
				DropImage.Parent = Dropdown
				DropImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				DropImage.BackgroundTransparency = 1.000
				DropImage.Position = UDim2.new(0, 445, 0, 6)
				DropImage.Rotation = -90
				DropImage.Size = UDim2.new(0, 20, 0, 20)
				DropImage.Image = "rbxassetid://6031090990"
				DropButton.Name = "DropButton"
				DropButton.Parent = Dropdown
				DropButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				DropButton.BackgroundTransparency = 1.000
				DropButton.Size = UDim2.new(0, 470, 0, 31)
				DropButton.Font = Enum.Font.SourceSans
				DropButton.Text = ""
				DropButton.TextColor3 = Color3.fromRGB(0, 0, 0)
				DropButton.TextSize = 14.000
				for i,v in next,option do
					local Item = Instance.new("TextButton")
					Item.Name = "Item"
					Item.Parent = DropScroll
					Item.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					Item.BackgroundTransparency = 1.000
					Item.Size = UDim2.new(0, 460, 0, 26)
					Item.Font = Enum.Font.GothamSemibold
					Item.Text = tostring(v)
					Item.TextColor3 = Color3.fromRGB(225, 225, 225)
					Item.TextSize = 13.000
					Item.TextTransparency = 0.500
					Item.ClipsDescendants = true
					Item.MouseEnter:Connect(function()
						TweenService:Create(
							Item,
							TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
							{TextTransparency = 0}
						):Play()
					end)
					Item.MouseLeave:Connect(function()
						TweenService:Create(
							Item,
							TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
							{TextTransparency = 0.5}
						):Play()
					end)
					Item.MouseButton1Click:Connect(function()
						CircleAnim(Item, Color3.fromRGB(255,255,255), Color3.fromRGB(255,255,255))
						isdropping = false
						Dropdown:TweenSize(UDim2.new(0,470,0,31),"Out","Quad",0.3,true)
						TweenService:Create(
							DropImage,
							TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
							{Rotation = -90}
						):Play()
						DropScroll.CanvasSize = UDim2.new(0,0,0,UIListLayout.AbsoluteContentSize.Y + 10)
						Current = Item.Text
						callback(Item.Text)
						DropTitle.Text = text.." : "..Item.Text
					end)
				end
				DropScroll.CanvasSize = UDim2.new(0,0,0,UIListLayout.AbsoluteContentSize.Y + 10)
				DropButton.MouseButton1Click:Connect(function()
					if isdropping == false then
						isdropping = true
						Dropdown:TweenSize(UDim2.new(0,470,0,131),"Out","Quad",0.3,true)
						TweenService:Create(
							DropImage,
							TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
							{Rotation = 180}
						):Play()
						DropScroll.CanvasSize = UDim2.new(0,0,0,UIListLayout.AbsoluteContentSize.Y + 10)
					else
						isdropping = false
						Dropdown:TweenSize(UDim2.new(0,470,0,31),"Out","Quad",0.3,true)
						TweenService:Create(
							DropImage,
							TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
							{Rotation = -90}
						):Play()
						DropScroll.CanvasSize = UDim2.new(0,0,0,UIListLayout.AbsoluteContentSize.Y + 10)
					end
				end)
				local dropfunc = {}
				function dropfunc:Add(t)
					local Item = Instance.new("TextButton")
					Item.Name = "Item"
					Item.Parent = DropScroll
					Item.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					Item.BackgroundTransparency = 1.000
					Item.Size = UDim2.new(0, 470, 0, 26)
					Item.Font = Enum.Font.GothamSemibold
					Item.Text = tostring(t)
					Item.TextColor3 = Color3.fromRGB(225, 225, 225)
					Item.TextSize = 13.000
					Item.TextTransparency = 0.500
					Item.ClipsDescendants = true
					Item.MouseEnter:Connect(function()
						TweenService:Create(
							Item,
							TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
							{TextTransparency = 0}
						):Play()
					end)
					Item.MouseLeave:Connect(function()
						TweenService:Create(
							Item,
							TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
							{TextTransparency = 0.5}
						):Play()
					end)
					Item.MouseButton1Click:Connect(function()
						isdropping = false
						CircleAnim(Item, Color3.fromRGB(255,255,255), Color3.fromRGB(255,255,255))
						Dropdown:TweenSize(UDim2.new(0,470,0,31),"Out","Quad",0.3,true)
						TweenService:Create(
							DropImage,
							TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
							{Rotation = -90}
						):Play()
						DropScroll.CanvasSize = UDim2.new(0,0,0,UIListLayout.AbsoluteContentSize.Y + 10)
						Current = Item.Text
						callback(Item.Text)
						DropTitle.Text = text.." : "..Item.Text
					end)
				end
				function dropfunc:Clear()
					DropTitle.Text = tostring(text).." : "
					isdropping = false
					Dropdown:TweenSize(UDim2.new(0,470,0,31),"Out","Quad",0.3,true)
					TweenService:Create(
						DropImage,
						TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
						{Rotation = -90}
					):Play()
					for i,v in next, DropScroll:GetChildren() do
						if v:IsA("TextButton") then
							v:Destroy()
						end
					end
				end
				function dropfunc:GetValue() return Current end
				function dropfunc:SetSelected(v)
					Current = v
					DropTitle.Text = text.." : "..tostring(v or "")
				end
				function dropfunc:SetOptions(list, keep)
					local prev = Current
					dropfunc:Clear()
					Current = nil
					for _, v in ipairs(list or {}) do dropfunc:Add(v) end
					if keep and prev and table.find(list or {}, prev) then dropfunc:SetSelected(prev) end
				end
				return dropfunc
			end
			function main:Slider(text,min,max,set,callback)
				local Slider = Instance.new("Frame")
				local slidercorner = Instance.new("UICorner")
				local sliderr = Instance.new("Frame")
				local sliderrcorner = Instance.new("UICorner")
				local SliderLabel = Instance.new("TextLabel")
				local HAHA = Instance.new("Frame")
				local AHEHE = Instance.new("TextButton")
				local bar = Instance.new("Frame")
				local bar1 = Instance.new("Frame")
				local bar1corner = Instance.new("UICorner")
				local barcorner = Instance.new("UICorner")
				local circlebar = Instance.new("Frame")
				local UICorner = Instance.new("UICorner")
				local slidervalue = Instance.new("Frame")
				local valuecorner = Instance.new("UICorner")
				local TextBox = Instance.new("TextBox")
				local UICorner_2 = Instance.new("UICorner")
				Slider.Name = "Slider"
				Slider.Parent = MainFramePage
				Slider.BackgroundColor3 = _G.Color
				Slider.BackgroundTransparency = 0
				Slider.Size = UDim2.new(0, 470, 0, 51)
				slidercorner.CornerRadius = UDim.new(0, 5)
				slidercorner.Name = "slidercorner"
				slidercorner.Parent = Slider
				sliderr.Name = "sliderr"
				sliderr.Parent = Slider
				sliderr.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
				sliderr.Position = UDim2.new(0, 1, 0, 1)
				sliderr.Size = UDim2.new(0, 468, 0, 49)
				sliderrcorner.CornerRadius = UDim.new(0, 5)
				sliderrcorner.Name = "sliderrcorner"
				sliderrcorner.Parent = sliderr
				SliderLabel.Name = "SliderLabel"
				SliderLabel.Parent = sliderr
				SliderLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				SliderLabel.BackgroundTransparency = 1.000
				SliderLabel.Position = UDim2.new(0, 15, 0, 0)
				SliderLabel.Size = UDim2.new(0, 180, 0, 26)
				SliderLabel.Font = Enum.Font.GothamSemibold
				SliderLabel.Text = text
				SliderLabel.TextColor3 = Color3.fromRGB(225, 225, 225)
				SliderLabel.TextSize = 16.000
				SliderLabel.TextTransparency = 0
				SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
				HAHA.Name = "HAHA"
				HAHA.Parent = sliderr
				HAHA.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				HAHA.BackgroundTransparency = 1.000
				HAHA.Size = UDim2.new(0, 468, 0, 29)
				AHEHE.Name = "AHEHE"
				AHEHE.Parent = sliderr
				AHEHE.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				AHEHE.BackgroundTransparency = 1.000
				AHEHE.Position = UDim2.new(0, 10, 0, 35)
				AHEHE.Size = UDim2.new(0, 448, 0, 5)
				AHEHE.Font = Enum.Font.SourceSans
				AHEHE.Text = ""
				AHEHE.TextColor3 = Color3.fromRGB(0, 0, 0)
				AHEHE.TextSize = 14.000
				bar.Name = "bar"
				bar.Parent = AHEHE
				bar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
				bar.Size = UDim2.new(0, 448, 0, 5)
				bar1.Name = "bar1"
				bar1.Parent = bar
				bar1.BackgroundColor3 = _G.Color
				bar1.BackgroundTransparency = 0
				bar1.Size = UDim2.new(set/max, 0, 0, 5)
				bar1corner.CornerRadius = UDim.new(0, 5)
				bar1corner.Name = "bar1corner"
				bar1corner.Parent = bar1
				barcorner.CornerRadius = UDim.new(0, 5)
				barcorner.Name = "barcorner"
				barcorner.Parent = bar
				circlebar.Name = "circlebar"
				circlebar.Parent = bar1
				circlebar.BackgroundColor3 = Color3.fromRGB(225, 225, 225)
				circlebar.Position = UDim2.new(1, -2, 0, -3)
				circlebar.Size = UDim2.new(0, 10, 0, 10)
				UICorner.CornerRadius = UDim.new(0, 100)
				UICorner.Parent = circlebar
				slidervalue.Name = "slidervalue"
				slidervalue.Parent = sliderr
				slidervalue.BackgroundColor3 = _G.Color
				slidervalue.BackgroundTransparency = 0
				slidervalue.Position = UDim2.new(0, 395, 0, 5)
				slidervalue.Size = UDim2.new(0, 65, 0, 18)
				valuecorner.CornerRadius = UDim.new(0, 5)
				valuecorner.Name = "valuecorner"
				valuecorner.Parent = slidervalue
				TextBox.Parent = slidervalue
				TextBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
				TextBox.Position = UDim2.new(0, 1, 0, 1)
				TextBox.Size = UDim2.new(0, 63, 0, 16)
				TextBox.Font = Enum.Font.GothamSemibold
				TextBox.TextColor3 = Color3.fromRGB(225, 225, 225)
				TextBox.TextSize = 9.000
				TextBox.Text = set
				TextBox.TextTransparency = 0
				UICorner_2.CornerRadius = UDim.new(0, 5)
				UICorner_2.Parent = TextBox
				local mouse = game.Players.LocalPlayer:GetMouse()
				local uis = game:GetService("UserInputService")
				if Value == nil then
					Value = set
					pcall(function()
						callback(Value)
					end)
				end
				AHEHE.MouseButton1Down:Connect(function()
					Value = math.floor((((tonumber(max) - tonumber(min)) / 448) * bar1.AbsoluteSize.X) + tonumber(min)) or 0
					pcall(function()
						callback(Value)
					end)
					TweenService:Create(
						bar1,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{Size = UDim2.new(0, math.clamp(mouse.X - bar1.AbsolutePosition.X, 0, 448), 0, 5)}
					):Play()
					TweenService:Create(
						circlebar,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{Position =  UDim2.new(0, math.clamp(mouse.X - bar1.AbsolutePosition.X - 2, 0, 438), 0, -3)}
					):Play()
					moveconnection = mouse.Move:Connect(function()
						TextBox.Text = Value
						Value = math.floor((((tonumber(max) - tonumber(min)) / 448) * bar1.AbsoluteSize.X) + tonumber(min))
						pcall(function()
							callback(Value)
						end)
						TweenService:Create(
							bar1,
							TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{Size = UDim2.new(0, math.clamp(mouse.X - bar1.AbsolutePosition.X, 0, 448), 0, 5)}
						):Play()
						TweenService:Create(
							circlebar,
							TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{Position =  UDim2.new(0, math.clamp(mouse.X - bar1.AbsolutePosition.X - 2, 0, 438), 0, -3)}
						):Play()
					end)
					releaseconnection = uis.InputEnded:Connect(function(Mouse)
						if Mouse.UserInputType == Enum.UserInputType.MouseButton1 then
							Value = math.floor((((tonumber(max) - tonumber(min)) / 448) * bar1.AbsoluteSize.X) + tonumber(min))
							pcall(function()
								callback(Value)
							end)
							TweenService:Create(
								bar1,
								TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
								{Size = UDim2.new(0, math.clamp(mouse.X - bar1.AbsolutePosition.X, 0, 448), 0, 5)}
							):Play()
							TweenService:Create(
								circlebar,
								TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
								{Position =  UDim2.new(0, math.clamp(mouse.X - bar1.AbsolutePosition.X - 2, 0, 438), 0, -3)}
							):Play()
							moveconnection:Disconnect()
							releaseconnection:Disconnect()
						end
					end)
				end)
				releaseconnection = uis.InputEnded:Connect(function(Mouse)
					if Mouse.UserInputType == Enum.UserInputType.MouseButton1 then
						Value = math.floor((((tonumber(max) - tonumber(min)) / 448) * bar1.AbsoluteSize.X) + tonumber(min))
						TextBox.Text = Value
					end
				end)
				TextBox.FocusLost:Connect(function()
					if tonumber(TextBox.Text) > max then
						TextBox.Text  = max
					end
					bar1.Size = UDim2.new((TextBox.Text or 0) / max, 0, 0, 5)
					circlebar.Position = UDim2.new(1, -2, 0, -3)
					TextBox.Text = tostring(TextBox.Text and math.floor( (TextBox.Text / max) * (max - min) + min) )
					pcall(callback, TextBox.Text)
				end)
				local sl = {}
				function sl:SetValue(v)
					v = math.clamp(tonumber(v) or min, min, max)
					local frac = (max > min) and (v - min) / (max - min) or 0
					bar1.Size = UDim2.new(0, frac * 448, 0, 5)
					circlebar.Position = UDim2.new(1, -2, 0, -3)
					TextBox.Text = tostring(v)
					pcall(callback, v)
				end
				function sl:GetValue() return tonumber(TextBox.Text) or min end
				return sl
			end
			function main:Textbox(text,disappear,callback,placeholder,numeric)
				local Textbox = Instance.new("Frame")
				local TextboxCorner = Instance.new("UICorner")
				local Textboxx = Instance.new("Frame")
				local TextboxxCorner = Instance.new("UICorner")
				local TextboxLabel = Instance.new("TextLabel")
				local txtbtn = Instance.new("TextButton")
				local RealTextbox = Instance.new("TextBox")
				local UICorner = Instance.new("UICorner")
				Textbox.Name = "Textbox"
				Textbox.Parent = MainFramePage
				Textbox.BackgroundColor3 = _G.Color
				Textbox.BackgroundTransparency = 0
				Textbox.Size = UDim2.new(0, 470, 0, 31)
				TextboxCorner.CornerRadius = UDim.new(0, 5)
				TextboxCorner.Name = "TextboxCorner"
				TextboxCorner.Parent = Textbox
				Textboxx.Name = "Textboxx"
				Textboxx.Parent = Textbox
				Textboxx.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
				Textboxx.Position = UDim2.new(0, 1, 0, 1)
				Textboxx.Size = UDim2.new(0, 468, 0, 29)
				TextboxxCorner.CornerRadius = UDim.new(0, 5)
				TextboxxCorner.Name = "TextboxxCorner"
				TextboxxCorner.Parent = Textboxx
				TextboxLabel.Name = "TextboxLabel"
				TextboxLabel.Parent = Textbox
				TextboxLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				TextboxLabel.BackgroundTransparency = 1.000
				TextboxLabel.Position = UDim2.new(0, 15, 0, 0)
				TextboxLabel.Text = text
				TextboxLabel.Size = UDim2.new(0, 145, 0, 31)
				TextboxLabel.Font = Enum.Font.GothamSemibold
				TextboxLabel.TextColor3 = Color3.fromRGB(225, 225, 225)
				TextboxLabel.TextSize = 16.000
				TextboxLabel.TextTransparency = 0
				TextboxLabel.TextXAlignment = Enum.TextXAlignment.Left
				txtbtn.Name = "txtbtn"
				txtbtn.Parent = Textbox
				txtbtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				txtbtn.BackgroundTransparency = 1.000
				txtbtn.Position = UDim2.new(0, 1, 0, 1)
				txtbtn.Size = UDim2.new(0, 468, 0, 29)
				txtbtn.Font = Enum.Font.SourceSans
				txtbtn.Text = ""
				txtbtn.TextColor3 = Color3.fromRGB(0, 0, 0)
				txtbtn.TextSize = 14.000
				RealTextbox.Name = "RealTextbox"
				RealTextbox.Parent = Textbox
				RealTextbox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
				RealTextbox.BackgroundTransparency = 0
				RealTextbox.Position = UDim2.new(0, 360, 0, 4)
				RealTextbox.Size = UDim2.new(0, 100, 0, 24)
				RealTextbox.Font = Enum.Font.GothamSemibold
				RealTextbox.Text = ""
				RealTextbox.TextColor3 = Color3.fromRGB(225, 225, 225)
				RealTextbox.TextSize = 11.000
				RealTextbox.TextTransparency = 0
				RealTextbox.PlaceholderText = placeholder or ""
				RealTextbox.PlaceholderColor3 = Color3.fromRGB(140, 140, 140)
				RealTextbox.FocusLost:Connect(function()
					if numeric then
						RealTextbox.Text = RealTextbox.Text:gsub("[^%d%.%-]", "")
					end
					callback(RealTextbox.Text)
					if disappear then
						RealTextbox.Text = ""
					end
				end)
				UICorner.CornerRadius = UDim.new(0, 5)
				UICorner.Parent = RealTextbox
				local tb = {}
				function tb:SetValue(v) RealTextbox.Text = tostring(v or "") end
				function tb:GetValue() return RealTextbox.Text end
				return tb
			end
			function main:Label(text)
				local Label = Instance.new("TextLabel")
				local PaddingLabel = Instance.new("UIPadding")
				local labell = {}
				Label.Name = "Label"
				Label.Parent = MainFramePage
				Label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Label.BackgroundTransparency = 1.000
				Label.Size = UDim2.new(0, 470, 0, 20)
				Label.Font = Enum.Font.GothamSemibold
				Label.TextColor3 = Color3.fromRGB(225, 225, 225)
				Label.TextSize = 16.000
				Label.Text = text
				Label.TextXAlignment = Enum.TextXAlignment.Left
				PaddingLabel.PaddingLeft = UDim.new(0,0)
				PaddingLabel.Parent = Label
				PaddingLabel.Name = "PaddingLabel"
				function labell:Set(newtext)
					Label.Text = newtext
				end
				function labell:SetText(newtext)
					Label.Text = tostring(newtext)
				end
				function labell:SetColor(color)
					Label.TextColor3 = color
				end
				return labell
			end
			function main:LabelP(text)
				local Label = Instance.new("TextLabel")
				local PaddingLabel = Instance.new("UIPadding")
				local labell = {}
				Label.Name = "Label"
				Label.Parent = MainFramePage
				Label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Label.BackgroundTransparency = 1.000
				Label.Size = UDim2.new(0, 470, 0, 20)
				Label.Font = Enum.Font.GothamSemibold
				Label.TextColor3 = Color3.fromRGB(195, 195, 195)
				Label.TextSize = 15.000
				Label.Text = text
				Label.TextXAlignment = Enum.TextXAlignment.Left
				PaddingLabel.PaddingLeft = UDim.new(0,25)
				PaddingLabel.Parent = Label
				PaddingLabel.Name = "PaddingLabel"
				function labell:Set(newtext)
					Label.Text = newtext
				end
				function labell:SetText(newtext)
					Label.Text = tostring(newtext)
				end
				function labell:SetColor(color)
					Label.TextColor3 = color
				end
				return labell
			end
			local function BuildListDropdown(text, list, multi, search, defaults, callback)
				list = list or {}
				callback = callback or function() end
				local opened = false
				local options = {}
				local selected = {}
				local single = nil
				local ItemButtons = {}
				local listHeight = 0
				local d = {}
				local Drop = Instance.new("Frame")
				local DropCorner = Instance.new("UICorner")
				local DropTitle = Instance.new("TextLabel")
				local DropArrow = Instance.new("ImageLabel")
				local DropButton = Instance.new("TextButton")
				local SearchBox = Instance.new("TextBox")
				local SearchCorner = Instance.new("UICorner")
				local Scroll = Instance.new("ScrollingFrame")
				local ScrollLayout = Instance.new("UIListLayout")
				Drop.Name = multi and "MultiDropdown" or "SearchDropdown"
				Drop.Parent = MainFramePage
				Drop.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
				Drop.ClipsDescendants = true
				Drop.Size = UDim2.new(0, 470, 0, 31)
				DropCorner.CornerRadius = UDim.new(0, 5)
				DropCorner.Parent = Drop
				DropTitle.Name = "DropTitle"
				DropTitle.Parent = Drop
				DropTitle.BackgroundTransparency = 1
				DropTitle.Position = UDim2.new(0, 15, 0, 0)
				DropTitle.Size = UDim2.new(0, 410, 0, 31)
				DropTitle.Font = Enum.Font.GothamSemibold
				DropTitle.TextColor3 = Color3.fromRGB(225, 225, 225)
				DropTitle.TextSize = 15
				DropTitle.TextXAlignment = Enum.TextXAlignment.Left
				DropTitle.TextTruncate = Enum.TextTruncate.AtEnd
				DropArrow.Name = "DropArrow"
				DropArrow.Parent = Drop
				DropArrow.BackgroundTransparency = 1
				DropArrow.Position = UDim2.new(0, 440, 0, 5)
				DropArrow.Size = UDim2.new(0, 20, 0, 20)
				DropArrow.Image = "rbxassetid://6031090990"
				DropArrow.Rotation = -90
				DropButton.Name = "DropButton"
				DropButton.Parent = Drop
				DropButton.BackgroundTransparency = 1
				DropButton.Size = UDim2.new(0, 470, 0, 31)
				DropButton.Text = ""
				SearchBox.Name = "SearchBox"
				SearchBox.Parent = Drop
				SearchBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
				SearchBox.Position = UDim2.new(0, 6, 0, 34 + (multi and 26 or 0))
				SearchBox.Size = UDim2.new(0, 458, 0, 22)
				SearchBox.Font = Enum.Font.GothamSemibold
				SearchBox.PlaceholderText = "Search..."
				SearchBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 140)
				SearchBox.Text = ""
				SearchBox.TextColor3 = Color3.fromRGB(225, 225, 225)
				SearchBox.TextSize = 13
				SearchBox.ClearTextOnFocus = false
				SearchBox.Visible = search and true or false
				SearchCorner.CornerRadius = UDim.new(0, 5)
				SearchCorner.Parent = SearchBox
				Scroll.Name = "Scroll"
				Scroll.Parent = Drop
				Scroll.Active = true
				Scroll.BackgroundTransparency = 1
				Scroll.BorderSizePixel = 0
				Scroll.Position = UDim2.new(0, 6, 0, (search and 60 or 34) + (multi and 26 or 0))
				Scroll.ScrollBarThickness = 3
				Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
				ScrollLayout.Parent = Scroll
				ScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
				local AllButton, ClearButton
				if multi then
					local function MakeCtrl(name, x, w)
						local B = Instance.new("TextButton")
						local BC = Instance.new("UICorner")
						B.Name = name
						B.Parent = Drop
						B.AutoButtonColor = false
						B.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
						B.Position = UDim2.new(0, x, 0, 34)
						B.Size = UDim2.new(0, w, 0, 22)
						B.Font = Enum.Font.GothamSemibold
						B.TextColor3 = Color3.fromRGB(225, 225, 225)
						B.TextSize = 12
						BC.CornerRadius = UDim.new(0, 5)
						BC.Parent = B
						return B
					end
					AllButton = MakeCtrl("SelectAll", 6, 227)
					AllButton.Text = "Select All"
					ClearButton = MakeCtrl("ClearAll", 237, 227)
					ClearButton.Text = "Clear All"
				end
				local function OpenHeight()
					return 34 + (multi and 26 or 0) + (search and 26 or 0) + listHeight + 6
				end
				local function UpdateTitle()
					if multi then
						local picked = {}
						for _, name in ipairs(options) do
							if selected[name] then picked[#picked + 1] = tostring(name) end
						end
						DropTitle.Text = text .. " : " .. table.concat(picked, ", ")
					else
						DropTitle.Text = text .. " : " .. tostring(single or "")
					end
				end
				local function IsSelected(name)
					if multi then return selected[name] == true end
					return single == name
				end
				local function SetOpen(state)
					opened = state and true or false
					TweenService:Create(Drop, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{Size = UDim2.new(0, 470, 0, opened and OpenHeight() or 31)}):Play()
					TweenService:Create(DropArrow, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{Rotation = opened and 0 or -90}):Play()
				end
				local function Refresh()
					for _, b in pairs(ItemButtons) do b:Destroy() end
					ItemButtons = {}
					local q = search and string.lower(SearchBox.Text) or ""
					local shown = 0
					for _, name in ipairs(options) do
						if q == "" or string.find(string.lower(tostring(name)), q, 1, true) then
							shown = shown + 1
							local Item = Instance.new("TextButton")
							Item.Name = "Item"
							Item.Parent = Scroll
							Item.LayoutOrder = shown
							Item.BackgroundTransparency = 1
							Item.Size = UDim2.new(0, 450, 0, 26)
							Item.Font = Enum.Font.GothamSemibold
							Item.Text = tostring(name)
							Item.TextSize = 13
							Item.AutoButtonColor = false
							Item.TextColor3 = IsSelected(name) and (_G.Color or Color3.fromRGB(68, 202, 186)) or Color3.fromRGB(225, 225, 225)
							Item.TextTransparency = IsSelected(name) and 0 or 0.4
							Item.MouseButton1Click:Connect(function()
								if multi then
									if selected[name] then selected[name] = nil else selected[name] = true end
									local on = IsSelected(name)
									Item.TextColor3 = on and (_G.Color or Color3.fromRGB(68, 202, 186)) or Color3.fromRGB(225, 225, 225)
									Item.TextTransparency = on and 0 or 0.4
									UpdateTitle()
									pcall(callback, d:GetValue())
								else
									single = name
									UpdateTitle()
									Refresh()
									SetOpen(false)
									pcall(callback, name)
								end
							end)
							ItemButtons[#ItemButtons + 1] = Item
						end
					end
					listHeight = math.min(shown * 26, 130)
					Scroll.CanvasSize = UDim2.new(0, 0, 0, shown * 26)
					Scroll.Size = UDim2.new(0, 458, 0, listHeight)
					if opened then
						Drop:TweenSize(UDim2.new(0, 470, 0, OpenHeight()), "Out", "Quad", 0.15, true)
					end
				end
				DropButton.MouseButton1Click:Connect(function() SetOpen(not opened) end)
				if search then
					SearchBox:GetPropertyChangedSignal("Text"):Connect(Refresh)
				end
				function d:GetValue()
					if multi then
						local out = {}
						for _, name in ipairs(options) do
							if selected[name] then out[#out + 1] = name end
						end
						return out
					end
					return single
				end
				function d:SetSelected(value)
					if multi then
						selected = {}
						if type(value) == "table" then
							for _, n in ipairs(value) do selected[n] = true end
						elseif value ~= nil then
							selected[value] = true
						end
					else
						if type(value) == "number" then value = options[value] end
						single = value
					end
					Refresh()
					UpdateTitle()
				end
				function d:SetValue(value)
					d:SetSelected(value)
					pcall(callback, d:GetValue())
				end
				function d:SetOptions(newlist, keep)
					local old = selected
					local oldSingle = single
					options = {}
					for _, name in ipairs(newlist or {}) do options[#options + 1] = name end
					selected = {}
					single = nil
					if keep then
						for _, name in ipairs(options) do
							if old[name] then selected[name] = true end
							if oldSingle == name then single = name end
						end
					end
					Refresh()
					UpdateTitle()
				end
				function d:Add(name)
					options[#options + 1] = name
					Refresh()
				end
				function d:Clear()
					options = {}
					selected = {}
					single = nil
					Refresh()
					UpdateTitle()
				end
				function d:SetOpen(state) SetOpen(state) end
				function d:SelectAll()
					if not multi then return end
					for _, name in ipairs(options) do selected[name] = true end
					Refresh()
					UpdateTitle()
					pcall(callback, d:GetValue())
				end
				function d:ClearAll()
					if not multi then return end
					selected = {}
					Refresh()
					UpdateTitle()
					pcall(callback, d:GetValue())
				end
				if multi then
					AllButton.MouseButton1Click:Connect(function() d:SelectAll() end)
					ClearButton.MouseButton1Click:Connect(function() d:ClearAll() end)
				end
				d:SetOptions(list, false)
				if defaults ~= nil then
					d:SetSelected(defaults)
					pcall(callback, d:GetValue())
				end
				return d
			end
			function main:MultiDropdown(text, list, defaults, callback, search)
				return BuildListDropdown(text, list, true, search, defaults, callback)
			end
			function main:SearchDropdown(text, list, default, callback)
				return BuildListDropdown(text, list, false, true, default, callback)
			end
			function main:ColorPicker(text, default, callback)
				callback = callback or function() end
				if typeof(default) ~= "Color3" then default = Color3.fromRGB(255, 255, 255) end
				local h, s, v = default:ToHSV()
				local opened = false
				local cp = {}
				local Holder = Instance.new("Frame")
				local HolderCorner = Instance.new("UICorner")
				local Title = Instance.new("TextLabel")
				local Swatch = Instance.new("Frame")
				local SwatchCorner = Instance.new("UICorner")
				local Arrow = Instance.new("ImageLabel")
				local HeadButton = Instance.new("TextButton")
				Holder.Name = "ColorPicker"
				Holder.Parent = MainFramePage
				Holder.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
				Holder.ClipsDescendants = true
				Holder.Size = UDim2.new(0, 470, 0, 31)
				HolderCorner.CornerRadius = UDim.new(0, 5)
				HolderCorner.Parent = Holder
				Title.Name = "Title"
				Title.Parent = Holder
				Title.BackgroundTransparency = 1
				Title.Position = UDim2.new(0, 15, 0, 0)
				Title.Size = UDim2.new(0, 330, 0, 31)
				Title.Font = Enum.Font.GothamSemibold
				Title.Text = tostring(text or "")
				Title.TextColor3 = Color3.fromRGB(225, 225, 225)
				Title.TextSize = 15
				Title.TextXAlignment = Enum.TextXAlignment.Left
				Title.TextTruncate = Enum.TextTruncate.AtEnd
				Swatch.Name = "Swatch"
				Swatch.Parent = Holder
				Swatch.BackgroundColor3 = default
				Swatch.BorderSizePixel = 0
				Swatch.Position = UDim2.new(0, 385, 0, 6)
				Swatch.Size = UDim2.new(0, 45, 0, 19)
				SwatchCorner.CornerRadius = UDim.new(0, 4)
				SwatchCorner.Parent = Swatch
				Arrow.Name = "Arrow"
				Arrow.Parent = Holder
				Arrow.BackgroundTransparency = 1
				Arrow.Position = UDim2.new(0, 440, 0, 5)
				Arrow.Size = UDim2.new(0, 20, 0, 20)
				Arrow.Image = "rbxassetid://6031090990"
				Arrow.Rotation = -90
				HeadButton.Name = "HeadButton"
				HeadButton.Parent = Holder
				HeadButton.BackgroundTransparency = 1
				HeadButton.Size = UDim2.new(0, 470, 0, 31)
				HeadButton.Text = ""
				local function MakeBar(y, label)
					local Lbl = Instance.new("TextLabel")
					local Bar = Instance.new("Frame")
					local BarCorner = Instance.new("UICorner")
					local Grad = Instance.new("UIGradient")
					local Knob = Instance.new("Frame")
					local KnobCorner = Instance.new("UICorner")
					local KnobStroke = Instance.new("UIStroke")
					Lbl.Name = label .. "Label"
					Lbl.Parent = Holder
					Lbl.BackgroundTransparency = 1
					Lbl.Position = UDim2.new(0, 15, 0, y)
					Lbl.Size = UDim2.new(0, 60, 0, 20)
					Lbl.Font = Enum.Font.GothamSemibold
					Lbl.Text = label
					Lbl.TextColor3 = Color3.fromRGB(225, 225, 225)
					Lbl.TextSize = 13
					Lbl.TextXAlignment = Enum.TextXAlignment.Left
					Bar.Name = label .. "Bar"
					Bar.Parent = Holder
					Bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					Bar.BorderSizePixel = 0
					Bar.Position = UDim2.new(0, 80, 0, y + 5)
					Bar.Size = UDim2.new(0, 370, 0, 10)
					BarCorner.CornerRadius = UDim.new(0, 5)
					BarCorner.Parent = Bar
					Grad.Parent = Bar
					Knob.Name = "Knob"
					Knob.Parent = Bar
					Knob.AnchorPoint = Vector2.new(0.5, 0.5)
					Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					Knob.BorderSizePixel = 0
					Knob.Position = UDim2.new(0, 0, 0.5, 0)
					Knob.Size = UDim2.new(0, 8, 0, 16)
					KnobCorner.CornerRadius = UDim.new(0, 4)
					KnobCorner.Parent = Knob
					KnobStroke.Parent = Knob
					KnobStroke.Color = Color3.fromRGB(20, 20, 20)
					KnobStroke.Thickness = 1
					return Bar, Grad, Knob
				end
				local HueBar, HueGrad, HueKnob = MakeBar(36, "Hue")
				local SatBar, SatGrad, SatKnob = MakeBar(60, "Sat")
				local ValBar, ValGrad, ValKnob = MakeBar(84, "Val")
				local hueKeys = {}
				for i = 0, 6 do
					hueKeys[#hueKeys + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6 >= 1 and 0.9999 or i / 6, 1, 1))
				end
				HueGrad.Color = ColorSequence.new(hueKeys)
				local function Update(fire)
					local c = Color3.fromHSV(h, s, v)
					Swatch.BackgroundColor3 = c
					SatGrad.Color = ColorSequence.new(Color3.fromHSV(h, 0, v), Color3.fromHSV(h, 1, v))
					ValGrad.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0), Color3.fromHSV(h, s, 1))
					HueKnob.Position = UDim2.new(h, 0, 0.5, 0)
					SatKnob.Position = UDim2.new(s, 0, 0.5, 0)
					ValKnob.Position = UDim2.new(v, 0, 0.5, 0)
					if fire then pcall(callback, c) end
				end
				local function Hook(Bar, onValue)
					local dragging = false
					local function Apply(input)
						local rel = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / math.max(Bar.AbsoluteSize.X, 1), 0, 1)
						onValue(rel)
					end
					Bar.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							dragging = true
							Apply(input)
						end
					end)
					Track(UserInputService.InputChanged:Connect(function(input)
						if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
							Apply(input)
						end
					end))
					Track(UserInputService.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							dragging = false
						end
					end))
				end
				Hook(HueBar, function(r) h = r; Update(true) end)
				Hook(SatBar, function(r) s = r; Update(true) end)
				Hook(ValBar, function(r) v = r; Update(true) end)
				local function SetOpen(state)
					opened = state and true or false
					TweenService:Create(Holder, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{Size = UDim2.new(0, 470, 0, opened and 114 or 31)}):Play()
					TweenService:Create(Arrow, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{Rotation = opened and 0 or -90}):Play()
				end
				HeadButton.MouseButton1Click:Connect(function() SetOpen(not opened) end)
				function cp:Get() return Color3.fromHSV(h, s, v) end
				function cp:Set(color, fire)
					if typeof(color) ~= "Color3" then return end
					h, s, v = color:ToHSV()
					Update(fire and true or false)
				end
				function cp:SetOpen(state) SetOpen(state) end
				Update(false)
				return cp
			end
			function main:Stepper(text, default, min, max, step, callback)
				min = tonumber(min) or 0
				max = tonumber(max) or 100
				step = tonumber(step) or 1
				if step <= 0 then step = 1 end
				callback = callback or function() end
				local value = math.clamp(tonumber(default) or min, min, max)
				local st = {}
				local Holder = Instance.new("Frame")
				local HolderCorner = Instance.new("UICorner")
				local Title = Instance.new("TextLabel")
				local Minus = Instance.new("TextButton")
				local MinusCorner = Instance.new("UICorner")
				local Plus = Instance.new("TextButton")
				local PlusCorner = Instance.new("UICorner")
				local Box = Instance.new("TextBox")
				local BoxCorner = Instance.new("UICorner")
				Holder.Name = "Stepper"
				Holder.Parent = MainFramePage
				Holder.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
				Holder.Size = UDim2.new(0, 470, 0, 31)
				HolderCorner.CornerRadius = UDim.new(0, 5)
				HolderCorner.Parent = Holder
				Title.Name = "Title"
				Title.Parent = Holder
				Title.BackgroundTransparency = 1
				Title.Position = UDim2.new(0, 15, 0, 0)
				Title.Size = UDim2.new(0, 300, 0, 31)
				Title.Font = Enum.Font.GothamSemibold
				Title.Text = tostring(text or "")
				Title.TextColor3 = Color3.fromRGB(225, 225, 225)
				Title.TextSize = 15
				Title.TextXAlignment = Enum.TextXAlignment.Left
				Title.TextTruncate = Enum.TextTruncate.AtEnd
				local function StyleBtn(B, C, label, x)
					B.Parent = Holder
					B.AutoButtonColor = false
					B.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
					B.Position = UDim2.new(0, x, 0, 4)
					B.Size = UDim2.new(0, 28, 0, 23)
					B.Font = Enum.Font.GothamBold
					B.Text = label
					B.TextColor3 = _G.Color or Color3.fromRGB(68, 202, 186)
					B.TextSize = 16
					C.CornerRadius = UDim.new(0, 5)
					C.Parent = B
				end
				StyleBtn(Minus, MinusCorner, "-", 330)
				StyleBtn(Plus, PlusCorner, "+", 432)
				Minus.Name = "Minus"
				Plus.Name = "Plus"
				Box.Name = "Value"
				Box.Parent = Holder
				Box.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
				Box.Position = UDim2.new(0, 362, 0, 4)
				Box.Size = UDim2.new(0, 66, 0, 23)
				Box.Font = Enum.Font.GothamSemibold
				Box.TextColor3 = Color3.fromRGB(225, 225, 225)
				Box.TextSize = 13
				Box.ClearTextOnFocus = false
				BoxCorner.CornerRadius = UDim.new(0, 5)
				BoxCorner.Parent = Box
				local function Snap(n)
					n = min + math.floor((n - min) / step + 0.5) * step
					n = math.clamp(n, min, max)
					return math.floor(n * 1000 + 0.5) / 1000
				end
				local function Apply(n, fire)
					value = Snap(n)
					Box.Text = tostring(value)
					if fire then pcall(callback, value) end
				end
				Minus.MouseButton1Click:Connect(function() Apply(value - step, true) end)
				Plus.MouseButton1Click:Connect(function() Apply(value + step, true) end)
				Box.FocusLost:Connect(function()
					local n = tonumber(Box.Text)
					if n then Apply(n, true) else Box.Text = tostring(value) end
				end)
				function st:Get() return value end
				function st:Set(n, fire) if tonumber(n) then Apply(tonumber(n), fire and true or false) end end
				Apply(value, false)
				return st
			end
			function main:ProgressBar(text, value, max)
				max = tonumber(max) or 100
				if max <= 0 then max = 100 end
				value = math.clamp(tonumber(value) or 0, 0, max)
				local pb = {}
				local Holder = Instance.new("Frame")
				local HolderCorner = Instance.new("UICorner")
				local Title = Instance.new("TextLabel")
				local Percent = Instance.new("TextLabel")
				local TrackFrame = Instance.new("Frame")
				local TrackCorner = Instance.new("UICorner")
				local Fill = Instance.new("Frame")
				local FillCorner = Instance.new("UICorner")
				Holder.Name = "ProgressBar"
				Holder.Parent = MainFramePage
				Holder.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
				Holder.Size = UDim2.new(0, 470, 0, 40)
				HolderCorner.CornerRadius = UDim.new(0, 5)
				HolderCorner.Parent = Holder
				Title.Name = "Title"
				Title.Parent = Holder
				Title.BackgroundTransparency = 1
				Title.Position = UDim2.new(0, 15, 0, 3)
				Title.Size = UDim2.new(0, 350, 0, 20)
				Title.Font = Enum.Font.GothamSemibold
				Title.Text = tostring(text or "")
				Title.TextColor3 = Color3.fromRGB(225, 225, 225)
				Title.TextSize = 14
				Title.TextXAlignment = Enum.TextXAlignment.Left
				Title.TextTruncate = Enum.TextTruncate.AtEnd
				Percent.Name = "Percent"
				Percent.Parent = Holder
				Percent.BackgroundTransparency = 1
				Percent.Position = UDim2.new(0, 375, 0, 3)
				Percent.Size = UDim2.new(0, 80, 0, 20)
				Percent.Font = Enum.Font.GothamSemibold
				Percent.TextColor3 = _G.Color or Color3.fromRGB(68, 202, 186)
				Percent.TextSize = 13
				Percent.TextXAlignment = Enum.TextXAlignment.Right
				TrackFrame.Name = "TrackFrame"
				TrackFrame.Parent = Holder
				TrackFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
				TrackFrame.BorderSizePixel = 0
				TrackFrame.Position = UDim2.new(0, 15, 0, 28)
				TrackFrame.Size = UDim2.new(0, 440, 0, 6)
				TrackCorner.CornerRadius = UDim.new(0, 3)
				TrackCorner.Parent = TrackFrame
				Fill.Name = "Fill"
				Fill.Parent = TrackFrame
				Fill.BackgroundColor3 = _G.Color or Color3.fromRGB(68, 202, 186)
				Fill.BorderSizePixel = 0
				Fill.Size = UDim2.new(0, 0, 1, 0)
				FillCorner.CornerRadius = UDim.new(0, 3)
				FillCorner.Parent = Fill
				local function Render()
					local pct = value / max
					Percent.Text = math.floor(pct * 100 + 0.5) .. "%"
					TweenService:Create(Fill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{Size = UDim2.new(pct, 0, 1, 0)}):Play()
				end
				function pb:Set(newValue, newMax)
					if tonumber(newMax) and tonumber(newMax) > 0 then max = tonumber(newMax) end
					value = math.clamp(tonumber(newValue) or value, 0, max)
					Render()
				end
				function pb:Get() return value, max end
				function pb:SetText(t) Title.Text = tostring(t or "") end
				Render()
				return pb
			end
			function main:Keybind(text, default, mode, callback)
				callback = callback or function() end
				local currentMode = (mode == "Hold") and "Hold" or "Toggle"
				local function KeyName(k)
					return (tostring(k):gsub("Enum%.KeyCode%.", ""):gsub("Enum%.UserInputType%.", ""))
				end
				local currentKey = KeyName(default or "F")
				local picking = false
				local toggleState = false
				local holdActive = false
				local kb = {}
				local Bind = Instance.new("Frame")
				local BindCorner = Instance.new("UICorner")
				local BindLabel = Instance.new("TextLabel")
				local BindButton = Instance.new("TextButton")
				local BindBtnCorner = Instance.new("UICorner")
				Bind.Name = "Keybind"
				Bind.Parent = MainFramePage
				Bind.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
				Bind.Size = UDim2.new(0, 470, 0, 31)
				BindCorner.CornerRadius = UDim.new(0, 5)
				BindCorner.Parent = Bind
				BindLabel.Name = "BindLabel"
				BindLabel.Parent = Bind
				BindLabel.BackgroundTransparency = 1
				BindLabel.Position = UDim2.new(0, 15, 0, 0)
				BindLabel.Size = UDim2.new(0, 330, 0, 31)
				BindLabel.Font = Enum.Font.GothamSemibold
				BindLabel.Text = tostring(text)
				BindLabel.TextColor3 = Color3.fromRGB(225, 225, 225)
				BindLabel.TextSize = 15
				BindLabel.TextXAlignment = Enum.TextXAlignment.Left
				BindButton.Name = "BindButton"
				BindButton.Parent = Bind
				BindButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
				BindButton.Position = UDim2.new(0, 360, 0, 4)
				BindButton.Size = UDim2.new(0, 100, 0, 23)
				BindButton.Font = Enum.Font.GothamSemibold
				BindButton.Text = "[ " .. currentKey .. " ]"
				BindButton.TextColor3 = _G.Color or Color3.fromRGB(68, 202, 186)
				BindButton.TextSize = 12
				BindBtnCorner.CornerRadius = UDim.new(0, 5)
				BindBtnCorner.Parent = BindButton
				BindButton.MouseButton1Click:Connect(function()
					if picking then return end
					picking = true
					BindButton.Text = "[ ... ]"
					local conn
					conn = Track(UserInputService.InputBegan:Connect(function(input)
						local name
						if input.UserInputType == Enum.UserInputType.Keyboard then
							name = input.KeyCode.Name
						elseif input.UserInputType == Enum.UserInputType.MouseButton1
							or input.UserInputType == Enum.UserInputType.MouseButton2
							or input.UserInputType == Enum.UserInputType.MouseButton3 then
							name = input.UserInputType.Name
						end
						if not name then return end
						if name ~= "Escape" then currentKey = name end
						BindButton.Text = "[ " .. currentKey .. " ]"
						picking = false
						conn:Disconnect()
					end))
				end)
				local function Matches(input)
					local n = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode.Name or input.UserInputType.Name
					return n == currentKey
				end
				Track(UserInputService.InputBegan:Connect(function(input, gpe)
					if gpe or picking or not Matches(input) then return end
					if currentMode == "Toggle" then
						toggleState = not toggleState
						pcall(callback, toggleState)
					else
						holdActive = true
						pcall(callback, true)
					end
				end))
				Track(UserInputService.InputEnded:Connect(function(input)
					if currentMode == "Hold" and holdActive and Matches(input) then
						holdActive = false
						pcall(callback, false)
					end
				end))
				function kb:Set(newKey)
					currentKey = KeyName(newKey)
					BindButton.Text = "[ " .. currentKey .. " ]"
				end
				function kb:Get() return currentKey end
				function kb:SetMode(m)
					if m == "Hold" or m == "Toggle" then
						currentMode = m
						toggleState = false
						holdActive = false
					end
				end
				function kb:GetMode() return currentMode end
				function kb:GetState()
					if currentMode == "Toggle" then return toggleState end
					return holdActive
				end
				return kb
			end
			function main:Group(title, open)
				local isOpen = open and true or false
				local Group = Instance.new("Frame")
				local GroupCorner = Instance.new("UICorner")
				local GroupStroke = Instance.new("UIStroke")
				local Header = Instance.new("TextButton")
				local HeaderLabel = Instance.new("TextLabel")
				local Arrow = Instance.new("ImageLabel")
				local Content = Instance.new("Frame")
				local ContentLayout = Instance.new("UIListLayout")
				local ContentPad = Instance.new("UIPadding")
				Group.Name = "Group"
				Group.Parent = MainFramePage
				Group.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
				Group.ClipsDescendants = true
				Group.Size = UDim2.new(0, 470, 0, 31)
				GroupCorner.CornerRadius = UDim.new(0, 5)
				GroupCorner.Parent = Group
				GroupStroke.Parent = Group
				GroupStroke.Color = _G.Color or Color3.fromRGB(68, 202, 186)
				GroupStroke.Thickness = 1
				GroupStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				Header.Name = "Header"
				Header.Parent = Group
				Header.BackgroundTransparency = 1
				Header.Size = UDim2.new(0, 470, 0, 31)
				Header.Text = ""
				HeaderLabel.Name = "HeaderLabel"
				HeaderLabel.Parent = Group
				HeaderLabel.BackgroundTransparency = 1
				HeaderLabel.Position = UDim2.new(0, 15, 0, 0)
				HeaderLabel.Size = UDim2.new(0, 400, 0, 31)
				HeaderLabel.Font = Enum.Font.GothamBold
				HeaderLabel.Text = tostring(title or "")
				HeaderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				HeaderLabel.TextSize = 15
				HeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
				Arrow.Name = "Arrow"
				Arrow.Parent = Group
				Arrow.BackgroundTransparency = 1
				Arrow.Position = UDim2.new(0, 440, 0, 5)
				Arrow.Size = UDim2.new(0, 20, 0, 20)
				Arrow.Image = "rbxassetid://6031090990"
				Arrow.Rotation = isOpen and 0 or -90
				Content.Name = "Content"
				Content.Parent = Group
				Content.BackgroundTransparency = 1
				Content.Position = UDim2.new(0, 0, 0, 33)
				Content.Size = UDim2.new(0, 470, 0, 0)
				ContentLayout.Parent = Content
				ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
				ContentLayout.Padding = UDim.new(0, 5)
				ContentPad.Parent = Content
				ContentPad.PaddingLeft = UDim.new(0, 0)
				local function Resize(animate)
					local h = ContentLayout.AbsoluteContentSize.Y
					Content.Size = UDim2.new(0, 470, 0, h)
					local target = UDim2.new(0, 470, 0, isOpen and (33 + h + 6) or 31)
					if animate then
						Group:TweenSize(target, "Out", "Quad", 0.2, true)
					else
						Group.Size = target
					end
				end
				ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() Resize(false) end)
				local grp = {}
				local function SetOpen(state)
					isOpen = state and true or false
					TweenService:Create(Arrow, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{Rotation = isOpen and 0 or -90}):Play()
					Resize(true)
				end
				Header.MouseButton1Click:Connect(function() SetOpen(not isOpen) end)
				local names = {"Button", "Toggle", "Dropdown", "MultiDropdown", "SearchDropdown", "Slider",
					"Textbox", "Keybind", "Label", "LabelP", "Paragraph", "Section", "Seperator", "Line",
					"ColorPicker", "Stepper", "ProgressBar"}
				for _, n in ipairs(names) do
					grp[n] = function(_, ...)
						local prev = MainFramePage
						MainFramePage = Content
						local res = table.pack(pcall(main[n], main, ...))
						MainFramePage = prev
						if not res[1] then error(res[2], 0) end
						return table.unpack(res, 2, res.n)
					end
				end
				function grp:SetOpen(state) SetOpen(state) end
				function grp:GetOpen() return isOpen end
				function grp:SetTitle(t) HeaderLabel.Text = tostring(t or "") end
				Resize(false)
				return grp
			end
			main.DropdownSection = main.Group
			function main:Section(text, icon)
				local Section = Instance.new("Frame")
				local SectionIcon = Instance.new("ImageLabel")
				local SectionLabel = Instance.new("TextLabel")
				local SectionLine = Instance.new("Frame")
				local sec = {}
				local hasIcon = icon ~= nil and icon ~= ""
				Section.Name = "Section"
				Section.Parent = MainFramePage
				Section.BackgroundTransparency = 1.000
				Section.Size = UDim2.new(0, 470, 0, 32)
				SectionIcon.Name = "SectionIcon"
				SectionIcon.Parent = Section
				SectionIcon.BackgroundTransparency = 1.000
				SectionIcon.Position = UDim2.new(0, 0, 0, 3)
				SectionIcon.Size = UDim2.new(0, 22, 0, 22)
				SectionIcon.Image = hasIcon and ResolveIcon(icon) or ""
				SectionIcon.ImageColor3 = _G.Color or Color3.fromRGB(68, 202, 186)
				SectionIcon.Visible = hasIcon
				SectionLabel.Name = "SectionLabel"
				SectionLabel.Parent = Section
				SectionLabel.BackgroundTransparency = 1.000
				SectionLabel.Position = UDim2.new(0, hasIcon and 30 or 0, 0, 0)
				SectionLabel.Size = UDim2.new(0, 440, 0, 28)
				SectionLabel.Font = Enum.Font.GothamBold
				SectionLabel.Text = tostring(text or "")
				SectionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				SectionLabel.TextSize = 18.000
				SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
				SectionLine.Name = "SectionLine"
				SectionLine.Parent = Section
				SectionLine.BackgroundColor3 = _G.Color or Color3.fromRGB(68, 202, 186)
				SectionLine.BorderSizePixel = 0
				SectionLine.Position = UDim2.new(0, 0, 0, 30)
				SectionLine.Size = UDim2.new(0, 470, 0, 1)
				function sec:Set(newtext)
					SectionLabel.Text = tostring(newtext or "")
				end
				return sec
			end
			function main:Paragraph(title, subtitle)
				local Paragraph = Instance.new("Frame")
				local ParaLayout = Instance.new("UIListLayout")
				local TitleLabel = Instance.new("TextLabel")
				local SubLabels = {}
				local para = {}
				local TitleColor = Color3.fromRGB(255, 190, 40)
				local SubColor = _G.Color or Color3.fromRGB(68, 202, 186)
				Paragraph.Name = "Paragraph"
				Paragraph.Parent = MainFramePage
				Paragraph.BackgroundTransparency = 1.000
				Paragraph.Size = UDim2.new(0, 470, 0, 20)
				ParaLayout.Parent = Paragraph
				ParaLayout.SortOrder = Enum.SortOrder.LayoutOrder
				ParaLayout.Padding = UDim.new(0, 6)
				TitleLabel.Name = "Title"
				TitleLabel.Parent = Paragraph
				TitleLabel.LayoutOrder = 0
				TitleLabel.BackgroundTransparency = 1.000
				TitleLabel.Size = UDim2.new(0, 470, 0, 20)
				TitleLabel.Font = Enum.Font.GothamSemibold
				TitleLabel.TextColor3 = TitleColor
				TitleLabel.TextSize = 16.000
				TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
				TitleLabel.Text = tostring(title or "")
				local function Resize()
					Paragraph.Size = UDim2.new(0, 470, 0, ParaLayout.AbsoluteContentSize.Y)
				end
				ParaLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(Resize)
				local function BuildSub(sub)
					for _, l in pairs(SubLabels) do l:Destroy() end
					SubLabels = {}
					local lines = {}
					if type(sub) == "table" then
						for _, v in ipairs(sub) do table.insert(lines, tostring(v)) end
					elseif sub ~= nil then
						for line in (tostring(sub).."\n"):gmatch("(.-)\n") do table.insert(lines, line) end
					end
					for i, line in ipairs(lines) do
						local Sub = Instance.new("TextLabel")
						local SubPad = Instance.new("UIPadding")
						Sub.Name = "Subtitle"
						Sub.Parent = Paragraph
						Sub.LayoutOrder = i
						Sub.BackgroundTransparency = 1.000
						Sub.Size = UDim2.new(0, 470, 0, 20)
						Sub.Font = Enum.Font.GothamSemibold
						Sub.TextColor3 = SubColor
						Sub.TextSize = 15.000
						Sub.TextXAlignment = Enum.TextXAlignment.Left
						Sub.Text = line
						SubPad.Parent = Sub
						SubPad.PaddingLeft = UDim.new(0, 25)
						SubLabels[i] = Sub
					end
					Resize()
				end
				BuildSub(subtitle)
				function para:SetTitle(newtitle)
					TitleLabel.Text = tostring(newtitle or "")
				end
				function para:SetSubtitle(newsub)
					BuildSub(newsub)
				end
				function para:Set(newtitle, newsub)
					if newtitle ~= nil then para:SetTitle(newtitle) end
					if newsub ~= nil then para:SetSubtitle(newsub) end
				end
				return para
			end
			function main:Seperator(text)
				local Seperator = Instance.new("Frame")
				local Sep1 = Instance.new("Frame")
				local Sep2 = Instance.new("TextLabel")
				local Sep3 = Instance.new("Frame")
				Seperator.Name = "Seperator"
				Seperator.Parent = MainFramePage
				Seperator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Seperator.BackgroundTransparency = 1.000
				Seperator.Size = UDim2.new(0, 470, 0, 20)
				Sep1.Name = "Sep1"
				Sep1.Parent = Seperator
				Sep1.BackgroundColor3 = _G.Color
				Sep1.BorderSizePixel = 0
				Sep1.Position = UDim2.new(0, 0, 0, 10)
				Sep1.Size = UDim2.new(0, 80, 0, 1)
				Sep2.Name = "Sep2"
				Sep2.Parent = Seperator
				Sep2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Sep2.BackgroundTransparency = 1.000
				Sep2.Position = UDim2.new(0, 185, 0, 0)
				Sep2.Size = UDim2.new(0, 100, 0, 20)
				Sep2.Font = Enum.Font.GothamSemibold
				Sep2.Text = text
				Sep2.TextColor3 = Color3.fromRGB(255, 255, 255)
				Sep2.TextSize = 14.000
				Sep3.Name = "Sep3"
				Sep3.Parent = Seperator
				Sep3.BackgroundColor3 = _G.Color
				Sep3.BorderSizePixel = 0
				Sep3.Position = UDim2.new(0, 390, 0, 10)
				Sep3.Size = UDim2.new(0, 80, 0, 1)
			end
			function main:Line()
				local Linee = Instance.new("Frame")
				local Line = Instance.new("Frame")
				Linee.Name = "Linee"
				Linee.Parent = MainFramePage
				Linee.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Linee.BackgroundTransparency = 1.000
				Linee.Position = UDim2.new(0, 0, 0.119999997, 0)
				Linee.Size = UDim2.new(0, 470, 0, 20)
				Line.Name = "Line"
				Line.Parent = Linee
				Line.BackgroundColor3 = _G.Color
				Line.BorderSizePixel = 0
				Line.Position = UDim2.new(0, 0, 0, 10)
				Line.Size = UDim2.new(0, 470, 0, 1)
			end
			return main
		end
		return uitab
	end
end
if getgenv then getgenv().pnkalibv2 = library end
_G.pnkalibv2 = library
return library
