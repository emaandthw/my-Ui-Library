-- Services
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Mouse = game:GetService("Players").LocalPlayer:GetMouse()

-- Rainbow hue state
local hue = 0
local colorPickerZIndex = 1

-- Upvalue for window X offset
local windowOffset = 0

-- Destroy existing instance
if game:GetService("CoreGui"):FindFirstChild("WizardLibrary") then
    game:GetService("CoreGui"):FindFirstChild("WizardLibrary"):Destroy()
end

-- Root GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WizardLibrary"
ScreenGui.Parent = game:GetService("CoreGui")

local Container = Instance.new("Frame")
Container.Name = "Container"
Container.Parent = ScreenGui
Container.BackgroundColor3 = Color3.new(1, 1, 1)
Container.BackgroundTransparency = 1
Container.Size = UDim2.new(0, 100, 0, 100)

-- Toggle visibility with RightControl
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightControl then
        CoastifiedLibrary.Enabled = not CoastifiedLibrary.Enabled
    end
end)

-- Dragging utility
local function Dragging(frame)
    local dragStart, startPos, dragging, lastInput

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        then
            lastInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == lastInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Strip spaces from a string (used for instance naming)
local function stripSpaces(str)
    return str:gsub(" ", "")
end

-- Rainbow hue ticker
coroutine.wrap(function()
    while wait() do
        hue = hue + 0.00392156862745098
        if hue >= 1 then hue = 0 end
    end
end)()

-- Tween helper
local function tween(instance, info, goal)
    TweenService:Create(instance, info, goal):Play()
end

local TWEEN_FAST  = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_MED   = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_SLOW  = TweenInfo.new(0.75, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_SLIDE = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_INSTANT = TweenInfo.new(0, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- Fade a button's text out, swap it, then fade back in
local function swapButtonText(btn, newText, newSize)
    tween(btn, TWEEN_FAST, { TextTransparency = 1 })
    btn.Text = newText
    btn.TextSize = newSize
    btn.Visible = false
    repeat wait() until btn.TextTransparency == 1
    btn.Visible = true
    tween(btn, TWEEN_FAST, { TextTransparency = 0 })
end

-- Fade two buttons simultaneously, swap, fade back
local function swapTwoButtons(btn1, newText1, newSize1, btn2, newText2, newSize2)
    tween(btn1, TWEEN_FAST, { TextTransparency = 1 })
    tween(btn2, TWEEN_FAST, { TextTransparency = 1 })
    btn1.Text = newText1
    btn1.TextSize = newSize1
    btn1.Visible = false
    btn2.Text = newText2
    btn2.TextSize = newSize2
    btn2.Visible = false
    repeat wait() until btn1.TextTransparency == 1 and btn2.TextTransparency == 1
    btn1.Visible = true
    btn2.Visible = true
    tween(btn1, TWEEN_FAST, { TextTransparency = 0 })
    tween(btn2, TWEEN_FAST, { TextTransparency = 0 })
end

-- ─── Library ───────────────────────────────────────────────────────────────

return {
    NewWindow = function(_, windowTitle)
        windowOffset = windowOffset + 2

        local windowId = stripSpaces(windowTitle)
        local bodyHeight = 35
        local windowOpen = true

        -- Instances
        local WindowRoot    = Instance.new("ImageLabel")
        local Topbar        = Instance.new("Frame")
        local ToggleBtn     = Instance.new("TextButton")
        local TitleLabel    = Instance.new("TextLabel")
        local BottomCover   = Instance.new("Frame")
        local Body          = Instance.new("ImageLabel")
        local BodySorter    = Instance.new("UIListLayout")
        local BodyTopCover  = Instance.new("Frame")

        local function growBody(amount)
            bodyHeight = bodyHeight + amount
            tween(Body, TWEEN_MED, { Size = UDim2.new(0, 170, 0, bodyHeight) })
        end
        local function shrinkBody(amount)
            bodyHeight = bodyHeight - amount
            tween(Body, TWEEN_MED, { Size = UDim2.new(0, 170, 0, bodyHeight) })
        end

        -- WindowRoot (rounded image label acting as the window shell)
        WindowRoot.Name = windowId .. "Window"
        WindowRoot.Parent = Container
        WindowRoot.BackgroundColor3 = Color3.new(0.098, 0.098, 0.098)
        WindowRoot.BackgroundTransparency = 1
        WindowRoot.Position = UDim2.new(windowOffset, -100, 3, -265)
        WindowRoot.Size = UDim2.new(0, 170, 0, 30)
        WindowRoot.ZIndex = 2
        WindowRoot.Image = "rbxassetid://3570695787"
        WindowRoot.ImageColor3 = Color3.new(0.098, 0.098, 0.098)
        WindowRoot.ScaleType = Enum.ScaleType.Slice
        WindowRoot.SliceCenter = Rect.new(100, 100, 100, 100)
        WindowRoot.SliceScale = 0.05

        -- Topbar
        Topbar.Name = "Topbar"
        Topbar.Parent = WindowRoot
        Topbar.BackgroundColor3 = Color3.new(1, 1, 1)
        Topbar.BackgroundTransparency = 1
        Topbar.BorderSizePixel = 0
        Topbar.Size = UDim2.new(0, 170, 0, 30)
        Topbar.ZIndex = 2

        -- Window toggle button (minimise/restore)
        ToggleBtn.Name = "WindowToggle"
        ToggleBtn.Parent = Topbar
        ToggleBtn.BackgroundColor3 = Color3.new(1, 1, 1)
        ToggleBtn.BackgroundTransparency = 1
        ToggleBtn.Position = UDim2.new(0.82245, 0, 0, 0)
        ToggleBtn.Size = UDim2.new(0, 30, 0, 30)
        ToggleBtn.ZIndex = 2
        ToggleBtn.Font = Enum.Font.SourceSansSemibold
        ToggleBtn.Text = "-"
        ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
        ToggleBtn.TextSize = 20
        ToggleBtn.TextWrapped = true

        ToggleBtn.MouseButton1Down:Connect(function()
            if windowOpen then
                windowOpen = false
                swapButtonText(ToggleBtn, "v", 14)
            else
                windowOpen = true
                swapButtonText(ToggleBtn, "-", 20)
            end
        end)

        -- Title
        TitleLabel.Name = "WindowTitle"
        TitleLabel.Parent = Topbar
        TitleLabel.BackgroundColor3 = Color3.new(1, 1, 1)
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Size = UDim2.new(0, 170, 0, 30)
        TitleLabel.ZIndex = 2
        TitleLabel.Font = Enum.Font.SourceSansBold
        TitleLabel.Text = windowTitle
        TitleLabel.TextColor3 = Color3.new(1, 1, 1)
        TitleLabel.TextSize = 17

        -- Cover that hides the bottom round corners of the topbar
        BottomCover.Name = "BottomRoundCover"
        BottomCover.Parent = Topbar
        BottomCover.BackgroundColor3 = Color3.new(0.098, 0.098, 0.098)
        BottomCover.BorderSizePixel = 0
        BottomCover.Position = UDim2.new(0, 0, 0.8333, 0)
        BottomCover.Size = UDim2.new(0, 170, 0, 5)
        BottomCover.ZIndex = 2

        -- Body
        Body.Name = "Body"
        Body.Parent = WindowRoot
        Body.BackgroundColor3 = Color3.new(0.137, 0.137, 0.137)
        Body.BackgroundTransparency = 1
        Body.ClipsDescendants = true
        Body.Size = UDim2.new(0, 170, 0, bodyHeight)
        Body.Image = "rbxassetid://3570695787"
        Body.ImageColor3 = Color3.new(0.137, 0.137, 0.137)
        Body.ScaleType = Enum.ScaleType.Slice
        Body.SliceCenter = Rect.new(100, 100, 100, 100)
        Body.SliceScale = 0.05

        BodySorter.Name = "Sorter"
        BodySorter.Parent = Body
        BodySorter.SortOrder = Enum.SortOrder.LayoutOrder

        BodyTopCover.Name = "TopbarBodyCover"
        BodyTopCover.Parent = Body
        BodyTopCover.BackgroundColor3 = Color3.new(1, 1, 1)
        BodyTopCover.BackgroundTransparency = 1
        BodyTopCover.BorderSizePixel = 0
        BodyTopCover.Size = UDim2.new(0, 170, 0, 30)

        Dragging(WindowRoot)

        -- ─── Window API ──────────────────────────────────────────────────────

        return {
            NewSection = function(_, sectionTitle)
                local sectionId = stripSpaces(sectionTitle)
                local sectionOpen = false
                local sectionHeight = 30
                local arrowText = "v"

                local SectionFrame   = Instance.new("Frame")
                local SectionInfo    = Instance.new("Frame")
                local SectionToggle  = Instance.new("TextButton")
                local SectionTitle   = Instance.new("TextLabel")
                local SectionLayout  = Instance.new("UIListLayout")

                local function growSection(amount)
                    sectionHeight = sectionHeight + amount
                    tween(SectionFrame, TWEEN_MED, { Size = UDim2.new(0, 170, 0, sectionHeight) })
                end
                local function shrinkSection(amount)
                    sectionHeight = sectionHeight - amount
                    tween(SectionFrame, TWEEN_MED, { Size = UDim2.new(0, 170, 0, sectionHeight) })
                end

                SectionFrame.Name = sectionId .. "Section"
                SectionFrame.Parent = Body
                SectionFrame.BackgroundColor3 = Color3.new(0.176, 0.176, 0.176)
                SectionFrame.BorderSizePixel = 0
                SectionFrame.ClipsDescendants = true
                SectionFrame.Size = UDim2.new(0, 170, 0, sectionHeight)

                growBody(30)

                SectionInfo.Name = "SectionInfo"
                SectionInfo.Parent = SectionFrame
                SectionInfo.BackgroundColor3 = Color3.new(1, 1, 1)
                SectionInfo.BackgroundTransparency = 1
                SectionInfo.Size = UDim2.new(0, 170, 0, 30)

                SectionToggle.Name = "SectionToggle"
                SectionToggle.Parent = SectionInfo
                SectionToggle.BackgroundColor3 = Color3.new(1, 1, 1)
                SectionToggle.BackgroundTransparency = 1
                SectionToggle.Position = UDim2.new(0.82245, 0, 0, 0)
                SectionToggle.Size = UDim2.new(0, 30, 0, 30)
                SectionToggle.ZIndex = 2
                SectionToggle.Font = Enum.Font.SourceSansSemibold
                SectionToggle.Text = arrowText
                SectionToggle.TextColor3 = Color3.new(1, 1, 1)
                SectionToggle.TextSize = 14
                SectionToggle.TextWrapped = true

                SectionTitle.Name = "SectionTitle"
                SectionTitle.Parent = SectionInfo
                SectionTitle.BackgroundColor3 = Color3.new(1, 1, 1)
                SectionTitle.BackgroundTransparency = 1
                SectionTitle.BorderSizePixel = 0
                SectionTitle.Position = UDim2.new(0.052941, 0, 0, 0)
                SectionTitle.Size = UDim2.new(0, 125, 0, 30)
                SectionTitle.Font = Enum.Font.SourceSansBold
                SectionTitle.Text = sectionTitle
                SectionTitle.TextColor3 = Color3.new(1, 1, 1)
                SectionTitle.TextSize = 17
                SectionTitle.TextXAlignment = Enum.TextXAlignment.Left

                SectionLayout.Name = "Layout"
                SectionLayout.Parent = SectionFrame
                SectionLayout.SortOrder = Enum.SortOrder.LayoutOrder

                -- Window toggle affects sections
                ToggleBtn.MouseButton1Down:Connect(function()
                    if windowOpen then
                        shrinkBody(30)
                        SectionToggle.Text = ""
                        tween(SectionFrame, TWEEN_MED, { BackgroundTransparency = 1 })
                    else
                        growBody(30)
                        SectionToggle.Text = arrowText
                        tween(SectionFrame, TWEEN_MED, { BackgroundTransparency = 0 })
                    end
                end)

                -- Section collapse/expand
                SectionToggle.MouseButton1Down:Connect(function()
                    if sectionOpen then
                        sectionOpen = false
                        arrowText = "v"
                        swapTwoButtons(SectionToggle, arrowText, 14, ToggleBtn, ToggleBtn.Text, ToggleBtn.TextSize)
                    else
                        sectionOpen = true
                        arrowText = "-"
                        swapTwoButtons(SectionToggle, arrowText, 20, ToggleBtn, ToggleBtn.Text, ToggleBtn.TextSize)
                    end
                end)

                -- Helper: update section/body sizing when window toggle is pressed and section state is known
                local function onWindowToggleForSection()
                    if windowOpen then
                        if sectionOpen then
                            shrinkBody(30)
                            tween(ToggleBtn, TWEEN_INSTANT, { Rotation = 0 })
                            tween(SectionFrame, TWEEN_MED, { BackgroundTransparency = 1 })
                        else
                            tween(SectionFrame, TWEEN_MED, { BackgroundTransparency = 1 })
                        end
                    else
                        if sectionOpen then
                            growBody(30)
                            tween(ToggleBtn, TWEEN_INSTANT, { Rotation = 360 })
                            tween(SectionFrame, TWEEN_MED, { BackgroundTransparency = 0 })
                        else
                            tween(SectionFrame, TWEEN_MED, { BackgroundTransparency = 0 })
                        end
                    end

                    swapButtonText(SectionToggle, SectionToggle.Text, SectionToggle.TextSize)
                end

                -- ─── Section API ─────────────────────────────────────────────

                return {
                    -- ── Toggle ────────────────────────────────────────────────
                    CreateToggle = function(_, label, callback)
                        local toggleId = stripSpaces(label)
                        local state = false

                        local Holder      = Instance.new("Frame")
                        local Title       = Instance.new("TextLabel")
                        local Background  = Instance.new("ImageLabel")
                        local Dot         = Instance.new("ImageButton")

                        Holder.Name = toggleId .. "ToggleHolder"
                        Holder.Parent = SectionFrame
                        Holder.BackgroundColor3 = Color3.new(0.137, 0.137, 0.137)
                        Holder.BorderSizePixel = 0
                        Holder.Size = UDim2.new(0, 170, 0, 30)

                        Title.Name = "ToggleTitle"
                        Title.Parent = Holder
                        Title.BackgroundColor3 = Color3.new(1, 1, 1)
                        Title.BackgroundTransparency = 1
                        Title.BorderSizePixel = 0
                        Title.Position = UDim2.new(0.052941, 0, 0, 0)
                        Title.Size = UDim2.new(0, 125, 0, 30)
                        Title.Font = Enum.Font.SourceSansBold
                        Title.Text = label
                        Title.TextColor3 = Color3.new(1, 1, 1)
                        Title.TextSize = 17
                        Title.TextXAlignment = Enum.TextXAlignment.Left

                        Background.Name = "ToggleBackground"
                        Background.Parent = Holder
                        Background.BackgroundColor3 = Color3.new(1, 1, 1)
                        Background.BackgroundTransparency = 1
                        Background.BorderSizePixel = 0
                        Background.Position = UDim2.new(0.847059, 0, 0.166667, 0)
                        Background.Size = UDim2.new(0, 20, 0, 20)
                        Background.Image = "rbxassetid://3570695787"
                        Background.ImageColor3 = Color3.new(0.254902, 0.254902, 0.254902)

                        Dot.Name = "ToggleButton"
                        Dot.Parent = Background
                        Dot.BackgroundColor3 = Color3.new(1, 1, 1)
                        Dot.BackgroundTransparency = 1
                        Dot.Position = UDim2.new(0, 2, 0, 2)
                        Dot.Size = UDim2.new(0, 16, 0, 16)
                        Dot.Image = "rbxassetid://3570695787"
                        Dot.ImageColor3 = Color3.new(1, 0.341176, 0.341176)
                        Dot.ImageTransparency = 1

                        Dot.MouseButton1Down:Connect(function()
                            state = not state
                            tween(Dot, TWEEN_MED, { ImageTransparency = state and 0 or 1 })
                            callback(state)
                        end)

                        SectionToggle.MouseButton1Down:Connect(function()
                            if sectionOpen then
                                shrinkSection(30)
                                shrinkBody(30)
                            else
                                growSection(30)
                                growBody(30)
                            end
                        end)

                        ToggleBtn.MouseButton1Down:Connect(onWindowToggleForSection)
                    end,

                    -- ── Slider ────────────────────────────────────────────────
                    CreateSlider = function(_, label, min, max, default, isFloat, callback)
                        local sliderId = stripSpaces(label)
                        local dragging = false
                        local useFloat = isFloat

                        local Holder        = Instance.new("Frame")
                        local TitleLbl      = Instance.new("TextLabel")
                        local ValueHolder   = Instance.new("ImageLabel")
                        local ValueLbl      = Instance.new("TextLabel")
                        local Track         = Instance.new("ImageLabel")
                        local Fill          = Instance.new("ImageLabel")

                        Holder.Name = sliderId .. "SliderHolder"
                        Holder.Parent = SectionFrame
                        Holder.BackgroundColor3 = Color3.new(0.137, 0.137, 0.137)
                        Holder.BorderSizePixel = 0
                        Holder.Size = UDim2.new(0, 170, 0, 30)

                        TitleLbl.Name = "SliderTitle"
                        TitleLbl.Parent = Holder
                        TitleLbl.BackgroundColor3 = Color3.new(1, 1, 1)
                        TitleLbl.BackgroundTransparency = 1
                        TitleLbl.BorderSizePixel = 0
                        TitleLbl.Position = UDim2.new(0.052941, 0, 0, 0)
                        TitleLbl.Size = UDim2.new(0, 125, 0, 15)
                        TitleLbl.Font = Enum.Font.SourceSansSemibold
                        TitleLbl.Text = label
                        TitleLbl.TextColor3 = Color3.new(1, 1, 1)
                        TitleLbl.TextSize = 17
                        TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

                        ValueHolder.Name = "SliderValueHolder"
                        ValueHolder.Parent = Holder
                        ValueHolder.BackgroundColor3 = Color3.new(0.254902, 0.254902, 0.254902)
                        ValueHolder.BackgroundTransparency = 1
                        ValueHolder.Position = UDim2.new(0.747059, 0, 0, 0)
                        ValueHolder.Size = UDim2.new(0, 35, 0, 15)
                        ValueHolder.Image = "rbxassetid://3570695787"
                        ValueHolder.ImageColor3 = Color3.new(0.254902, 0.254902, 0.254902)
                        ValueHolder.ImageTransparency = 0.5
                        ValueHolder.ScaleType = Enum.ScaleType.Slice
                        ValueHolder.SliceCenter = Rect.new(100, 100, 100, 100)
                        ValueHolder.SliceScale = 0.02

                        ValueLbl.Name = "SliderValue"
                        ValueLbl.Parent = ValueHolder
                        ValueLbl.BackgroundColor3 = Color3.new(1, 1, 1)
                        ValueLbl.BackgroundTransparency = 1
                        ValueLbl.Size = UDim2.new(0, 35, 0, 15)
                        ValueLbl.Font = Enum.Font.SourceSansSemibold
                        ValueLbl.Text = tostring(
                            useFloat and tonumber(string.format("%.2f", default or min))
                                      or (default or min)
                        )
                        ValueLbl.TextColor3 = Color3.new(1, 1, 1)
                        ValueLbl.TextSize = 14

                        Track.Name = "SliderBackground"
                        Track.Parent = Holder
                        Track.BackgroundColor3 = Color3.new(0.254902, 0.254902, 0.254902)
                        Track.BackgroundTransparency = 1
                        Track.Position = UDim2.new(0.053, 0, 0.65, 0)
                        Track.Selectable = true
                        Track.Size = UDim2.new(0, 153, 0, 5)
                        Track.Image = "rbxassetid://3570695787"
                        Track.ImageColor3 = Color3.new(0.254902, 0.254902, 0.254902)
                        Track.ImageTransparency = 0.5
                        Track.ScaleType = Enum.ScaleType.Slice
                        Track.SliceCenter = Rect.new(100, 100, 100, 100)
                        Track.ClipsDescendants = true
                        Track.SliceScale = 0.02

                        Fill.Name = "Slider"
                        Fill.Parent = Track
                        Fill.BackgroundColor3 = Color3.new(1, 1, 1)
                        Fill.BackgroundTransparency = 1
                        Fill.Size = UDim2.new(((default or min) - min) / (max - min), 0, 0, 5)
                        Fill.Image = "rbxassetid://3570695787"
                        Fill.ScaleType = Enum.ScaleType.Slice
                        Fill.SliceCenter = Rect.new(100, 100, 100, 100)
                        Fill.SliceScale = 0.02

                        local function updateSlider(input)
                            local scale = math.clamp(
                                (input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X,
                                0, 1
                            )
                            tween(Fill, TWEEN_SLIDE, { Size = UDim2.new(scale, 0, 1.15, 0) })

                            local rawValue = scale * (max - min) + min
                            local value = useFloat and tonumber(string.format("%.2f", rawValue))
                                                    or math.floor(rawValue)
                            ValueLbl.Text = tostring(value)
                            callback(value)
                        end

                        Track.InputBegan:Connect(function(i)
                            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                                dragging = true
                                updateSlider(i)
                            end
                        end)
                        Track.InputEnded:Connect(function(i)
                            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                                dragging = false
                            end
                        end)
                        UserInputService.InputChanged:Connect(function(i)
                            if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
                                updateSlider(i)
                            end
                        end)

                        SectionToggle.MouseButton1Down:Connect(function()
                            if sectionOpen then
                                shrinkSection(30)
                                shrinkBody(30)
                            else
                                growSection(30)
                                growBody(30)
                            end
                        end)

                        ToggleBtn.MouseButton1Down:Connect(onWindowToggleForSection)
                    end,

                    -- ── Color Picker ──────────────────────────────────────────
                    CreateColorPicker = function(_, label, defaultColor, callback)
                        local pickerId = stripSpaces(label)
                        colorPickerZIndex = colorPickerZIndex + 1
                        local zi = colorPickerZIndex

                        local pickerOpen = false
                        local rainbowOn  = false
                        local satConn, hueConn

                        local HSV = { H = 1, S = 1, V = 1 }

                        -- Instances
                        local Holder         = Instance.new("Frame")
                        local PickerTitle    = Instance.new("TextLabel")
                        local ColorSwatch    = Instance.new("ImageButton")
                        local PickerPopup    = Instance.new("ImageLabel")

                        local RainbowHolder  = Instance.new("Frame")
                        local RainbowTitle   = Instance.new("TextLabel")
                        local RainbowBg      = Instance.new("ImageLabel")
                        local RainbowBtn     = Instance.new("ImageButton")

                        local LabelR         = Instance.new("TextLabel")
                        local LabelG         = Instance.new("TextLabel")
                        local LabelB         = Instance.new("TextLabel")
                        local RoundR         = Instance.new("ImageLabel")
                        local RoundG         = Instance.new("ImageLabel")
                        local RoundB         = Instance.new("ImageLabel")

                        local HueHolder      = Instance.new("ImageLabel")
                        local HueBar         = Instance.new("ImageLabel")
                        local HueMarker      = Instance.new("Frame")

                        local SatHolder      = Instance.new("ImageLabel")
                        local SatSurface     = Instance.new("ImageLabel")
                        local SatMarker      = Instance.new("ImageLabel")

                        -- Layout
                        Holder.Name = pickerId .. "ColorPickerHolder"
                        Holder.Parent = SectionFrame
                        Holder.BackgroundColor3 = Color3.new(0.137, 0.137, 0.137)
                        Holder.BorderSizePixel = 0
                        Holder.Size = UDim2.new(0, 170, 0, 30)

                        PickerTitle.Name = "ColorPickerTitle"
                        PickerTitle.Parent = Holder
                        PickerTitle.BackgroundColor3 = Color3.new(1, 1, 1)
                        PickerTitle.BackgroundTransparency = 1
                        PickerTitle.BorderSizePixel = 0
                        PickerTitle.Position = UDim2.new(0.052941, 0, 0, 0)
                        PickerTitle.Size = UDim2.new(0, 125, 0, 30)
                        PickerTitle.Font = Enum.Font.SourceSansBold
                        PickerTitle.Text = label
                        PickerTitle.TextColor3 = Color3.new(1, 1, 1)
                        PickerTitle.TextSize = 17
                        PickerTitle.TextXAlignment = Enum.TextXAlignment.Left

                        ColorSwatch.Name = "ColorPickerToggle"
                        ColorSwatch.Parent = Holder
                        ColorSwatch.BackgroundColor3 = Color3.new(1, 1, 1)
                        ColorSwatch.BackgroundTransparency = 1
                        ColorSwatch.Position = UDim2.new(0.822, 0, 0.167, 0)
                        ColorSwatch.Size = UDim2.new(0, 22, 0, 20)
                        ColorSwatch.Image = "rbxassetid://3570695787"
                        ColorSwatch.ImageColor3 = defaultColor
                        ColorSwatch.ScaleType = Enum.ScaleType.Slice
                        ColorSwatch.SliceCenter = Rect.new(100, 100, 100, 100)
                        ColorSwatch.SliceScale = 0.04

                        PickerPopup.Name = "ColorPickerMain"
                        PickerPopup.Parent = Holder
                        PickerPopup.BackgroundColor3 = Color3.new(0.137, 0.137, 0.137)
                        PickerPopup.BackgroundTransparency = 1
                        PickerPopup.ClipsDescendants = true
                        PickerPopup.BorderSizePixel = 0
                        PickerPopup.Position = UDim2.new(1.04706, 0, -1.36667, 0)
                        PickerPopup.Size = UDim2.new(0, 0, 0, 175)
                        PickerPopup.Image = "rbxassetid://3570695787"
                        PickerPopup.ImageColor3 = Color3.new(0.137, 0.137, 0.137)
                        PickerPopup.ScaleType = Enum.ScaleType.Slice
                        PickerPopup.SliceCenter = Rect.new(100, 100, 100, 100)
                        PickerPopup.SliceScale = 0.05
                        PickerPopup.ZIndex = 1 + zi

                        -- Rainbow toggle row
                        RainbowHolder.Name = "RainbowToggleHolder"
                        RainbowHolder.Parent = PickerPopup
                        RainbowHolder.BackgroundColor3 = Color3.new(0.137, 0.137, 0.137)
                        RainbowHolder.BackgroundTransparency = 1
                        RainbowHolder.BorderSizePixel = 0
                        RainbowHolder.Position = UDim2.new(0, 0, 0.82, 0)
                        RainbowHolder.Size = UDim2.new(0, 170, 0, 30)
                        RainbowHolder.ZIndex = 1 + zi

                        RainbowTitle.Name = "RainbowTitle"
                        RainbowTitle.Parent = RainbowHolder
                        RainbowTitle.BackgroundColor3 = Color3.new(1, 1, 1)
                        RainbowTitle.BackgroundTransparency = 1
                        RainbowTitle.BorderSizePixel = 0
                        RainbowTitle.Position = UDim2.new(0.052941, 0, 0, 0)
                        RainbowTitle.Size = UDim2.new(0, 125, 0, 30)
                        RainbowTitle.Font = Enum.Font.SourceSansBold
                        RainbowTitle.Text = "Rainbow"
                        RainbowTitle.TextColor3 = Color3.new(1, 1, 1)
                        RainbowTitle.TextSize = 17
                        RainbowTitle.TextXAlignment = Enum.TextXAlignment.Left
                        RainbowTitle.ZIndex = 1 + zi

                        RainbowBg.Name = "RainbowBackground"
                        RainbowBg.Parent = RainbowHolder
                        RainbowBg.BackgroundColor3 = Color3.new(1, 1, 1)
                        RainbowBg.BackgroundTransparency = 1
                        RainbowBg.BorderSizePixel = 0
                        RainbowBg.Position = UDim2.new(0.847059, 0, 0.166667, 0)
                        RainbowBg.Size = UDim2.new(0, 20, 0, 20)
                        RainbowBg.Image = "rbxassetid://3570695787"
                        RainbowBg.ImageColor3 = Color3.new(0.254902, 0.254902, 0.254902)
                        RainbowBg.ZIndex = 1 + zi

                        RainbowBtn.Name = "RainbowToggleButton"
                        RainbowBtn.Parent = RainbowBg
                        RainbowBtn.BackgroundColor3 = Color3.new(1, 1, 1)
                        RainbowBtn.BackgroundTransparency = 1
                        RainbowBtn.Position = UDim2.new(0, 2, 0, 2)
                        RainbowBtn.Size = UDim2.new(0, 16, 0, 16)
                        RainbowBtn.Image = "rbxassetid://3570695787"
                        RainbowBtn.ImageColor3 = Color3.new(1, 0.341176, 0.341176)
                        RainbowBtn.ImageTransparency = 1
                        RainbowBtn.ZIndex = 1 + zi

                        -- RGB value labels
                        local function makeRgbLabel(name, xPos)
                            local lbl = Instance.new("TextLabel")
                            lbl.Name = name
                            lbl.Parent = PickerPopup
                            lbl.BackgroundColor3 = Color3.new(0.254902, 0.254902, 0.254902)
                            lbl.BackgroundTransparency = 1
                            lbl.BorderSizePixel = 0
                            lbl.ClipsDescendants = true
                            lbl.Position = UDim2.new(0, xPos, 0, 127)
                            lbl.Size = UDim2.new(0, 50, 0, 16)
                            lbl.ZIndex = 2 + zi
                            lbl.Font = Enum.Font.SourceSansBold
                            lbl.TextColor3 = Color3.new(1, 1, 1)
                            lbl.TextSize = 14

                            local round = Instance.new("ImageLabel")
                            round.Active = true
                            round.AnchorPoint = Vector2.new(0.5, 0.5)
                            round.BackgroundColor3 = Color3.new(1, 1, 1)
                            round.BackgroundTransparency = 1
                            round.Position = UDim2.new(0.5, 0, 0.5, 0)
                            round.Selectable = true
                            round.Size = UDim2.new(1, 0, 1, 0)
                            round.Image = "rbxassetid://3570695787"
                            round.ImageColor3 = Color3.new(0.254902, 0.254902, 0.254902)
                            round.ScaleType = Enum.ScaleType.Slice
                            round.SliceCenter = Rect.new(100, 100, 100, 100)
                            round.SliceScale = 0.04
                            round.ZIndex = 1 + zi
                            round.Parent = lbl

                            return lbl
                        end

                        LabelR = makeRgbLabel("ColorValueR", 7)
                        LabelR.Text = "R: 000"
                        LabelG = makeRgbLabel("ColorValueG", 60)
                        LabelG.Text = "G: 000"
                        LabelB = makeRgbLabel("ColorValueB", 114)
                        LabelB.Text = "B: 000"

                        -- Hue strip
                        HueHolder.Name = "RoundHueHolder"
                        HueHolder.Parent = PickerPopup
                        HueHolder.BackgroundColor3 = Color3.new(1, 1, 1)
                        HueHolder.BackgroundTransparency = 1
                        HueHolder.ClipsDescendants = true
                        HueHolder.Position = UDim2.new(0, 136, 0, 6)
                        HueHolder.Size = UDim2.new(0, 28, 0, 114)
                        HueHolder.ZIndex = 2 + zi
                        HueHolder.Image = "rbxassetid://4695575676"
                        HueHolder.ImageColor3 = Color3.new(0.137, 0.137, 0.137)
                        HueHolder.ScaleType = Enum.ScaleType.Slice
                        HueHolder.SliceCenter = Rect.new(128, 128, 128, 128)
                        HueHolder.SliceScale = 0.05

                        HueBar.Name = "ColorHue"
                        HueBar.Parent = HueHolder
                        HueBar.BackgroundColor3 = Color3.new(1, 1, 1)
                        HueBar.BackgroundTransparency = 1
                        HueBar.BorderSizePixel = 0
                        HueBar.Size = UDim2.new(0, 28, 0, 114)
                        HueBar.Image = "http://www.roblox.com/asset/?id=4801885250"
                        HueBar.ScaleType = Enum.ScaleType.Crop
                        HueBar.ZIndex = 1 + zi

                        HueMarker.Name = "HueMarker"
                        HueMarker.Parent = HueHolder
                        HueMarker.BackgroundColor3 = Color3.new(0.294118, 0.294118, 0.294118)
                        HueMarker.BorderSizePixel = 0
                        HueMarker.Position = UDim2.new(-0.25, 0, 0, 0)
                        HueMarker.Size = UDim2.new(0, 42, 0, 5)
                        HueMarker.ZIndex = 1 + zi

                        -- Saturation square
                        SatHolder.Name = "RoundSaturationHolder"
                        SatHolder.Parent = PickerPopup
                        SatHolder.BackgroundColor3 = Color3.new(1, 1, 1)
                        SatHolder.BackgroundTransparency = 1
                        SatHolder.ClipsDescendants = true
                        SatHolder.Position = UDim2.new(0, 7, 0, 6)
                        SatHolder.Size = UDim2.new(0, 122, 0, 114)
                        SatHolder.ZIndex = 2 + zi
                        SatHolder.Image = "rbxassetid://4695575676"
                        SatHolder.ImageColor3 = Color3.new(0.137, 0.137, 0.137)
                        SatHolder.ScaleType = Enum.ScaleType.Slice
                        SatHolder.SliceCenter = Rect.new(128, 128, 128, 128)
                        SatHolder.SliceScale = 0.05

                        SatSurface.Name = "ColorSelector"
                        SatSurface.Parent = SatHolder
                        SatSurface.BackgroundColor3 = defaultColor
                        SatSurface.BorderSizePixel = 0
                        SatSurface.Size = UDim2.new(0, 122, 0, 114)
                        SatSurface.Image = "rbxassetid://4805274903"
                        SatSurface.ZIndex = 1 + zi

                        SatMarker.Name = "SaturationMarker"
                        SatMarker.Parent = SatHolder
                        SatMarker.BackgroundColor3 = Color3.new(1, 1, 1)
                        SatMarker.BackgroundTransparency = 1
                        SatMarker.Size = UDim2.new(0, 0, 0, 0)
                        SatMarker.Image = "http://www.roblox.com/asset/?id=4805639000"
                        SatMarker.ZIndex = 1 + zi

                        -- Helpers
                        local function updateRgbLabels()
                            local c = ColorSwatch.ImageColor3
                            LabelR.Text = "R: " .. math.floor(c.R * 255)
                            LabelG.Text = "G: " .. math.floor(c.G * 255)
                            LabelB.Text = "B: " .. math.floor(c.B * 255)
                        end

                        local function applyHSV()
                            local color = Color3.fromHSV(HSV.H, HSV.S, HSV.V)
                            ColorSwatch.ImageColor3 = color
                            SatSurface.BackgroundColor3 = Color3.fromHSV(HSV.H, 1, 1)
                            callback(color)
                            updateRgbLabels()
                        end

                        local function getSatUV(frame)
                            local x = math.clamp((Mouse.X - frame.AbsolutePosition.X) / frame.AbsoluteSize.X, 0, 1)
                            local y = math.clamp((Mouse.Y - frame.AbsolutePosition.Y) / frame.AbsoluteSize.Y, 0, 1)
                            return x, y
                        end

                        local function getHueY(frame)
                            return math.clamp(Mouse.Y - frame.AbsolutePosition.Y, -10, frame.AbsoluteSize.Y)
                                   / frame.AbsoluteSize.Y
                        end

                        updateRgbLabels()

                        -- Popup open/close
                        local function closePopup()
                            pickerOpen = false
                            tween(PickerPopup, TWEEN_SLOW, { Size = UDim2.new(0, 0, 0, 175) })
                            Body.ClipsDescendants = true
                            SectionFrame.ClipsDescendants = true
                        end

                        ColorSwatch.MouseButton1Down:Connect(function()
                            if pickerOpen then
                                closePopup()
                            else
                                pickerOpen = true
                                Body.ClipsDescendants = false
                                SectionFrame.ClipsDescendants = false
                                tween(PickerPopup, TWEEN_SLOW, { Size = UDim2.new(0, 171, 0, 175) })
                            end
                        end)

                        -- Saturation dragging
                        SatSurface.InputBegan:Connect(function(i)
                            if i.UserInputType == Enum.UserInputType.MouseButton1 and not rainbowOn then
                                if satConn then satConn:Disconnect() end
                                satConn = RunService.RenderStepped:Connect(function()
                                    local u, v = getSatUV(SatHolder)
                                    SatMarker.Position = UDim2.new(u, 0, v, 0)
                                    HSV.S = u
                                    HSV.V = 1 - v
                                    applyHSV()
                                end)
                            end
                        end)
                        SatSurface.InputEnded:Connect(function(i)
                            if i.UserInputType == Enum.UserInputType.MouseButton1 and satConn then
                                satConn:Disconnect()
                                satConn = nil
                            end
                        end)
                        SatSurface.MouseLeave:Connect(function()
                            if satConn then satConn:Disconnect() satConn = nil end
                        end)

                        -- Hue dragging
                        HueBar.InputBegan:Connect(function(i)
                            if i.UserInputType == Enum.UserInputType.MouseButton1 and not rainbowOn then
                                if hueConn then hueConn:Disconnect() end
                                hueConn = RunService.RenderStepped:Connect(function()
                                    local _, vNorm = getSatUV(HueHolder)
                                    local y = getHueY(HueHolder)
                                    HSV.H = 1 - vNorm
                                    tween(HueMarker, TWEEN_SLIDE, { Position = UDim2.new(-0.25, 0, y, 0) })
                                    applyHSV()
                                end)
                            end
                        end)
                        HueBar.InputEnded:Connect(function(i)
                            if i.UserInputType == Enum.UserInputType.MouseButton1 and hueConn then
                                hueConn:Disconnect()
                                hueConn = nil
                            end
                        end)
                        HueBar.MouseLeave:Connect(function()
                            if hueConn then hueConn:Disconnect() hueConn = nil end
                        end)

                        -- Rainbow mode
                        RainbowBtn.MouseButton1Down:Connect(function()
                            rainbowOn = not rainbowOn
                            tween(RainbowBtn, TWEEN_MED, { ImageTransparency = rainbowOn and 0 or 1 })

                            while rainbowOn do
                                local c = Color3.fromHSV(hue, 1, 1)
                                ColorSwatch.ImageColor3 = c
                                SatSurface.BackgroundColor3 = c
                                callback(c)
                                updateRgbLabels()
                                wait()
                            end
                        end)

                        -- Section/window collapse cleans up picker
                        SectionToggle.MouseButton1Down:Connect(function()
                            closePopup()
                            if sectionOpen then
                                shrinkSection(30)
                                shrinkBody(30)
                            else
                                growSection(30)
                                growBody(30)
                            end
                        end)

                        ToggleBtn.MouseButton1Down:Connect(function()
                            closePopup()
                            onWindowToggleForSection()
                        end)
                    end,

                    -- ── Button ────────────────────────────────────────────────
                    CreateButton = function(_, label, callback)
                        local buttonId = stripSpaces(label)

                        local Holder = Instance.new("Frame")
                        local Btn    = Instance.new("TextButton")
                        local Round  = Instance.new("ImageLabel")

                        Holder.Name = buttonId .. "ButtonHolder"
                        Holder.Parent = SectionFrame
                        Holder.BackgroundColor3 = Color3.new(0.137, 0.137, 0.137)
                        Holder.BorderSizePixel = 0
                        Holder.Size = UDim2.new(0, 170, 0, 30)

                        Btn.Name = "Button"
                        Btn.Parent = Holder
                        Btn.BackgroundColor3 = Color3.new(0.254902, 0.254902, 0.254902)
                        Btn.BackgroundTransparency = 1
                        Btn.BorderSizePixel = 0
                        Btn.Position = UDim2.new(0.052941, 0, 0, 0)
                        Btn.Size = UDim2.new(0, 153, 0, 24)
                        Btn.ZIndex = 2
                        Btn.AutoButtonColor = false
                        Btn.Font = Enum.Font.SourceSansBold
                        Btn.Text = label
                        Btn.TextColor3 = Color3.new(1, 1, 1)
                        Btn.TextSize = 14

                        Round.Name = "ButtonRound"
                        Round.Parent = Btn
                        Round.Active = true
                        Round.AnchorPoint = Vector2.new(0.5, 0.5)
                        Round.BackgroundColor3 = Color3.new(1, 1, 1)
                        Round.BackgroundTransparency = 1
                        Round.BorderSizePixel = 0
                        Round.ClipsDescendants = true
                        Round.Position = UDim2.new(0.5, 0, 0.5, 0)
                        Round.Selectable = true
                        Round.Size = UDim2.new(1, 0, 1, 0)
                        Round.Image = "rbxassetid://3570695787"
                        Round.ImageColor3 = Color3.new(0.254902, 0.254902, 0.254902)
                        Round.ScaleType = Enum.ScaleType.Slice
                        Round.SliceCenter = Rect.new(100, 100, 100, 100)
                        Round.SliceScale = 0.04

                        Btn.MouseButton1Down:Connect(function()
                            callback(Btn)
                        end)

                        SectionToggle.MouseButton1Down:Connect(function()
                            if sectionOpen then
                                shrinkSection(30)
                                shrinkBody(30)
                            else
                                growSection(30)
                                growBody(30)
                            end
                        end)

                        ToggleBtn.MouseButton1Down:Connect(onWindowToggleForSection)
                    end,

                    -- ── Textbox ───────────────────────────────────────────────
                    CreateTextbox = function(_, placeholder, callback)
                        local tbId = stripSpaces(placeholder)

                        local Holder = Instance.new("Frame")
                        local TB     = Instance.new("TextBox")
                        local Round  = Instance.new("ImageLabel")

                        Holder.Name = tbId .. "TextBoxHolder"
                        Holder.Parent = SectionFrame
                        Holder.BackgroundColor3 = Color3.new(0.137, 0.137, 0.137)
                        Holder.BorderSizePixel = 0
                        Holder.Size = UDim2.new(0, 170, 0, 30)

                        TB.Parent = Holder
                        TB.BackgroundColor3 = Color3.new(0.254902, 0.254902, 0.254902)
                        TB.BackgroundTransparency = 1
                        TB.ClipsDescendants = true
                        TB.Position = UDim2.new(0.053, 0, 0, 0)
                        TB.Size = UDim2.new(0, 153, 0, 24)
                        TB.ZIndex = 2
                        TB.Font = Enum.Font.SourceSansBold
                        TB.PlaceholderText = placeholder
                        TB.Text = ""
                        TB.TextColor3 = Color3.new(1, 1, 1)
                        TB.TextSize = 14

                        Round.Name = "TextBoxRound"
                        Round.Parent = TB
                        Round.Active = true
                        Round.AnchorPoint = Vector2.new(0.5, 0.5)
                        Round.BackgroundColor3 = Color3.new(1, 1, 1)
                        Round.BackgroundTransparency = 1
                        Round.BorderSizePixel = 0
                        Round.ClipsDescendants = true
                        Round.Position = UDim2.new(0.5, 0, 0.5, 0)
                        Round.Selectable = true
                        Round.Size = UDim2.new(1, 0, 1, 0)
                        Round.Image = "rbxassetid://3570695787"
                        Round.ImageColor3 = Color3.new(0.254902, 0.254902, 0.254902)
                        Round.ScaleType = Enum.ScaleType.Slice
                        Round.SliceCenter = Rect.new(100, 100, 100, 100)
                        Round.SliceScale = 0.04

                        TB.FocusLost:Connect(function(enterPressed)
                            if enterPressed then
                                callback(TB.Text)
                            end
                        end)

                        SectionToggle.MouseButton1Down:Connect(function()
                            if sectionOpen then
                                shrinkSection(30)
                                shrinkBody(30)
                            else
                                growSection(30)
                                growBody(30)
                            end
                        end)

                        ToggleBtn.MouseButton1Down:Connect(onWindowToggleForSection)
                    end,

                    -- ── Dropdown ──────────────────────────────────────────────
                    CreateDropdown = function(_, label, options, defaultIndex, callback)
                        local ddId = stripSpaces(label)
                        local canvasScale = 1
                        local selected = options[defaultIndex]
                        local dropHeight = 0
                        local isOpen = false
                        local hasScrollbar = false

                        local Holder       = Instance.new("Frame")
                        local DisplayLabel = Instance.new("TextLabel")
                        local DDRound      = Instance.new("ImageLabel")
                        local ArrowBtn     = Instance.new("TextButton")
                        local Popup        = Instance.new("ImageLabel")
                        local Scroll       = Instance.new("ScrollingFrame")
                        local ScrollLayout = Instance.new("UIListLayout")

                        Holder.Name = ddId .. "DropdownHolder"
                        Holder.Parent = SectionFrame
                        Holder.BackgroundColor3 = Color3.new(0.137, 0.137, 0.137)
                        Holder.BorderSizePixel = 0
                        Holder.Size = UDim2.new(0, 170, 0, 30)

                        DisplayLabel.Name = "DropdownTitle"
                        DisplayLabel.Parent = Holder
                        DisplayLabel.BackgroundColor3 = Color3.new(0.254902, 0.254902, 0.254902)
                        DisplayLabel.BackgroundTransparency = 1
                        DisplayLabel.BorderSizePixel = 0
                        DisplayLabel.Position = UDim2.new(0.053, 0, 0, 0)
                        DisplayLabel.Size = UDim2.new(0, 153, 0, 24)
                        DisplayLabel.ZIndex = 2
                        DisplayLabel.Font = Enum.Font.SourceSansBold
                        DisplayLabel.Text = selected
                        DisplayLabel.TextColor3 = Color3.new(1, 1, 1)
                        DisplayLabel.TextSize = 14

                        DDRound.Name = "DropdownRound"
                        DDRound.Parent = DisplayLabel
                        DDRound.Active = true
                        DDRound.AnchorPoint = Vector2.new(0.5, 0.5)
                        DDRound.BackgroundColor3 = Color3.new(1, 1, 1)
                        DDRound.BackgroundTransparency = 1
                        DDRound.BorderSizePixel = 0
                        DDRound.ClipsDescendants = true
                        DDRound.Position = UDim2.new(0.5, 0, 0.5, 0)
                        DDRound.Selectable = true
                        DDRound.Size = UDim2.new(1, 0, 1, 0)
                        DDRound.Image = "rbxassetid://3570695787"
                        DDRound.ImageColor3 = Color3.new(0.254902, 0.254902, 0.254902)
                        DDRound.ScaleType = Enum.ScaleType.Slice
                        DDRound.SliceCenter = Rect.new(100, 100, 100, 100)
                        DDRound.SliceScale = 0.04

                        ArrowBtn.Name = "DropdownToggle"
                        ArrowBtn.Parent = DisplayLabel
                        ArrowBtn.BackgroundColor3 = Color3.new(1, 1, 1)
                        ArrowBtn.BackgroundTransparency = 1
                        ArrowBtn.Position = UDim2.new(0.816928, 0, 0, 0)
                        ArrowBtn.Size = UDim2.new(0, 28, 0, 24)
                        ArrowBtn.AutoButtonColor = false
                        ArrowBtn.Font = Enum.Font.SourceSansBold
                        ArrowBtn.Text = ">"
                        ArrowBtn.TextColor3 = Color3.new(1, 1, 1)
                        ArrowBtn.TextSize = 15

                        Popup.Name = "DropdownMain"
                        Popup.Parent = DisplayLabel
                        Popup.BackgroundColor3 = Color3.new(0.137, 0.137, 0.137)
                        Popup.BackgroundTransparency = 1
                        Popup.ClipsDescendants = true
                        Popup.Position = UDim2.new(1.09275, 0, -0.033666, 0)
                        Popup.Size = UDim2.new(0, 0, 0, dropHeight)
                        Popup.Image = "rbxassetid://3570695787"
                        Popup.ImageColor3 = Color3.new(0.137, 0.137, 0.137)
                        Popup.ScaleType = Enum.ScaleType.Slice
                        Popup.SliceCenter = Rect.new(100, 100, 100, 100)
                        Popup.SliceScale = 0.04

                        Scroll.Parent = Popup
                        Scroll.BackgroundColor3 = Color3.new(1, 1, 1)
                        Scroll.BackgroundTransparency = 1
                        Scroll.BorderSizePixel = 0
                        Scroll.Size = UDim2.new(0, 153, 0, dropHeight)
                        Scroll.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
                        Scroll.CanvasSize = UDim2.new(0, 0, canvasScale, 0)
                        Scroll.ScrollBarThickness = 3
                        Scroll.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
                        Scroll.ScrollingDirection = "Y"

                        ScrollLayout.Name = "ButtonLayout"
                        ScrollLayout.Parent = Scroll
                        ScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder

                        -- Close helper
                        local function closeDropdown()
                            isOpen = false
                            ArrowBtn.Text = ">"
                            tween(ArrowBtn, TWEEN_MED, { Rotation = 0 })
                            tween(DisplayLabel, TWEEN_MED, { TextColor3 = Color3.new(1, 1, 1) })
                            DisplayLabel.Text = selected
                            tween(Scroll, TWEEN_MED, { ScrollBarImageTransparency = 1 })
                            tween(Scroll, TWEEN_MED, { Size = UDim2.new(0, 0, 0, dropHeight) })
                            tween(Popup, TWEEN_MED, { Size = UDim2.new(0, 0, 0, dropHeight) })
                        end

                        -- Build option rows
                        local rowCount = 0
                        for _, optionText in ipairs(options) do
                            local OptionBtn = Instance.new("TextButton")
                            rowCount = rowCount + 1

                            OptionBtn.Name = stripSpaces(optionText) .. "Button"
                            OptionBtn.Parent = Scroll
                            OptionBtn.BackgroundColor3 = Color3.new(0.215686, 0.215686, 0.215686)
                            OptionBtn.BackgroundTransparency = 1
                            OptionBtn.BorderSizePixel = 0
                            OptionBtn.Size = UDim2.new(0, 153, 0, 25)
                            OptionBtn.AutoButtonColor = false
                            OptionBtn.Font = Enum.Font.SourceSansBold
                            OptionBtn.Text = optionText
                            OptionBtn.TextColor3 = Color3.new(1, 1, 1)
                            OptionBtn.TextSize = 14

                            if rowCount <= 4 then
                                dropHeight = dropHeight + 25
                                Popup.Size = UDim2.new(0, 0, 0, dropHeight)
                            else
                                hasScrollbar = true
                            end
                            if hasScrollbar then
                                canvasScale = canvasScale + 0.25
                                Scroll.CanvasSize = UDim2.new(0, 0, canvasScale, 0)
                            end

                            OptionBtn.InputBegan:Connect(function(i)
                                if i.UserInputType == Enum.UserInputType.MouseMovement then
                                    tween(OptionBtn, TWEEN_MED, { BackgroundTransparency = 0.5 })
                                end
                            end)
                            OptionBtn.InputEnded:Connect(function(i)
                                if i.UserInputType == Enum.UserInputType.MouseMovement then
                                    tween(OptionBtn, TWEEN_MED, { BackgroundTransparency = 1 })
                                end
                            end)

                            OptionBtn.MouseButton1Down:Connect(function()
                                selected = optionText
                                callback(optionText)
                                closeDropdown()
                            end)
                        end

                        -- Arrow toggle
                        ArrowBtn.MouseButton1Down:Connect(function()
                            if isOpen then
                                closeDropdown()
                            else
                                Body.ClipsDescendants = false
                                SectionFrame.ClipsDescendants = false
                                isOpen = true
                                ArrowBtn.Text = "<"
                                tween(ArrowBtn, TWEEN_MED, { Rotation = -360 })
                                tween(DisplayLabel, TWEEN_MED, { TextColor3 = Color3.new(0.698039, 0.698039, 0.698039) })
                                DisplayLabel.Text = label
                                tween(Scroll, TWEEN_MED, { ScrollBarImageTransparency = 0 })
                                tween(Scroll, TWEEN_MED, { Size = UDim2.new(0, 153, 0, dropHeight) })
                                tween(Popup, TWEEN_MED, { Size = UDim2.new(0, 153, 0, dropHeight) })
                            end
                        end)

                        SectionToggle.MouseButton1Down:Connect(function()
                            closeDropdown()
                            Body.ClipsDescendants = true
                            SectionFrame.ClipsDescendants = true
                            if sectionOpen then
                                shrinkSection(30)
                                shrinkBody(30)
                            else
                                growSection(30)
                                growBody(30)
                            end
                        end)

                        ToggleBtn.MouseButton1Down:Connect(function()
                            closeDropdown()
                            Body.ClipsDescendants = true
                            SectionFrame.ClipsDescendants = true
                            onWindowToggleForSection()
                        end)
                    end,
                }
            end,
        }
    end,
}
