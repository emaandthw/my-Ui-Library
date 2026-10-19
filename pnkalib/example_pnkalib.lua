
--// pnkalib - Example
-- How to load the library:
--   Method 1 (local file in the executor workspace):
--       local Library = loadstring(readfile("pnkalib.lua"))()
--   Method 2 (host on GitHub and use the raw link):
--       local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/<user>/<repo>/main/pnkalib.lua"))()

local Library = loadstring(readfile("pnkalib.lua"))()

----------------------------------------------------------------
-- 1. Create Window
--    Title / Desc : Title (red) and description (white) on the top bar
--    Image        : (optional) logo, format: "rbxassetid://..."
----------------------------------------------------------------
local Window = Library:CreateWindow({
	Title = "pnkalib",
	Desc = "Example Hub",
	-- Image = "rbxassetid://5009915795",
})

-- Set this flag to make the GUI visible (when UIToggled = true)
-- Click the circular button in the bottom-left corner to hide/show the UI.
getgenv().ReadyForGuiLoaded = true
Library.ToggleUI()

----------------------------------------------------------------
-- 2. Tabs + Sections
--    AddTab returns a page. Use AddLeftGroupbox / AddRightGroupbox to create sections.
----------------------------------------------------------------
local MainTab = Window:AddTab("Main")
local SettingsTab = Window:AddTab("Settings")

local FarmSection = MainTab:AddLeftGroupbox("Auto Farm")
local PlayerSection = MainTab:AddRightGroupbox("Player")
local ConfigSection = SettingsTab:AddLeftGroupbox("Config")

----------------------------------------------------------------
-- 3. Label
----------------------------------------------------------------
local StatusLabel = FarmSection:AddLabel("Status: Idle")
-- StatusLabel:SetText("Status: Farming")
-- StatusLabel.SetColor(Color3.fromRGB(240, 62, 62))

----------------------------------------------------------------
-- 4. Toggle
--    Callback receives (state: boolean)
----------------------------------------------------------------
local AutoFarm = FarmSection:AddToggle({
	Title = "Auto Farm",
	Desc = "Automatically farm the nearest enemies",
	Default = false,
	Callback = function(state)
		StatusLabel:SetText(state and "Status: Farming" or "Status: Idle")
		print("Auto Farm:", state)
	end,
})
-- AutoFarm.SetStage(true) -- Enable/disable through code

----------------------------------------------------------------
-- 5. Button
----------------------------------------------------------------
local TeleBtn = FarmSection:AddButton({
	Title = "Teleport To Spawn",
	Callback = function()
		Library:Notify({
			Title = "Teleport",
			Description = "Teleported to spawn!",
			Duration = 3,
		}, true)
	end,
})
-- TeleBtn:SetTitle("New Title")

----------------------------------------------------------------
-- 6. Slider
--    Min / Max / Default ; Rounding = number of decimal places (optional)
----------------------------------------------------------------
PlayerSection:AddSlider({
	Title = "WalkSpeed",
	Min = 16,
	Max = 200,
	Default = 16,
	Callback = function(value)
		local hum = game.Players.LocalPlayer.Character
			and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = value
		end
	end,
})

PlayerSection:AddSlider({
	Title = "Jump Power",
	Min = 50,
	Max = 300,
	Default = 50,
	Callback = function(value)
		local hum = game.Players.LocalPlayer.Character
			and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.UseJumpPower = true
			hum.JumpPower = value
		end
	end,
})

----------------------------------------------------------------
-- 7. Input (Textbox)
--    Numeric = true -> numbers only
----------------------------------------------------------------
PlayerSection:AddInput({
	Title = "Custom Name",
	Placeholder = "Enter a name...",
	Default = "",
	Callback = function(text)
		print("Input:", text)
	end,
})

PlayerSection:AddInput({
	Title = "Delay (seconds)",
	Placeholder = "0.5",
	Numeric = true,
	Callback = function(text)
		print("Delay:", tonumber(text))
	end,
})

----------------------------------------------------------------
-- 8. Dropdown (Single Selection)
--    Values: array of strings ; Default: index or name ; Search = enables search box
----------------------------------------------------------------
local WeaponDropdown = FarmSection:AddDropdown({
	Title = "Select Weapon",
	Values = { "Melee", "Sword", "Gun", "Fruit" },
	Default = 1,
	Search = true,
	Callback = function(value)
		print("Weapon:", value)
	end,
})
-- WeaponDropdown:SetValue("Sword")
-- print(WeaponDropdown:GetValue())
-- WeaponDropdown:GetNewList({ "A", "B", "C" }) -- Update the list

----------------------------------------------------------------
-- 9. Dropdown (Multiple Selection) -> Multi = true
--    Callback receives (name, isSelected: boolean)
----------------------------------------------------------------
local SelectedMobs = {}
FarmSection:AddDropdown({
	Title = "Select Mobs",
	Values = { "Bandit", "Monkey", "Gorilla", "Pirate" },
	Multi = true,
	Callback = function(name, isSelected)
		SelectedMobs[name] = isSelected or nil
		print("Mob:", name, isSelected)
	end,
})

----------------------------------------------------------------
-- 10. Dropdown Section (Expandable group containing a slider)
----------------------------------------------------------------
local AdvancedGroup = PlayerSection:AddDropdownSection({
	Title = "Advanced",
})

AdvancedGroup:AddSlider({
	Title = "Gravity",
	Min = 0,
	Max = 196,
	Default = 196,
	Callback = function(value)
		workspace.Gravity = value
	end,
})
-- AdvancedGroup:SetOpen(true)
-- AdvancedGroup:SetTitle("Advanced (New)")

----------------------------------------------------------------
-- 11. KeyBind
--    Mode = "Toggle" or "Hold" ; Callback receives (state: boolean)
----------------------------------------------------------------
ConfigSection:AddKeyBind({
	Title = "Toggle Auto Farm",
	Default = "F",
	Mode = "Toggle",
	Callback = function(state)
		AutoFarm.SetStage(state)
	end,
})

ConfigSection:AddKeyBind({
	Title = "Sprint (Hold Key)",
	Default = "LeftShift",
	Mode = "Hold",
	Callback = function(held)
		print("Sprint:", held)
	end,
})

----------------------------------------------------------------
-- 12. Destroy UI Button
----------------------------------------------------------------
ConfigSection:AddButton({
	Title = "Destroy UI",
	Callback = function()
		Library.DestroyUI()
	end,
})

----------------------------------------------------------------
-- 13. Change Theme Colors Through Code (Optional)
--     Must be set BEFORE Library:CreateWindow to apply to the entire UI.
--     Example:
--       getgenv().UIColor["Button Color"] = Color3.fromRGB(240, 62, 62)
--       getgenv().UIColor["Title Text Color"] = Color3.fromRGB(240, 62, 62)
----------------------------------------------------------------

Library:Notify({
	Title = "Loaded",
	Description = "pnkalib example is ready!",
	Duration = 5,
}, true)
