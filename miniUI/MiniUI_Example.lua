--[[
	MiniUI_Demo.lua
	Demo for every MiniUI component.
	Put MiniUI.lua in your executor's workspace folder, then run this script.
]]

local UI = loadstring(readfile("MiniUI.lua"))()

local Window = UI:CreateWindow({
	Title = "Mini Hub",
	Size = UDim2.fromOffset(500, 350),
	ToggleKey = Enum.KeyCode.RightShift, -- optional (keyboard only)
})

local Main = Window:CreateTab("Main")
local Inputs = Window:CreateTab("Inputs")
local Lists = Window:CreateTab("Lists")
local Data = Window:CreateTab("Data")
local LogTab = Window:CreateTab("Console")
local Settings = Window:CreateTab("Settings")

local Console -- created below, used by callbacks
local function log(message, kind)
	if Console then
		Console:Log(message, kind)
	end
end

----------------------------------------------------------------------
-- Main: Section, Label, Paragraph, Divider, Button, Toggle, Checkbox,
--       Slider, Counter, ProgressBar, KeyValue
----------------------------------------------------------------------
Main:CreateSection("General")
Main:CreateLabel("Welcome to Mini Hub")
Main:CreateParagraph({
	Title = "Information",
	Content = "This is a sample paragraph. Long text wraps automatically and the card grows with it.",
})
Main:CreateDivider()
Main:CreateDivider("Controls")

Main:CreateButton({
	Title = "Click Me",
	Callback = function()
		log("Button clicked", "Info")
		UI:Notify({ Title = "Button", Content = "You clicked the button.", Duration = 2 })
	end,
})

Main:CreateButton({
	Title = "Primary Button",
	Style = "Primary",
	Callback = function()
		log("Primary button clicked", "Success")
	end,
})

Main:CreateToggle({
	Title = "Enable Feature",
	Default = false,
	Callback = function(Value)
		log("Toggle = " .. tostring(Value))
	end,
})

Main:CreateCheckbox({
	Title = "Remember Me",
	Default = true,
	Callback = function(Value)
		log("Checkbox = " .. tostring(Value))
	end,
})

Main:CreateSlider({
	Title = "Speed",
	Min = 1,
	Max = 100,
	Default = 16,
	Increment = 1,
	Callback = function(Value)
		log("Speed = " .. Value)
	end,
})

Main:CreateSlider({
	Title = "Opacity",
	Min = 0,
	Max = 1,
	Default = 0.5,
	Increment = 0.05,
	Callback = function(Value)
		log("Opacity = " .. Value)
	end,
})

Main:CreateCounter({
	Title = "Amount",
	Min = 0,
	Max = 50,
	Default = 5,
	Step = 1,
	Callback = function(Value)
		log("Amount = " .. Value)
	end,
})

local Progress = Main:CreateProgressBar({ Title = "Loading", Default = 0 })
local Status = Main:CreateKeyValue({ Title = "Status", Value = "Idle" })

Main:CreateButton({
	Title = "Run Progress Demo",
	Callback = function()
		Status:Set("Running")
		task.spawn(function()
			for i = 0, 100, 10 do
				if Window:IsDestroyed() then
					return
				end
				Progress:Set(i)
				task.wait(0.15)
			end
			Status:Set("Done")
			UI:Notify({ Title = "Progress", Content = "Finished.", Type = "Success" })
		end)
	end,
})

----------------------------------------------------------------------
-- Inputs: Input, Textbox, Dropdown, MultiDropdown, RadioGroup,
--         Keybind, ColorPicker
----------------------------------------------------------------------
Inputs:CreateSection("Text")

Inputs:CreateInput({
	Title = "Player Name",
	Placeholder = "Enter name...",
	Default = "",
	Callback = function(Value)
		log("Name = " .. Value)
	end,
})

Inputs:CreateInput({
	Title = "Delay (s)",
	Placeholder = "0.5",
	Default = 0.5,
	Numeric = true,
	Min = 0,
	Max = 10,
	Callback = function(Value)
		log("Delay = " .. tostring(Value))
	end,
})

Inputs:CreateTextbox({
	Title = "Notes",
	Placeholder = "Write something...",
	Height = 80,
	Callback = function(Value)
		log("Notes length = " .. #Value)
	end,
})

Inputs:CreateSection("Choices")

Inputs:CreateDropdown({
	Title = "Select Option",
	Options = { "Option 1", "Option 2", "Option 3" },
	Default = "Option 1",
	Callback = function(Value)
		log("Dropdown = " .. tostring(Value))
	end,
})

Inputs:CreateMultiDropdown({
	Title = "Select Many",
	Options = { "Apple", "Banana", "Cherry", "Mango", "Grape" },
	Default = { "Apple", "Mango" },
	Callback = function(Values)
		log("MultiDropdown = " .. table.concat(Values, ", "))
	end,
})

Inputs:CreateRadioGroup({
	Title = "Mode",
	Options = { "Easy", "Normal", "Hard" },
	Default = "Normal",
	Callback = function(Value)
		log("Mode = " .. tostring(Value))
	end,
})

Inputs:CreateSection("Other")

Inputs:CreateKeybind({
	Title = "Toggle UI Key",
	Default = Enum.KeyCode.RightControl,
	Callback = function(Key)
		-- fires when the bound key is pressed (or when tapped on touch-only devices)
		Window:Toggle()
	end,
	OnChanged = function(Key)
		log("Keybind changed to " .. (Key and Key.Name or "None"))
	end,
})

Inputs:CreateColorPicker({
	Title = "Accent Color",
	Default = Color3.fromRGB(86, 140, 255),
	Callback = function(Color)
		log(string.format(
			"Color = %d, %d, %d",
			math.floor(Color.R * 255 + 0.5),
			math.floor(Color.G * 255 + 0.5),
			math.floor(Color.B * 255 + 0.5)
		))
	end,
})

----------------------------------------------------------------------
-- Lists: SearchBox, ItemList, Collapsible
----------------------------------------------------------------------
Lists:CreateSection("Items")

local Items = Lists:CreateItemList({
	Title = "Servers",
	Items = { "Alpha", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf", "Hotel" },
	MaxHeight = 140,
	Callback = function(Value)
		log("Selected item = " .. tostring(Value))
	end,
})

Lists:CreateSearchBox({
	Placeholder = "Filter servers...",
	Target = Items, -- automatically filters the list
	Callback = function(Query)
		log("Search: '" .. Query .. "'")
	end,
})

Lists:CreateButton({
	Title = "Add Random Item",
	Callback = function()
		Items:AddItem("Server " .. math.random(100, 999))
	end,
})

local Box = Lists:CreateCollapsible({ Title = "Advanced Options", Open = false })
Box:CreateLabel("These controls live inside a Collapsible.")
Box:CreateToggle({
	Title = "Debug Mode",
	Callback = function(v)
		log("Debug = " .. tostring(v))
	end,
})
Box:CreateSlider({
	Title = "Retries",
	Min = 0,
	Max = 10,
	Default = 3,
	Callback = function(v)
		log("Retries = " .. v)
	end,
})

----------------------------------------------------------------------
-- Data: SearchBox + DataTable
----------------------------------------------------------------------
Data:CreateSection("Table")

local Table = Data:CreateDataTable({
	Title = "Players",
	Columns = { "Name", "Level", "Role" },
	Widths = { 2, 1, 2 },
	Rows = {
		{ "Alice", 45, "Tank" },
		{ "Bob", 38, "Healer" },
		{ "Charlie", 52, "Damage" },
		{ "Dana", 41, "Support" },
		{ "Evan", 60, "Damage" },
	},
	MaxHeight = 150,
	Callback = function(Row)
		log("Row: " .. table.concat({ tostring(Row[1]), tostring(Row[2]), tostring(Row[3]) }, " / "))
	end,
})

Data:CreateSearchBox({
	Placeholder = "Search table...",
	Target = Table,
})

Data:CreateButton({
	Title = "Add Row",
	Callback = function()
		Table:AddRow({ "Player" .. math.random(10, 99), math.random(1, 80), "Guest" })
	end,
})

----------------------------------------------------------------------
-- Console
----------------------------------------------------------------------
LogTab:CreateSection("Logs")
Console = LogTab:CreateConsole({ Title = "Output", Height = 190, Timestamp = true })
Console:Log("Console ready", "Success")
Console:Warn("This is a warning")
Console:Error("This is an error")

LogTab:CreateButton({
	Title = "Write Test Logs",
	Callback = function()
		Console:Info("Info message")
		Console:Success("Success message")
		Console:Warn("Warning message")
		Console:Error("Error message")
	end,
})

----------------------------------------------------------------------
-- Settings: scale, notifications, minimize, destroy
----------------------------------------------------------------------
Settings:CreateSection("Interface")

Settings:CreateSlider({
	Title = "UI Scale",
	Min = 0.7,
	Max = 1.3,
	Default = 1,
	Increment = 0.05,
	Callback = function(Value)
		Window:SetScale(Value)
	end,
})

Settings:CreateButton({
	Title = "Minimize UI (tap the bubble to reopen)",
	Callback = function()
		Window:Hide()
	end,
})

Settings:CreateSection("Notifications")

Settings:CreateButton({
	Title = "Info Notification",
	Callback = function()
		UI:Notify({ Title = "Mini Hub", Content = "This is an info notification.", Duration = 3 })
	end,
})
Settings:CreateButton({
	Title = "Success Notification",
	Callback = function()
		UI:Notify({ Title = "Done", Content = "Everything worked.", Duration = 3, Type = "Success" })
	end,
})
Settings:CreateButton({
	Title = "Warning Notification",
	Callback = function()
		UI:Notify({ Title = "Careful", Content = "Something needs attention.", Duration = 3, Type = "Warning" })
	end,
})
Settings:CreateButton({
	Title = "Error Notification",
	Callback = function()
		UI:Notify({ Title = "Oops", Content = "Something went wrong.", Duration = 3, Type = "Error" })
	end,
})

Settings:CreateSection("Danger Zone")

Settings:CreateButton({
	Title = "Destroy UI",
	Style = "Primary",
	Callback = function()
		Window:Destroy() -- removes the GUI and disconnects every connection
	end,
})

UI:Notify({
	Title = "Mini Hub",
	Content = "UI loaded successfully.",
	Duration = 3,
})
