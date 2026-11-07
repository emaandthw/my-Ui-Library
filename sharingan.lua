return function(Window)
    local function makeSharingan(raw)
        local CoreGui = game:GetService("CoreGui")
        local RunService = game:GetService("RunService")
        local TweenService = game:GetService("TweenService")
        local UIS = game:GetService("UserInputService")
        local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
        if not isMobile then return nil end
        local old = CoreGui:FindFirstChild("PnkaSharingan")
        if old then old:Destroy() end
        local gui = Instance.new("ScreenGui")
        gui.Name = "PnkaSharingan"
        gui.ResetOnSpawn = false
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.Parent = CoreGui
        local btn = Instance.new("TextButton")
        btn.Name = "SharinganBtn"
        btn.Parent = gui
        btn.AnchorPoint = Vector2.new(0, 1)
        btn.Size = UDim2.new(0, 50, 0, 50)
        btn.Position = UDim2.new(0, 15, 1, -15)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.AutoButtonColor = false
        local IMAGES = {
            "rbxassetid://129621581849239",
            "rbxassetid://76829292090480",
            "rbxassetid://104188192963138",
        }
        local tomoe = {}
        for i = 1, 3 do
            local img = Instance.new("ImageLabel")
            img.Name = "Tomoe" .. i
            img.Parent = btn
            img.Size = UDim2.fromScale(1, 1)
            img.BackgroundTransparency = 1
            img.BorderSizePixel = 0
            img.Image = IMAGES[i]
            img.ScaleType = Enum.ScaleType.Fit
            img.Visible = i == 3
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = img
            tomoe[i] = img
        end
        local curTomoe = 3
        local wanted = 3
        local busy = false
        local lastClick = 0
        local COOLDOWN = 0.9
        local function setTomoe(n)
            curTomoe = n
            for i, img in ipairs(tomoe) do
                img.Visible = (i == n)
            end
        end
        local function spin(target)
            local dir = target > curTomoe and 1 or -1
            local steps = math.abs(target - curTomoe)
            local tw = TweenService:Create(btn, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Rotation = btn.Rotation + 180
            })
            tw:Play()
            task.spawn(function()
                for _ = 1, steps do
                    task.wait(0.8 / (steps + 1))
                    setTomoe(curTomoe + dir)
                end
            end)
            tw.Completed:Wait()
        end
        local dragging, dragInput, dragStart, startPos, holdStarted = false, nil, nil, nil, 0
        local dragged = false
        local HOLD = 0.1
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                holdStarted = tick()
                dragged = false
                dragStart = input.Position
                startPos = btn.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        holdStarted = 0
                        dragInput = nil
                    end
                end)
            end
        end)
        btn.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        RunService.RenderStepped:Connect(function()
            if holdStarted > 0 and not dragging and tick() - holdStarted >= HOLD then
                dragging = true
            end
            if dragging and dragInput and dragStart then
                local d = dragInput.Position - dragStart
                if d.Magnitude > 6 then dragged = true end
                btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
        btn.MouseButton1Click:Connect(function()
            if dragged then dragged = false return end
            local now = tick()
            if busy or now - lastClick < COOLDOWN then return end
            lastClick = now
            raw:Toggle()
        end)
        local function playSpin(target)
            wanted = target
            if busy then return end
            busy = true
            task.spawn(function()
                spin(target)
                if curTomoe ~= wanted then setTomoe(wanted) end
                busy = false
            end)
        end
        return gui, playSpin
    end

    local gui, playSpin = makeSharingan({ Toggle = function() Window:Minimize() end })
    if playSpin then
        local origMinimize = Window.Minimize
        Window.Minimize = function(self, ...)
            origMinimize(self, ...)
            playSpin(Window.Minimized and 1 or 3)
        end
    end
    return gui
end
