--[[
    WallyLib - UI Library (cleaned)
]]

local Library = {
    count        = 0,
    queue        = {},
    callbacks    = {},
    rainbowtable = {},
    toggled      = true,
    binds        = {},
    connections  = {},   -- kết nối toàn cục (Destroy sẽ ngắt hết)
    windows      = {},   -- danh sách window đã tạo
    destroyed    = false,
}

local WindowMeta = {}
WindowMeta.__index = WindowMeta

local UIS    = game:GetService("UserInputService")
local RS     = game:GetService("RunService")
local Debris = game:GetService("Debris")

---------------------------------------------------------------------------
-- Theme mặc định
---------------------------------------------------------------------------
local default = {
    topcolor         = Color3.fromRGB(30, 30, 30),
    titlecolor       = Color3.fromRGB(255, 255, 255),
    underlinecolor   = Color3.fromRGB(0, 0, 255),
    bgcolor          = Color3.fromRGB(35, 35, 35),
    boxcolor         = Color3.fromRGB(35, 35, 35),
    btncolor         = Color3.fromRGB(25, 25, 25),
    dropcolor        = Color3.fromRGB(25, 25, 25),
    sectncolor       = Color3.fromRGB(25, 25, 25),
    bordercolor      = Color3.fromRGB(60, 60, 60),
    font             = Enum.Font.SourceSans,
    titlefont        = Enum.Font.Code,
    fontsize         = 17,
    titlesize        = 18,
    textstroke       = 1,
    titlestroke      = 1,
    strokecolor      = Color3.fromRGB(0, 0, 0),
    textcolor        = Color3.fromRGB(255, 255, 255),
    titletextcolor   = Color3.fromRGB(255, 255, 255),
    placeholdercolor = Color3.fromRGB(255, 255, 255),
    titlestrokecolor = Color3.fromRGB(0, 0, 0),
}

Library.options = setmetatable({}, { __index = default })

---------------------------------------------------------------------------
-- Helper: tạo instance
---------------------------------------------------------------------------
function Library.Create(_, className, props)
    local inst = Instance.new(className)
    for k, v in pairs(props) do
        if k ~= "Parent" then
            if typeof(v) == "Instance" then
                v.Parent = inst
            else
                inst[k] = v
            end
        end
    end
    inst.Parent = props.Parent
    return inst
end

---------------------------------------------------------------------------
-- Kéo window bằng thanh tiêu đề (chuột + cảm ứng)
---------------------------------------------------------------------------
local Drag = {}

function Drag.new(frame, onMoved)
    local dragging, dragInput, startInputPos, startFramePos
    local conns = {}

    local function clamp(x, y)
        local parent = frame.Parent
        local cam    = workspace.CurrentCamera
        local vp     = cam and cam.ViewportSize or Vector2.new(1920, 1080)
        local base   = parent and parent.AbsolutePosition or Vector2.new()
        -- giữ thanh tiêu đề luôn nằm trong màn hình
        x = math.clamp(x, -base.X, vp.X - base.X - 60)
        y = math.clamp(y, -base.Y, vp.Y - base.Y - 30)
        return x, y
    end

    local function beginDrag(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        dragging      = true
        dragInput     = input
        startInputPos = input.Position
        startFramePos = frame.Position

        local c
        c = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging  = false
                dragInput = nil
                c:Disconnect()
                if onMoved then onMoved(frame.Position) end
            end
        end)
    end

    local function hook(obj)
        table.insert(conns, obj.InputBegan:Connect(beginDrag))
    end

    -- kéo được từ nền thanh tiêu đề và cả chữ tiêu đề
    hook(frame)
    for _, child in ipairs(frame:GetChildren()) do
        if child:IsA("TextLabel") then hook(child) end
    end

    table.insert(conns, UIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input == dragInput then
            local delta = input.Position - startInputPos
            local x, y  = clamp(
                startFramePos.X.Offset + delta.X,
                startFramePos.Y.Offset + delta.Y
            )
            frame.Position = UDim2.new(0, x, 0, y)
        end
    end))

    frame.Destroying:Connect(function()
        for _, c in ipairs(conns) do c:Disconnect() end
    end)
end

---------------------------------------------------------------------------
-- Ẩn/hiện toàn bộ UI bằng RightControl
---------------------------------------------------------------------------
table.insert(Library.connections, UIS.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightControl then
        Library.toggled = not Library.toggled
        for _, entry in pairs(Library.queue) do
            local pos = Library.toggled and entry.p or UDim2.new(-1, 0, -0.5, 0)
            entry.w:TweenPosition(pos, Library.toggled and "Out" or "In", "Quad", 0.15, true)
        end
    end
end))

---------------------------------------------------------------------------
-- Keybind matching
---------------------------------------------------------------------------
local function matchBind(bind, input)
    if typeof(bind) == "Instance" then
        if bind.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == bind.KeyCode then
            return true
        end
        if tostring(bind.UserInputType):find("MouseButton") and input.UserInputType == bind.UserInputType then
            return true
        end
    end
    if tostring(bind):find("MouseButton1") then
        return bind == input.UserInputType
    else
        return bind == input.KeyCode
    end
end

table.insert(Library.connections, UIS.InputBegan:Connect(function(input)
    if Library.binding then return end
    for flag, data in pairs(Library.binds) do
        local val = data.location[flag]
        if val and matchBind(val, input) then
            data.callback()
        end
    end
end))

---------------------------------------------------------------------------
-- Vòng lặp rainbow
---------------------------------------------------------------------------
task.spawn(function()
    local hue = 0
    while not Library.destroyed do
        hue = (hue + 0.00333) % 1
        for _, obj in pairs(Library.rainbowtable) do
            obj.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        end
        task.wait()
    end
end)

---------------------------------------------------------------------------
-- Helper nội bộ của window
---------------------------------------------------------------------------
-- Tổng chiều cao các phần tử con (bỏ UIListLayout)
local function contentHeight(container)
    local height = 0
    for _, child in pairs(container:GetChildren()) do
        if not child:IsA("UIListLayout") then
            height = height + child.AbsoluteSize.Y
        end
    end
    return height
end

function WindowMeta:Resize()
    self.container.Size = UDim2.new(1, 0, 0, contentHeight(self.container) + 5)
end

-- LayoutOrder lớn nhất + 1 (đếm số con sẽ bị lệch khi có phần tử bị Destroy)
function WindowMeta:GetOrder()
    local maxOrder = -1
    for _, child in pairs(self.container:GetChildren()) do
        if not child:IsA("UIListLayout") then
            maxOrder = math.max(maxOrder, child.LayoutOrder)
        end
    end
    return maxOrder + 1
end

-- Lấy cfg.location / cfg.flag / cfg.default... dùng chung cho các control
local function readCfg(self, cfg)
    cfg = cfg or {}
    return cfg.location or self.flags, cfg.flag or "", cfg
end

---------------------------------------------------------------------------
-- WindowMeta:Destroy (xoá 1 window và dọn kết nối của nó)
---------------------------------------------------------------------------
function WindowMeta:Destroy()
    if self.destroyed then return end
    self.destroyed = true

    for _, fn in ipairs(self.cleanups) do
        pcall(fn)
    end
    self.cleanups = {}

    -- gỡ bind và callback thuộc window này
    for flag, data in pairs(Library.binds) do
        if data.owner == self then Library.binds[flag] = nil end
    end
    for _, flag in ipairs(self.callbackFlags) do
        Library.callbacks[flag] = nil
    end

    -- gỡ khỏi queue (RightControl) và rainbow
    local underline = self.object:FindFirstChild("Underline")
    for i = #Library.queue, 1, -1 do
        if Library.queue[i].w == self.object then table.remove(Library.queue, i) end
    end
    for i = #Library.rainbowtable, 1, -1 do
        if Library.rainbowtable[i] == underline then table.remove(Library.rainbowtable, i) end
    end
    for i = #Library.windows, 1, -1 do
        if Library.windows[i] == self then table.remove(Library.windows, i) end
    end

    self.object:Destroy()
end

---------------------------------------------------------------------------
-- WindowMeta.window (tạo khung window)
---------------------------------------------------------------------------
function WindowMeta.window(name, opt)
    Library.count = Library.count + 1

    local titleLabel = Library:Create("TextLabel", {
        Text                  = name,
        Size                  = UDim2.new(1, -10, 1, 0),
        Position              = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency= 1,
        Font                  = opt.titlefont,
        TextSize              = opt.titlesize,
        TextColor3            = opt.titletextcolor,
        TextStrokeTransparency= opt.titlestroke,
        TextStrokeColor3      = opt.titlestrokecolor,
        ZIndex                = 3,
    })

    local toggleBtn = Library:Create("TextButton", {
        Name                  = "window_toggle",
        Size                  = UDim2.new(0, 30, 0, 30),
        Position              = UDim2.new(1, -35, 0, 0),
        BackgroundTransparency= 1,
        Text                  = "-",
        TextSize              = opt.titlesize,
        Font                  = opt.titlefont,
        TextColor3            = opt.titletextcolor,
        TextStrokeTransparency= opt.titlestroke,
        TextStrokeColor3      = opt.titlestrokecolor,
        ZIndex                = 3,
    })

    local underline = Library:Create("Frame", {
        Name            = "Underline",
        Size            = UDim2.new(1, 0, 0, 2),
        Position        = UDim2.new(0, 0, 1, -2),
        BackgroundColor3= opt.underlinecolor ~= "rainbow" and opt.underlinecolor or Color3.new(),
        BorderSizePixel = 0,
        ZIndex          = 3,
    })

    local container = Library:Create("Frame", {
        Name            = "container",
        Position        = UDim2.new(0, 0, 1, 0),
        Size            = UDim2.new(1, 0, 0, 0),
        BorderSizePixel = 0,
        BackgroundColor3= opt.bgcolor,
        ClipsDescendants= false,
        Library:Create("UIListLayout", { Name = "List", SortOrder = Enum.SortOrder.LayoutOrder }),
    })

    local frame = Library:Create("Frame", {
        Name            = name,
        Size            = UDim2.new(0, 190, 0, 30),
        BackgroundColor3= opt.topcolor,
        BorderSizePixel = 0,
        Parent          = Library.container,
        Position        = UDim2.new(0, 15 + 200 * Library.count - 200, 0, 0),
        ZIndex          = 3,
        titleLabel,
        toggleBtn,
        underline,
        container,
    })

    if opt.underlinecolor == "rainbow" then
        table.insert(Library.rainbowtable, underline)
    end

    local win = setmetatable({
        count         = 0,
        object        = frame,
        container     = container,
        toggled       = true,
        flags         = {},
        cleanups      = {},
        callbackFlags = {},
        destroyed     = false,
    }, WindowMeta)

    table.insert(Library.queue, { w = win.object, p = win.object.Position })

    toggleBtn.MouseButton1Click:Connect(function()
        win.toggled = not win.toggled
        toggleBtn.Text = win.toggled and "+" or "-"

        if not win.toggled then
            win.container.ClipsDescendants = true
        end
        task.wait()

        local targetSize = win.toggled
            and UDim2.new(1, 0, 0, contentHeight(win.container) + 5)
            or  UDim2.new(1, 0, 0, 0)
        win.container:TweenSize(targetSize, win.toggled and "In" or "Out", "Quint", 0.3, true)
        task.wait(0.3)

        if win.toggled then
            win.container.ClipsDescendants = false
        end
    end)

    return win
end

---------------------------------------------------------------------------
-- Toggle
---------------------------------------------------------------------------
function WindowMeta:Toggle(label, cfg, callback)
    cfg = cfg or {}
    local loc, flag, _ = readCfg(self, cfg)
    local cb  = callback or function() end
    local val = cfg.default or false
    loc[flag] = val

    local function checkText()
        return loc[flag] and utf8.char(10003) or ""
    end

    local checkmark = Library:Create("TextButton", {
        Name                  = "Checkmark",
        Text                  = checkText(),
        Font                  = Library.options.font,
        TextSize              = Library.options.fontsize,
        Size                  = UDim2.new(0, 20, 0, 20),
        Position              = UDim2.new(1, -25, 0, 4),
        TextColor3            = Library.options.textcolor,
        BackgroundColor3      = Library.options.bgcolor,
        BorderColor3          = Library.options.bordercolor,
        TextStrokeTransparency= Library.options.textstroke,
        TextStrokeColor3      = Library.options.strokecolor,
    })

    local textLabel = Library:Create("TextLabel", {
        Name                  = label,
        Text                  = "\r" .. label,
        BackgroundTransparency= 1,
        TextColor3            = Library.options.textcolor,
        Position              = UDim2.new(0, 5, 0, 0),
        Size                  = UDim2.new(1, -5, 1, 0),
        TextXAlignment        = Enum.TextXAlignment.Left,
        Font                  = Library.options.font,
        TextSize              = Library.options.fontsize,
        TextStrokeTransparency= Library.options.textstroke,
        TextStrokeColor3      = Library.options.strokecolor,
        checkmark,
    })

    local row = Library:Create("Frame", {
        BackgroundTransparency= 1,
        Size                  = UDim2.new(1, 0, 0, 25),
        LayoutOrder           = self:GetOrder(),
        Parent                = self.container,
        textLabel,
    })

    local function setValue(newVal)
        loc[flag] = newVal
        cb(loc[flag])
        checkmark.Text = checkText()
    end

    checkmark.MouseButton1Click:Connect(function()
        setValue(not loc[flag])
    end)

    Library.callbacks[flag] = function() setValue(not loc[flag]) end
    table.insert(self.callbackFlags, flag)

    if loc[flag] == true then cb(loc[flag]) end

    self:Resize()

    return {
        Set = function(_, newVal) setValue(newVal) end,
    }
end

---------------------------------------------------------------------------
-- Button
---------------------------------------------------------------------------
function WindowMeta:Button(label, callback)
    local cb = callback or function() end

    local btn = Library:Create("TextButton", {
        Name                  = label,
        Text                  = label,
        BackgroundColor3      = Library.options.btncolor,
        BorderColor3          = Library.options.bordercolor,
        TextStrokeTransparency= Library.options.textstroke,
        TextStrokeColor3      = Library.options.strokecolor,
        TextColor3            = Library.options.textcolor,
        Position              = UDim2.new(0, 5, 0, 5),
        Size                  = UDim2.new(1, -10, 0, 20),
        Font                  = Library.options.font,
        TextSize              = Library.options.fontsize,
    })

    local row = Library:Create("Frame", {
        BackgroundTransparency= 1,
        Size                  = UDim2.new(1, 0, 0, 25),
        LayoutOrder           = self:GetOrder(),
        Parent                = self.container,
        btn,
    })
    row[label].MouseButton1Click:Connect(cb)

    self:Resize()

    return {
        Fire = function() cb() end,
    }
end

---------------------------------------------------------------------------
-- Box (TextBox)
---------------------------------------------------------------------------
function WindowMeta:Box(label, cfg, callback)
    cfg = cfg or {}
    local loc, flag = readCfg(self, cfg)
    local inputType = cfg.type or ""
    local default_  = cfg.default or ""
    local cb        = callback or function() end
    local minVal    = cfg.min or 0
    local maxVal    = cfg.max or 9000000000

    if inputType == "number" and tonumber(default_) then
        loc[flag] = default_
    else
        loc[flag] = ""
        default_  = ""
    end

    local box = Library:Create("TextBox", {
        Name                  = "Box",
        Text                  = tostring(default_),
        Font                  = Library.options.font,
        TextSize              = Library.options.fontsize,
        TextStrokeTransparency= Library.options.textstroke,
        TextStrokeColor3      = Library.options.strokecolor,
        Size                  = UDim2.new(0, 60, 0, 20),
        Position              = UDim2.new(1, -65, 0, 3),
        TextColor3            = Library.options.textcolor,
        BackgroundColor3      = Library.options.boxcolor,
        BorderColor3          = Library.options.bordercolor,
        PlaceholderColor3     = Library.options.placeholdercolor,
    })

    local textLabel = Library:Create("TextLabel", {
        Name                  = label,
        Text                  = "\r" .. label,
        BackgroundTransparency= 1,
        TextColor3            = Library.options.textcolor,
        TextStrokeTransparency= Library.options.textstroke,
        TextStrokeColor3      = Library.options.strokecolor,
        Position              = UDim2.new(0, 5, 0, 0),
        Size                  = UDim2.new(1, -5, 1, 0),
        TextXAlignment        = Enum.TextXAlignment.Left,
        Font                  = Library.options.font,
        TextSize              = Library.options.fontsize,
        box,
    })

    Library:Create("Frame", {
        BackgroundTransparency= 1,
        Size                  = UDim2.new(1, 0, 0, 25),
        LayoutOrder           = self:GetOrder(),
        Parent                = self.container,
        textLabel,
    })

    box.FocusLost:Connect(function(enterPressed)
        local prev = loc[flag]
        if inputType ~= "number" then
            loc[flag] = tostring(box.Text)
        else
            local n = tonumber(box.Text)
            if n then
                loc[flag] = math.clamp(n, minVal, maxVal)
            end
            box.Text = tostring(loc[flag])
        end
        cb(loc[flag], prev, enterPressed)
    end)

    -- chỉ cho nhập số: xoá mọi ký tự chữ và dấu +
    if inputType == "number" then
        box:GetPropertyChangedSignal("Text"):Connect(function()
            box.Text = string.gsub(box.Text, "[%a+]", "")
        end)
    end

    self:Resize()
    return box
end

---------------------------------------------------------------------------
-- Bind (keybind)
---------------------------------------------------------------------------
local BIND_BLACKLIST = { Return = true, Space = true, Tab = true, Unknown = true }
local BIND_ALIASES   = {
    RightControl = "RightCtrl", LeftControl = "LeftCtrl",
    LeftShift    = "LShift",    RightShift  = "RShift",
    MouseButton1 = "Mouse1",    MouseButton2 = "Mouse2",
}
local MOUSE_BUTTONS = { MouseButton1 = true, MouseButton2 = true }

-- Tên hiển thị của một input (phím hoặc chuột)
local function inputName(input)
    local name = input.UserInputType ~= Enum.UserInputType.Keyboard
        and input.UserInputType.Name
        or input.KeyCode.Name
    return BIND_ALIASES[name] or name
end

function WindowMeta:Bind(label, cfg, callback)
    cfg = cfg or {}
    local loc, flag = readCfg(self, cfg)
    local kbOnly = cfg.kbonly or false
    local cb     = callback or function() end
    local def    = cfg.default

    if kbOnly and not tostring(def):find("MouseButton") then
        loc[flag] = def
    end

    local displayName = not def and "None" or (BIND_ALIASES[def.Name] or def.Name or "None")

    local keybindBtn = Library:Create("TextButton", {
        Name                  = "Keybind",
        Text                  = displayName,
        TextStrokeTransparency= Library.options.textstroke,
        TextStrokeColor3      = Library.options.strokecolor,
        Font                  = Library.options.font,
        TextSize              = Library.options.fontsize,
        Size                  = UDim2.new(0, 60, 0, 20),
        Position              = UDim2.new(1, -65, 0, 5),
        TextColor3            = Library.options.textcolor,
        BackgroundColor3      = Library.options.bgcolor,
        BorderColor3          = Library.options.bordercolor,
        BorderSizePixel       = 1,
    })

    local textLabel = Library:Create("TextLabel", {
        Name                  = label,
        Text                  = "\r" .. label,
        BackgroundTransparency= 1,
        TextColor3            = Library.options.textcolor,
        Position              = UDim2.new(0, 5, 0, 0),
        Size                  = UDim2.new(1, -5, 1, 0),
        TextXAlignment        = Enum.TextXAlignment.Left,
        Font                  = Library.options.font,
        TextSize              = Library.options.fontsize,
        TextStrokeTransparency= Library.options.textstroke,
        TextStrokeColor3      = Library.options.strokecolor,
        BorderColor3          = Library.options.bordercolor,
        BorderSizePixel       = 1,
        keybindBtn,
    })

    Library:Create("Frame", {
        BackgroundTransparency= 1,
        Size                  = UDim2.new(1, 0, 0, 30),
        LayoutOrder           = self:GetOrder(),
        Parent                = self.container,
        textLabel,
    })

    -- hiển thị lại bind hiện tại (dùng khi bấm phím không hợp lệ)
    local function restoreDisplay()
        if not loc[flag] then return end
        local ok, name = pcall(inputName, loc[flag])
        if ok then
            keybindBtn.Text = name
        else
            local s = tostring(loc[flag])
            keybindBtn.Text = BIND_ALIASES[s] or s
        end
    end

    keybindBtn.MouseButton1Click:Connect(function()
        Library.binding = true
        keybindBtn.Text = "..."

        local input = UIS.InputBegan:Wait()

        local isInvalid = (input.UserInputType == Enum.UserInputType.Keyboard
                or (not MOUSE_BUTTONS[input.UserInputType.Name] or kbOnly))
            and (not input.KeyCode or BIND_BLACKLIST[input.KeyCode.Name])

        if isInvalid then
            restoreDisplay()
        else
            loc[flag]       = input
            keybindBtn.Text = inputName(input)
        end

        task.wait(0.1)
        Library.binding = false
    end)

    if loc[flag] then
        local name = tostring(loc[flag].Name)
        keybindBtn.Text = BIND_ALIASES[name] or name
    end

    Library.binds[flag] = { location = loc, callback = cb, owner = self }

    self:Resize()
end

---------------------------------------------------------------------------
-- Section
---------------------------------------------------------------------------
function WindowMeta:Section(text)
    local order  = self:GetOrder()
    local isTop  = order == 0
    local size   = isTop and UDim2.new(1, 0, 0, 21) or UDim2.new(1, 0, 0, 25)
    local pos    = isTop and UDim2.new(0, 0, 0, -1) or UDim2.new(0, 0, 0, 4)
    local lblSz  = isTop and UDim2.new(1, 0, 1, 0)  or UDim2.new(1, 0, 0, 20)

    local lbl = Library:Create("TextLabel", {
        Name                  = "section_lbl",
        Text                  = text,
        BackgroundTransparency= 0,
        BorderSizePixel       = 0,
        BackgroundColor3      = Library.options.sectncolor,
        TextColor3            = Library.options.textcolor,
        Position              = pos,
        Size                  = lblSz,
        Font                  = Library.options.font,
        TextSize              = Library.options.fontsize,
        TextStrokeTransparency= Library.options.textstroke,
        TextStrokeColor3      = Library.options.strokecolor,
    })

    Library:Create("Frame", {
        Name                  = "Section",
        BackgroundTransparency= 1,
        Size                  = size,
        BackgroundColor3      = Library.options.sectncolor,
        BorderSizePixel       = 0,
        LayoutOrder           = order,
        Parent                = self.container,
        lbl,
    })

    self:Resize()
end

---------------------------------------------------------------------------
-- Label
-- cfg (tuỳ chọn): color, align ("Left"/"Center"/"Right"), wrap (true = tự xuống dòng)
-- Trả về: obj:Set(text), obj:SetColor(color3), obj:Destroy()
---------------------------------------------------------------------------
function WindowMeta:Label(text, cfg)
    cfg = cfg or {}
    local wrap      = cfg.wrap or false
    local align     = Enum.TextXAlignment[cfg.align or "Left"] or Enum.TextXAlignment.Left
    local TextService = game:GetService("TextService")

    local lbl = Library:Create("TextLabel", {
        Name                  = "label_text",
        Text                  = tostring(text),
        BackgroundTransparency= 1,
        TextColor3            = cfg.color or Library.options.textcolor,
        Position              = UDim2.new(0, 5, 0, 0),
        Size                  = UDim2.new(1, -10, 1, 0),
        TextXAlignment        = align,
        TextWrapped           = wrap,
        Font                  = Library.options.font,
        TextSize              = Library.options.fontsize,
        TextStrokeTransparency= Library.options.textstroke,
        TextStrokeColor3      = Library.options.strokecolor,
    })

    local row = Library:Create("Frame", {
        Name                  = "Label",
        BackgroundTransparency= 1,
        Size                  = UDim2.new(1, 0, 0, 25),
        LayoutOrder           = self:GetOrder(),
        Parent                = self.container,
        lbl,
    })

    -- nếu wrap: tính lại chiều cao theo nội dung
    local function fit()
        if not wrap then return end
        local width = math.max(self.object.AbsoluteSize.X - 10, 50)
        local size  = TextService:GetTextSize(
            lbl.Text, lbl.TextSize, lbl.Font, Vector2.new(width, 10000)
        )
        row.Size = UDim2.new(1, 0, 0, math.max(25, size.Y + 6))
    end
    fit()

    local function resizeLater()
        task.defer(function()
            if not self.destroyed then self:Resize() end
        end)
    end

    self:Resize()

    local obj = {}

    function obj:Set(newText)
        if not row.Parent then return end
        lbl.Text = tostring(newText)
        fit()
        resizeLater()
    end

    function obj:SetColor(color)
        if row.Parent then lbl.TextColor3 = color end
    end

    function obj:Destroy()
        if row.Parent then
            row:Destroy()
            resizeLater()
        end
    end

    return obj
end

---------------------------------------------------------------------------
-- Slider
---------------------------------------------------------------------------
-- Làm tròn giá trị để hiển thị (precise = giữ số thập phân)
local function formatValue(v, precise)
    local rounded = tonumber(string.format("%.2f", v))
    return precise and rounded or math.floor(rounded)
end

function WindowMeta:Slider(label, cfg, callback)
    cfg = cfg or {}
    local loc, flag = readCfg(self, cfg)
    local val     = cfg.default or cfg.min
    local minVal  = cfg.min or 0
    local maxVal  = cfg.max or 1
    local precise = cfg.precise or false
    local cb      = callback or function() end
    loc[flag]     = val

    local valLabel = Library:Create("TextLabel", {
        Name                  = "ValueLabel",
        Text                  = val,
        BackgroundTransparency= 1,
        TextColor3            = Library.options.textcolor,
        Position              = UDim2.new(0, -10, 0, 0),
        Size                  = UDim2.new(0, 1, 1, 0),
        TextXAlignment        = Enum.TextXAlignment.Right,
        Font                  = Library.options.font,
        TextSize              = Library.options.fontsize,
        TextStrokeTransparency= Library.options.textstroke,
        TextStrokeColor3      = Library.options.strokecolor,
    })

    local button = Library:Create("TextButton", {
        Name                  = "Button",
        Size                  = UDim2.new(0, 5, 1, -2),
        Position              = UDim2.new(0, 0, 0, 1),
        AutoButtonColor       = false,
        Text                  = "",
        BackgroundColor3      = Color3.fromRGB(20, 20, 20),
        BorderSizePixel       = 0,
        ZIndex                = 2,
        TextStrokeTransparency= Library.options.textstroke,
        TextStrokeColor3      = Library.options.strokecolor,
    })

    local line = Library:Create("Frame", {
        Name                  = "Line",
        BackgroundTransparency= 0,
        Position              = UDim2.new(0, 0, 0.5, 0),
        Size                  = UDim2.new(1, 0, 0, 1),
        BackgroundColor3      = Library.options.textcolor,
        BorderSizePixel       = 0,
    })

    local sliderContainer = Library:Create("Frame", {
        Name                  = "Container",
        Size                  = UDim2.new(0, 60, 0, 20),
        Position              = UDim2.new(1, -65, 0, 3),
        BackgroundTransparency= 1,
        BorderSizePixel       = 0,
        valLabel, button, line,
    })

    local textLabel = Library:Create("TextLabel", {
        Name                  = label,
        Text                  = "\r" .. label,
        BackgroundTransparency= 1,
        TextColor3            = Library.options.textcolor,
        TextStrokeTransparency= Library.options.textstroke,
        TextStrokeColor3      = Library.options.strokecolor,
        Position              = UDim2.new(0, 5, 0, 2),
        Size                  = UDim2.new(1, -5, 1, 0),
        TextXAlignment        = Enum.TextXAlignment.Left,
        Font                  = Library.options.font,
        TextSize              = Library.options.fontsize,
        sliderContainer,
    })

    local row = Library:Create("Frame", {
        BackgroundTransparency= 1,
        Size                  = UDim2.new(1, 0, 0, 25),
        LayoutOrder           = self:GetOrder(),
        Parent                = self.container,
        textLabel,
    })

    local sliderEl   = row:FindFirstChild(label)
    local renderConn = nil
    local inputBegin, inputEnd, btnDown, globalUp

    -- đặt vị trí nút trượt + nhãn giá trị theo giá trị số
    local function applyVisual(v)
        local frac = 1 - (maxVal - v) / (maxVal - minVal)
        sliderEl.Container.Button.Position = UDim2.new(math.clamp(frac, 0, 0.99), 0, 0, 1)
        sliderEl.Container.ValueLabel.Text = formatValue(v, precise)
    end

    local function startDrag()
        if renderConn then renderConn:Disconnect() end
        renderConn = RS.RenderStepped:Connect(function()
            local mouseX  = UIS:GetMouseLocation().X
            local pct     = (mouseX - sliderEl.Container.AbsolutePosition.X) / sliderEl.Container.AbsoluteSize.X
            local clamped = math.clamp(pct, 0, 1)
            local raw     = minVal + (maxVal - minVal) * clamped
            local result  = precise and raw or math.floor(raw)

            sliderEl.Container.Button.Position = UDim2.new(math.clamp(tonumber(string.format("%.2f", clamped)), 0, 0.99), 0, 0, 1)
            sliderEl.Container.ValueLabel.Text = result
            loc[flag] = tonumber(result)
            cb(loc[flag])
        end)
    end

    local function stopDrag()
        if renderConn  then renderConn:Disconnect()  end
        if inputBegin  then inputBegin:Disconnect()  end
        if inputEnd    then inputEnd:Disconnect()    end
        if globalUp    then globalUp:Disconnect()    end
    end

    table.insert(self.cleanups, function()
        stopDrag()
        if btnDown then btnDown:Disconnect() end
    end)

    -- chỉ nối sự kiện chuột khi con trỏ đi vào slider
    sliderEl.Container.MouseEnter:Connect(function()
        inputBegin = sliderEl.Container.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then startDrag() end
        end)
        inputEnd = sliderEl.Container.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then stopDrag() end
        end)
        btnDown = sliderEl.Container.Button.MouseButton1Down:Connect(startDrag)
        globalUp = UIS.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 and btnDown and btnDown.Connected then
                stopDrag()
            end
        end)
    end)

    -- vị trí ban đầu
    if val ~= minVal then
        applyVisual(val)
    end

    self:Resize()

    return {
        Set = function(_, newVal)
            applyVisual(newVal)
            loc[flag] = formatValue(newVal, precise)
            cb(loc[flag])
        end,
    }
end

---------------------------------------------------------------------------
-- SearchBox
---------------------------------------------------------------------------
function WindowMeta:SearchBox(placeholder, cfg, callback)
    cfg = cfg or {}
    local list      = cfg.list or {}
    local loc, flag = readCfg(self, cfg)
    local cb        = callback or function() end
    local selecting = false

    local listLayout = Library:Create("UIListLayout", {
        Name      = "ListLayout",
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    local dropContainer = Library:Create("ScrollingFrame", {
        Name              = "Container",
        Position          = UDim2.new(0, 0, 1, 1),
        BackgroundColor3  = Library.options.btncolor,
        ScrollBarThickness= 0,
        BorderSizePixel   = 0,
        BorderColor3      = Library.options.bordercolor,
        Size              = UDim2.new(1, 0, 0, 0),
        ZIndex            = 2,
        listLayout,
    })

    local box = Library:Create("TextBox", {
        Name                  = "Box",
        Text                  = "",
        PlaceholderText       = placeholder,
        PlaceholderColor3     = Color3.fromRGB(60, 60, 60),
        Font                  = Library.options.font,
        TextSize              = Library.options.fontsize,
        Size                  = UDim2.new(1, -10, 0, 20),
        Position              = UDim2.new(0, 5, 0, 4),
        TextColor3            = Library.options.textcolor,
        BackgroundColor3      = Library.options.dropcolor,
        BorderColor3          = Library.options.bordercolor,
        TextStrokeTransparency= Library.options.textstroke,
        TextStrokeColor3      = Library.options.strokecolor,
        dropContainer,
    })

    local row = Library:Create("Frame", {
        BackgroundTransparency= 1,
        Size                  = UDim2.new(1, 0, 0, 25),
        LayoutOrder           = self:GetOrder(),
        Parent                = self.container,
        box,
    })

    local function clearResults(cont)
        cont.ScrollBarThickness = 0
        for _, child in pairs(cont:GetChildren()) do
            if not child:IsA("UIListLayout") then child:Destroy() end
        end
    end

    local function updateSearch(query)
        local cont = row.Box.Container
        clearResults(cont)

        if #query > 0 then
            local q = string.lower(query)
            for _, item in pairs(list) do
                if string.sub(string.lower(item), 1, #query) == q then
                    local itemBtn = Library:Create("TextButton", {
                        Text                  = item,
                        Font                  = Library.options.font,
                        TextSize              = Library.options.fontsize,
                        TextColor3            = Library.options.textcolor,
                        BorderColor3          = Library.options.bordercolor,
                        TextStrokeTransparency= Library.options.textstroke,
                        TextStrokeColor3      = Library.options.strokecolor,
                        Parent                = cont,
                        Size                  = UDim2.new(1, 0, 0, 20),
                        BackgroundColor3      = Library.options.btncolor,
                        ZIndex                = 2,
                    })
                    itemBtn.MouseButton1Click:Connect(function()
                        selecting = true
                        row.Box.Text = itemBtn.Text
                        task.wait()
                        selecting = false
                        loc[flag] = itemBtn.Text
                        cb(loc[flag])
                        clearResults(cont)
                        cont:TweenSize(UDim2.new(1, 0, 0, 0), "Out", "Quint", 0.3, true)
                    end)
                end
            end
        end

        -- tính chiều cao hiển thị (tối đa 100px, quá thì hiện thanh cuộn)
        local total   = 20 * #cont:GetChildren() - 20
        local clamped = math.clamp(total, 0, 100)
        if total > 100 then
            cont.ScrollBarThickness = 5
        end
        cont:TweenSize(UDim2.new(1, 0, 0, clamped), "Out", "Quint", 0.3, true)
        cont.CanvasSize = UDim2.new(1, 0, 0, total)
    end

    box:GetPropertyChangedSignal("Text"):Connect(function()
        if not selecting then
            updateSearch(row.Box.Text)
        end
    end)

    self:Resize()

    local function refresh(newList)
        list = newList
        updateSearch("")
    end

    return refresh, row.Box
end

---------------------------------------------------------------------------
-- Dropdown
---------------------------------------------------------------------------
local DROP_ITEM_H  = 20
local DROP_MAX_H   = 100

function WindowMeta:Dropdown(label, items, cfg, callback)
    cfg = cfg or {}
    local loc, flag = readCfg(self, cfg)
    local cb   = callback or function() end
    local list = cfg.list or items or {}
    loc[flag]  = list[1]

    local selLabel = Library:Create("TextLabel", {
        Name                  = "Selection",
        Size                  = UDim2.new(1, 0, 1, 0),
        Text                  = list[1],
        TextColor3            = Library.options.textcolor,
        BackgroundTransparency= 1,
        Font                  = Library.options.font,
        TextSize              = Library.options.fontsize,
        TextStrokeTransparency= Library.options.textstroke,
        TextStrokeColor3      = Library.options.strokecolor,
    })

    local dropArrow = Library:Create("TextButton", {
        Name                  = "drop",
        BackgroundTransparency= 1,
        Size                  = UDim2.new(0, 20, 1, 0),
        Position              = UDim2.new(1, -25, 0, 0),
        Text                  = "v",
        TextColor3            = Library.options.textcolor,
        Font                  = Library.options.font,
        TextSize              = Library.options.fontsize,
        TextStrokeTransparency= Library.options.textstroke,
        TextStrokeColor3      = Library.options.strokecolor,
    })

    local dropLabel = Library:Create("Frame", {
        Name                  = "dropdown_lbl",
        BackgroundTransparency= 0,
        BackgroundColor3      = Library.options.dropcolor,
        Position              = UDim2.new(0, 5, 0, 4),
        BorderColor3          = Library.options.bordercolor,
        Size                  = UDim2.new(1, -10, 0, 20),
        selLabel, dropArrow,
    })

    local row = Library:Create("Frame", {
        BackgroundTransparency= 1,
        Size                  = UDim2.new(1, 0, 0, 25),
        BackgroundColor3      = Color3.fromRGB(25, 25, 25),
        BorderSizePixel       = 0,
        LayoutOrder           = self:GetOrder(),
        Parent                = self.container,
        dropLabel,
    })

    local outsideConn = nil

    table.insert(self.cleanups, function()
        if outsideConn then outsideConn:Disconnect() end
    end)

    local function selection()
        return dropLabel:WaitForChild("Selection")
    end

    local function isMouseOver(frame)
        local mouse   = UIS:GetMouseLocation()
        local mPos    = Vector2.new(mouse.X, mouse.Y - 36)   -- bù thanh topbar
        local absPos  = frame.AbsolutePosition
        local absSize = frame.AbsoluteSize
        return mPos.X >= absPos.X and mPos.X <= absPos.X + absSize.X
           and mPos.Y >= absPos.Y and mPos.Y <= absPos.Y + absSize.Y
    end

    local function closeList(scroll)
        selection().TextColor3 = Library.options.textcolor
        selection().Text       = loc[flag]
        scroll:TweenSize(UDim2.new(1, 0, 0, 0), "In", "Quint", 0.3, true)
        task.wait(0.15)
        Debris:AddItem(scroll, 0)
        if outsideConn then outsideConn:Disconnect() end
    end

    dropArrow.MouseButton1Click:Connect(function()
        if outsideConn and outsideConn.Connected then return end

        selection().TextColor3 = Color3.fromRGB(60, 60, 60)
        selection().Text       = label

        local itemCount = 0
        for _ in pairs(list) do itemCount = itemCount + 1 end
        local totalH   = itemCount * DROP_ITEM_H
        local scrollH  = math.min(totalH, DROP_MAX_H)
        local scrollBar = totalH > DROP_MAX_H and 5 or 0

        local scroll = Library:Create("ScrollingFrame", {
            Name              = "DropContainer",
            Parent            = dropLabel,
            Size              = UDim2.new(1, 0, 0, 0),
            BackgroundColor3  = Library.options.bgcolor,
            BorderColor3      = Library.options.bordercolor,
            Position          = UDim2.new(0, 0, 1, 0),
            ScrollBarThickness= scrollBar,
            CanvasSize        = UDim2.new(0, 0, 0, totalH),
            ZIndex            = 5,
            ClipsDescendants  = true,
            TopImage          = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            BottomImage       = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            Library:Create("UIListLayout", { Name = "List", SortOrder = Enum.SortOrder.LayoutOrder }),
        })

        for idx, item in pairs(list) do
            local itemBtn = Library:Create("TextButton", {
                Size                  = UDim2.new(1, 0, 0, DROP_ITEM_H),
                BackgroundColor3      = Library.options.btncolor,
                BorderColor3          = Library.options.bordercolor,
                Text                  = item,
                Font                  = Library.options.font,
                TextSize              = Library.options.fontsize,
                LayoutOrder           = idx,
                Parent                = scroll,
                ZIndex                = 5,
                TextColor3            = Library.options.textcolor,
                TextStrokeTransparency= Library.options.textstroke,
                TextStrokeColor3      = Library.options.strokecolor,
            })
            itemBtn.MouseButton1Click:Connect(function()
                selection().TextColor3 = Library.options.textcolor
                selection().Text       = itemBtn.Text
                loc[flag] = tostring(itemBtn.Text)
                cb(loc[flag])
                Debris:AddItem(scroll, 0)
                if outsideConn then outsideConn:Disconnect() end
            end)
        end

        scroll:TweenSize(UDim2.new(1, 0, 0, scrollH), "Out", "Quint", 0.3, true)

        -- click ra ngoài thì đóng danh sách
        outsideConn = UIS.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 and not isMouseOver(scroll) then
                closeList(scroll)
            end
        end)
    end)

    self:Resize()

    return {
        Refresh = function(_, newItems)
            list      = newItems
            loc[flag] = newItems[1]
            if outsideConn then outsideConn:Disconnect() end
            selection().Text       = loc[flag]
            selection().TextColor3 = Library.options.textcolor
        end,
    }
end

---------------------------------------------------------------------------
-- Library.Destroy (huỷ toàn bộ thư viện)
---------------------------------------------------------------------------
function Library.Destroy(_)
    if Library.destroyed then return end
    Library.destroyed = true   -- cũng dừng vòng lặp rainbow

    for i = #Library.windows, 1, -1 do
        local w = Library.windows[i]
        if w then pcall(function() w:Destroy() end) end
    end

    for _, c in ipairs(Library.connections) do
        pcall(function() c:Disconnect() end)
    end

    if Library.gui then
        pcall(function() Library.gui:Destroy() end)
    end

    Library.gui         = nil
    Library.container   = nil
    Library.connections = {}
    Library.windows     = {}
    Library.queue       = {}
    Library.binds       = {}
    Library.callbacks   = {}
    Library.rainbowtable = {}
end

---------------------------------------------------------------------------
-- Library.CreateWindow (điểm vào chính)
---------------------------------------------------------------------------
function Library.CreateWindow(_, name, opts)
    if Library.destroyed then
        warn("[Library] Đã Destroy, hãy load lại thư viện để tạo window mới.")
        return
    end

    if not Library.container then
        local gui = Library:Create("ScreenGui", {
            Name   = "LibraryGui",
            Parent = game:GetService("CoreGui"),
            Library:Create("Frame", {
                Name                  = "Container",
                Size                  = UDim2.new(1, -30, 1, 0),
                Position              = UDim2.new(0, 20, 0, 20),
                BackgroundTransparency= 1,
                Active                = false,
            }),
        })
        Library.gui       = gui
        Library.container = gui:FindFirstChild("Container")
    end

    if opts then
        Library.options = setmetatable(opts, { __index = default })
    end

    local win = WindowMeta.window(name, Library.options)
    table.insert(Library.windows, win)

    Drag.new(win.object, function(newPos)
        -- cập nhật vị trí gốc để RightControl không đưa window về chỗ cũ
        for _, entry in pairs(Library.queue) do
            if entry.w == win.object then entry.p = newPos end
        end
    end)

    return win
end

return Library
