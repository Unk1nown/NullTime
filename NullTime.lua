-- NullTime V3 (uncontinued)

local function safeGetService(serviceName)
    local ok, service = pcall(game.GetService, game, serviceName)
    if not ok then return nil end

    if type(cloneref) == "function" then
        local success, ref = pcall(cloneref, service)
        if success and ref then
            return ref
        end
    end

    return service
end

local S = {
    Players = safeGetService("Players"),
    CoreGui = safeGetService("CoreGui"),
    UserInputService = safeGetService("UserInputService"),
    TweenService = safeGetService("TweenService"),
    ReplicatedStorage = safeGetService("ReplicatedStorage"),
    RunService = safeGetService("RunService"),
    Workspace = safeGetService("Workspace"),
    VirtualUser = safeGetService("VirtualUser"),
    ProximityPromptService = safeGetService("ProximityPromptService"),
    LogService = safeGetService("LogService"),
    TeleportService = safeGetService("TeleportService"),
    HttpService = safeGetService("HttpService"),
}

local LocalPlayer = S.Players.LocalPlayer

local function resolveGuiRoot()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if pg then return pg end

    local ok, playerGui = pcall(function()
        return LocalPlayer:WaitForChild("PlayerGui", 5)
    end)
    if ok and playerGui then return playerGui end

    if type(gethui) == "function" then
        local success, h = pcall(gethui)
        if success and typeof(h) == "Instance" then return h end
    end

    return S.CoreGui
end

local GuiRoot = resolveGuiRoot()

local C = {
    BASE = Color3.fromRGB(6, 6, 8),
    SURFACE = Color3.fromRGB(11, 11, 14),
    ELEVATED = Color3.fromRGB(18, 18, 22),
    BORDER = Color3.fromRGB(40, 40, 47),
    DIVIDER = Color3.fromRGB(27, 27, 32),
    TEXT_1 = Color3.fromRGB(245, 245, 248),
    TEXT_2 = Color3.fromRGB(165, 165, 175),
    TEXT_3 = Color3.fromRGB(95, 95, 105),
    ACCENT = Color3.fromRGB(225, 225, 232),
    ACCENT_D = Color3.fromRGB(80, 80, 90),
    SUCCESS = Color3.fromRGB(100, 220, 135),
    WARNING = Color3.fromRGB(225, 190, 90),
    ERROR = Color3.fromRGB(235, 85, 85)
}

local T_FAST = TweenInfo.new(0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local T_MED = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local T_SMOOTH = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function Tween(obj, info, props)
    if not obj or not obj.Parent then return end
    local ok, tween = pcall(function()
        return S.TweenService:Create(obj, info, props)
    end)
    if ok and tween then
        tween:Play()
        return tween
    end
end

local function Corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = obj
    return c
end

local function Stroke(obj, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or C.BORDER
    s.Thickness = thickness or 1
    s.Transparency = 0
    s.Parent = obj
    return s
end

local function AddPressAnimation(button)
    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = button

    button.MouseButton1Down:Connect(function()
        Tween(scale, T_FAST, {Scale = 0.975})
    end)

    button.MouseButton1Up:Connect(function()
        Tween(scale, T_FAST, {Scale = 1})
    end)

    button.MouseEnter:Connect(function()
        Tween(button, T_FAST, {BackgroundColor3 = C.ELEVATED})
    end)

    button.MouseLeave:Connect(function()
        Tween(button, T_FAST, {BackgroundColor3 = C.SURFACE})
        Tween(scale, T_FAST, {Scale = 1})
    end)

    return scale
end

local function mountGui(gui)
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    pcall(function()
        if type(syn) == "table" and type(syn.protect_gui) == "function" then
            syn.protect_gui(gui)
        end
    end)

    local targets = {}
    if GuiRoot then table.insert(targets, GuiRoot) end
    if type(gethui) == "function" then
        local ok, h = pcall(gethui)
        if ok and typeof(h) == "Instance" then table.insert(targets, h) end
    end
    if S.CoreGui then table.insert(targets, S.CoreGui) end

    for _, target in ipairs(targets) do
        local ok = pcall(function() gui.Parent = target end)
        if ok and gui.Parent == target then return true end
    end
    return false
end

local function AddDotWave(parent)
    task.spawn(function()
        pcall(function()
            local bg = Instance.new("Frame")
            bg.Name = "DotWaveBackground"
            bg.Size = UDim2.fromScale(1, 1)
            bg.Position = UDim2.fromScale(0, 0)
            bg.BackgroundTransparency = 1
            bg.BorderSizePixel = 0
            bg.ClipsDescendants = true
            bg.Active = false
            bg.Selectable = false
            bg.ZIndex = 1
            bg.Parent = parent

            local dots = {}
            local cols = 20
            local rows = 14

            for y = 1, rows do
                for x = 1, cols do
                    local dot = Instance.new("Frame")
                    dot.Name = "Dot"
                    dot.AnchorPoint = Vector2.new(0.5, 0.5)
                    dot.Size = UDim2.fromOffset(2, 2)
                    dot.Position = UDim2.fromScale((x - 0.5) / cols, (y - 0.5) / rows)
                    dot.BackgroundColor3 = C.TEXT_2
                    dot.BackgroundTransparency = 0.9
                    dot.BorderSizePixel = 0
                    dot.Active = false
                    dot.Selectable = false
                    dot.ZIndex = 1
                    dot.Parent = bg
                    Corner(dot, 50)

                    dots[#dots + 1] = {object = dot, x = x, y = y}
                end
            end

            local start = os.clock()
            while bg and bg.Parent do
                local t = os.clock() - start
                for _, d in ipairs(dots) do
                    local nx = d.x / cols
                    local ny = d.y / rows
                    local wave = math.sin(nx * 7 + t * 1.35) * 0.5 + math.sin(ny * 6 - t * 1.05) * 0.35 + math.sin((nx + ny) * 4 + t * 0.75) * 0.15
                    local lift = wave * 4
                    local size = 1.4 + ((wave + 1) * 0.7)
                    local transparency = 0.91 - ((wave + 1) * 0.075)

                    d.object.Position = UDim2.fromScale(nx, ny) + UDim2.fromOffset(0, lift)
                    d.object.Size = UDim2.fromOffset(size, size)
                    d.object.BackgroundTransparency = math.clamp(transparency, 0.68, 0.95)
                end
                task.wait(0.06)
            end
        end)
    end)
end

pcall(function()
    local names = {"NullTime-Auth", "NullTime-UI"}
    local roots = {GuiRoot, S.CoreGui}

    for _, root in ipairs(roots) do
        if root then
            for _, name in ipairs(names) do
                local old = root:FindFirstChild(name)
                if old then old:Destroy() end
            end
        end
    end
end)

local __DHubEnv = (type(getgenv) == "function" and getgenv()) or _G
__DHubEnv.__NullTimeActive = false

local KEYS_URL = "https://raw.githubusercontent.com/Unk1nown/FTI/refs/heads/main/keys.txt"

local function fetchRemoteDatabase()
    local res = nil
    local httpReq = (type(request) == "function" and request) or (type(http_request) == "function" and http_request) or (type(http) == "table" and type(http.request) == "function" and http.request)
    
    if httpReq then
        local ok, response = pcall(httpReq, {Url = KEYS_URL, Method = "GET"})
        if ok and response and response.Body then
            res = response.Body
        end
    end

    if not res then
        local ok, body = pcall(function() return game:HttpGet(KEYS_URL) end)
        if ok and type(body) == "string" then
            res = body
        end
    end

    if not res then return nil end

    local blocks = {}
    local currentBlock = {}

    for line in res:gmatch("[^\r\n]+") do
        local k, v = line:match("^%s*([^=]+)%s*=%s*(.-)%s*$")
        if k and v then
            currentBlock[k:lower()] = v
        end

        if currentBlock.user and currentBlock.key and currentBlock.days then
            table.insert(blocks, {
                user = currentBlock.user,
                key = currentBlock.key,
                days = tonumber(currentBlock.days) or -1
            })
            currentBlock = {}
        end
    end

    return blocks
end

local AuthSG = Instance.new("ScreenGui")
AuthSG.Name = "NullTime-Auth"

if not mountGui(AuthSG) then return end

local AuthFrame = Instance.new("Frame")
AuthFrame.Name = "AuthFrame"
AuthFrame.Parent = AuthSG
AuthFrame.Size = UDim2.new(0, 320, 0, 215)
AuthFrame.Position = UDim2.fromScale(0.5, 0.5)
AuthFrame.AnchorPoint = Vector2.new(0.5, 0.5)
AuthFrame.BackgroundColor3 = C.BASE
AuthFrame.ClipsDescendants = true
AuthFrame.ZIndex = 5

Corner(AuthFrame, 9)
Stroke(AuthFrame, C.BORDER, 1)
AddDotWave(AuthFrame)

local AuthScale = Instance.new("UIScale")
AuthScale.Scale = 0.86
AuthScale.Parent = AuthFrame

local AuthHeader = Instance.new("Frame")
AuthHeader.Parent = AuthFrame
AuthHeader.Size = UDim2.new(1, 0, 0, 42)
AuthHeader.BackgroundColor3 = C.SURFACE
AuthHeader.BorderSizePixel = 0
AuthHeader.ZIndex = 5

Corner(AuthHeader, 9)

local AuthHeaderFix = Instance.new("Frame")
AuthHeaderFix.Parent = AuthHeader
AuthHeaderFix.Size = UDim2.new(1, 0, 0, 9)
AuthHeaderFix.Position = UDim2.new(0, 0, 1, -9)
AuthHeaderFix.BackgroundColor3 = C.SURFACE
AuthHeaderFix.BorderSizePixel = 0
AuthHeaderFix.ZIndex = 5

local AuthLine = Instance.new("Frame")
AuthLine.Parent = AuthHeader
AuthLine.Size = UDim2.new(0, 42, 0, 3)
AuthLine.Position = UDim2.new(0, 14, 0, 0)
AuthLine.BackgroundColor3 = C.ACCENT
AuthLine.BorderSizePixel = 0
AuthLine.ZIndex = 7

Corner(AuthLine, 2)

local AuthTitle = Instance.new("TextLabel")
AuthTitle.Parent = AuthHeader
AuthTitle.Size = UDim2.new(1, -25, 1, 0)
AuthTitle.Position = UDim2.new(0, 14, 0, 0)
AuthTitle.BackgroundTransparency = 1
AuthTitle.Text = "NULLTIME  R V3"
AuthTitle.TextColor3 = C.TEXT_1
AuthTitle.Font = Enum.Font.GothamBold
AuthTitle.TextSize = 13
AuthTitle.TextXAlignment = Enum.TextXAlignment.Left
AuthTitle.ZIndex = 7

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Parent = AuthFrame
StatusLabel.Size = UDim2.new(1, -30, 0, 25)
StatusLabel.Position = UDim2.new(0, 15, 0, 50)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Verifying account..."
StatusLabel.TextColor3 = C.TEXT_2
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.ZIndex = 7

local InputBox = Instance.new("TextBox")
InputBox.Parent = AuthFrame
InputBox.Size = UDim2.new(1, -40, 0, 38)
InputBox.Position = UDim2.new(0, 20, 0, 82)
InputBox.BackgroundColor3 = C.SURFACE
InputBox.Text = LocalPlayer.Name
InputBox.PlaceholderText = "Roblox User..."
InputBox.TextColor3 = C.TEXT_1
InputBox.PlaceholderColor3 = C.TEXT_3
InputBox.Font = Enum.Font.GothamBold
InputBox.TextSize = 12
InputBox.ClearTextOnFocus = false
InputBox.TextEditable = false
InputBox.ZIndex = 7

Corner(InputBox, 6)
Stroke(InputBox, C.BORDER, 1)

local ActionBtn = Instance.new("TextButton")
ActionBtn.Parent = AuthFrame
ActionBtn.Size = UDim2.new(1, -40, 0, 38)
ActionBtn.Position = UDim2.new(0, 20, 0, 132)
ActionBtn.BackgroundColor3 = C.ACCENT
ActionBtn.Text = "Verify Roblox User"
ActionBtn.TextColor3 = Color3.fromRGB(10, 10, 12)
ActionBtn.Font = Enum.Font.GothamBold
ActionBtn.TextSize = 12
ActionBtn.AutoButtonColor = false
ActionBtn.ZIndex = 7

Corner(ActionBtn, 6)

local AuthButtonScale = Instance.new("UIScale")
AuthButtonScale.Parent = ActionBtn

ActionBtn.MouseButton1Down:Connect(function()
    Tween(AuthButtonScale, T_FAST, {Scale = 0.97})
end)

ActionBtn.MouseButton1Up:Connect(function()
    Tween(AuthButtonScale, T_FAST, {Scale = 1})
end)

ActionBtn.MouseEnter:Connect(function()
    Tween(ActionBtn, T_FAST, {BackgroundColor3 = Color3.fromRGB(245, 245, 248)})
end)

ActionBtn.MouseLeave:Connect(function()
    Tween(ActionBtn, T_FAST, {BackgroundColor3 = C.ACCENT})
    Tween(AuthButtonScale, T_FAST, {Scale = 1})
end)

Tween(AuthScale, T_SMOOTH, {Scale = 1})

local currentStep = 1
local validatedUser = ""
local dbCache = nil

local function promptError(msg)
    StatusLabel.Text = msg
    StatusLabel.TextColor3 = C.ERROR
    task.wait(1.5)
    if StatusLabel.Parent then
        StatusLabel.TextColor3 = C.TEXT_2
    end
end

function loadMainScript()
    local env = (type(getgenv) == "function" and getgenv()) or _G
    env.__NullTimeActive = false

    pcall(function()
        local old = GuiRoot and GuiRoot:FindFirstChild("NullTime-UI")
        if old then old:Destroy() end
        if S.CoreGui then
            old = S.CoreGui:FindFirstChild("NullTime-UI")
            if old then old:Destroy() end
        end
    end)

    -- CONFIG AUTO-SAVE SYSTEM
    local CONFIG_FILE = "NullTimeV3_Config.json"
    local savedConfig = {}
    
    local function loadConfig()
        if type(readfile) == "function" and type(isfile) == "function" and isfile(CONFIG_FILE) then
            local ok, data = pcall(readfile, CONFIG_FILE)
            if ok and data then
                local decoded = pcall(S.HttpService.JSONDecode, S.HttpService, data)
                if decoded then savedConfig = S.HttpService:JSONDecode(data) end
            end
        end
    end

    local function saveConfig()
        if type(writefile) == "function" then
            pcall(function()
                writefile(CONFIG_FILE, S.HttpService:JSONEncode(savedConfig))
            end)
        end
    end

    loadConfig()

    local BoulderRarityColors = {
        Mossite = Color3.fromRGB(50, 205, 50),
        Voltite = Color3.fromRGB(0, 191, 255),
        Gildrite = Color3.fromRGB(255, 215, 0),
        Rimeveil = Color3.fromRGB(138, 43, 226),
        Nocturnite = Color3.fromRGB(255, 0, 85)
    }

    local function MakeDraggable(frame, handle)
        local dragging = false
        local dragStart, startPosition

        handle.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
            dragging = true
            dragStart = input.Position
            startPosition = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end)

        S.UserInputService.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
            )
        end)
    end

    local MainSG = Instance.new("ScreenGui")
    MainSG.Name = "NullTime-UI"

    if not mountGui(MainSG) then
        env.__NullTimeActive = false
        return
    end

    env.__NullTimeActive = true
    local activeDropdown = nil

    local function CreateSection(parent, text)
        local lbl = Instance.new("TextLabel")
        lbl.Parent = parent
        lbl.Size = UDim2.new(1, 0, 0, 20)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBold
        lbl.TextColor3 = C.TEXT_2
        lbl.Text = text:upper()
        lbl.TextSize = 10
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 10
    end

    local function CreateButton(parent, label)
        local row = Instance.new("TextButton")
        row.Parent = parent
        row.Size = UDim2.new(1, 0, 0, 38)
        row.BackgroundColor3 = C.SURFACE
        row.Text = ""
        row.AutoButtonColor = false
        row.ZIndex = 10

        Corner(row, 6)
        Stroke(row, C.BORDER)

        local leftAccent = Instance.new("Frame")
        leftAccent.Parent = row
        leftAccent.Size = UDim2.new(0, 2, 0, 18)
        leftAccent.Position = UDim2.new(0, 0, 0.5, -9)
        leftAccent.BackgroundColor3 = C.ACCENT
        leftAccent.BorderSizePixel = 0
        leftAccent.ZIndex = 11

        Corner(leftAccent, 2)

        local labelTxt = Instance.new("TextLabel")
        labelTxt.Name = "BtnText"
        labelTxt.Parent = row
        labelTxt.Size = UDim2.new(1, -20, 1, 0)
        labelTxt.Position = UDim2.new(0, 14, 0, 0)
        labelTxt.BackgroundTransparency = 1
        labelTxt.Text = label
        labelTxt.TextColor3 = C.TEXT_1
        labelTxt.Font = Enum.Font.GothamBold
        labelTxt.TextSize = 11
        labelTxt.TextXAlignment = Enum.TextXAlignment.Left
        labelTxt.ZIndex = 11

        AddPressAnimation(row)
        return row
    end

    local function CreateToggle(parent, label, default, callback)
        local state = (savedConfig[label] ~= nil) and savedConfig[label] or (default == true)
        local row = Instance.new("TextButton")
        row.Parent = parent
        row.Size = UDim2.new(1, 0, 0, 38)
        row.BackgroundColor3 = C.SURFACE
        row.Text = ""
        row.AutoButtonColor = false
        row.ZIndex = 10

        Corner(row, 6)
        local rowStroke = Stroke(row, C.BORDER)

        local leftAccent = Instance.new("Frame")
        leftAccent.Parent = row
        leftAccent.Size = UDim2.new(0, 2, 0, 18)
        leftAccent.Position = UDim2.new(0, 0, 0.5, -9)
        leftAccent.BorderSizePixel = 0
        leftAccent.ZIndex = 11

        Corner(leftAccent, 2)

        local labelTxt = Instance.new("TextLabel")
        labelTxt.Name = "BtnText"
        labelTxt.Parent = row
        labelTxt.Size = UDim2.new(1, -68, 1, 0)
        labelTxt.Position = UDim2.new(0, 14, 0, 0)
        labelTxt.BackgroundTransparency = 1
        labelTxt.Text = label
        labelTxt.TextColor3 = C.TEXT_1
        labelTxt.Font = Enum.Font.GothamBold
        labelTxt.TextSize = 11
        labelTxt.TextXAlignment = Enum.TextXAlignment.Left
        labelTxt.ZIndex = 11

        local switch = Instance.new("Frame")
        switch.Parent = row
        switch.Size = UDim2.new(0, 38, 0, 20)
        switch.Position = UDim2.new(1, -50, 0.5, -10)
        switch.BackgroundColor3 = C.ELEVATED
        switch.BorderSizePixel = 0
        switch.Active = false
        switch.ZIndex = 12

        Corner(switch, 10)
        local switchStroke = Stroke(switch, C.BORDER, 1)

        local knob = Instance.new("Frame")
        knob.Parent = switch
        knob.Size = UDim2.new(0, 14, 0, 14)
        knob.Position = UDim2.new(0, 3, 0.5, -7)
        knob.BackgroundColor3 = C.TEXT_3
        knob.BorderSizePixel = 0
        knob.Active = false
        knob.ZIndex = 13

        Corner(knob, 50)
        local pressScale = Instance.new("UIScale")
        pressScale.Parent = row

        local function updateVisual(instant)
            local targetBg = state and C.ACCENT_D or C.ELEVATED
            local targetKnob = state and C.ACCENT or C.TEXT_3
            local targetStroke = state and C.ACCENT_D or C.BORDER
            local targetPos = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
            local targetAccent = state and C.ACCENT or C.DIVIDER

            if instant then
                switch.BackgroundColor3 = targetBg
                switchStroke.Color = targetStroke
                knob.BackgroundColor3 = targetKnob
                knob.Position = targetPos
                leftAccent.BackgroundColor3 = targetAccent
            else
                Tween(switch, T_MED, {BackgroundColor3 = targetBg})
                Tween(switchStroke, T_MED, {Color = targetStroke})
                Tween(knob, T_MED, {Position = targetPos, BackgroundColor3 = targetKnob})
                Tween(leftAccent, T_MED, {BackgroundColor3 = targetAccent})
            end
        end

        local function setState(value, fireCallback)
            state = value == true
            savedConfig[label] = state
            saveConfig()
            updateVisual(false)
            if fireCallback and callback then callback(state) end
        end

        row.MouseButton1Down:Connect(function() Tween(pressScale, T_FAST, {Scale = 0.975}) end)
        row.MouseButton1Up:Connect(function() Tween(pressScale, T_FAST, {Scale = 1}) end)
        row.MouseLeave:Connect(function() Tween(pressScale, T_FAST, {Scale = 1}) end)

        row.MouseButton1Click:Connect(function()
            setState(not state, true)
        end)

        updateVisual(true)

        if state and callback then
            task.defer(function() callback(true) end)
        end

        return row, setState, function() return state end
    end

    local function CreateInput(parent, label, defaultText, callback)
        local row = Instance.new("Frame")
        row.Parent = parent
        row.Size = UDim2.new(1, 0, 0, 42)
        row.BackgroundColor3 = C.SURFACE
        row.ZIndex = 10

        Corner(row, 6)
        Stroke(row, C.BORDER)

        local labelTxt = Instance.new("TextLabel")
        labelTxt.Parent = row
        labelTxt.Size = UDim2.new(0.5, 0, 1, 0)
        labelTxt.Position = UDim2.new(0, 14, 0, 0)
        labelTxt.BackgroundTransparency = 1
        labelTxt.Text = label
        labelTxt.TextColor3 = C.TEXT_2
        labelTxt.Font = Enum.Font.GothamMedium
        labelTxt.TextSize = 10
        labelTxt.TextXAlignment = Enum.TextXAlignment.Left
        labelTxt.ZIndex = 11

        local box = Instance.new("TextBox")
        box.Parent = row
        box.Size = UDim2.new(0.45, 0, 0, 28)
        box.Position = UDim2.new(0.52, 0, 0.5, -14)
        box.BackgroundColor3 = C.ELEVATED
        box.Text = tostring(savedConfig[label] or defaultText or "")
        box.TextColor3 = C.TEXT_1
        box.Font = Enum.Font.GothamBold
        box.TextSize = 11
        box.ClearTextOnFocus = false
        box.ZIndex = 12

        Corner(box, 4)
        Stroke(box, C.DIVIDER)

        box.FocusLost:Connect(function()
            savedConfig[label] = box.Text
            saveConfig()
            if callback then callback(box.Text) end
        end)

        return row, box
    end

    local function CreateDropdown(parent, label, options, isMulti, callback)
        local selected = savedConfig[label] or (isMulti and {} or "")

        local function displayText()
            if isMulti then
                local keys = {}
                if type(selected) == "table" then
                    for k, v in pairs(selected) do if v == true then keys[#keys + 1] = k end end
                end
                if #keys == 0 then return "None" end
                table.sort(keys)
                if #keys == 1 then return keys[1] end
                return keys[1] .. " +" .. tostring(#keys - 1)
            end
            return (selected == "" or not selected) and "None" or tostring(selected)
        end

        local row = Instance.new("Frame")
        row.Parent = parent
        row.Size = UDim2.new(1, 0, 0, 42)
        row.BackgroundColor3 = C.SURFACE
        row.ZIndex = 10

        Corner(row, 6)
        Stroke(row, C.BORDER)

        local labelTxt = Instance.new("TextLabel")
        labelTxt.Parent = row
        labelTxt.Size = UDim2.new(0.42, 0, 1, 0)
        labelTxt.Position = UDim2.new(0, 14, 0, 0)
        labelTxt.BackgroundTransparency = 1
        labelTxt.Text = label
        labelTxt.TextColor3 = C.TEXT_2
        labelTxt.Font = Enum.Font.GothamMedium
        labelTxt.TextSize = 10
        labelTxt.TextXAlignment = Enum.TextXAlignment.Left
        labelTxt.ZIndex = 11

        local dropBtn = Instance.new("TextButton")
        dropBtn.Parent = row
        dropBtn.Size = UDim2.new(0.53, 0, 0, 28)
        dropBtn.Position = UDim2.new(0.44, 0, 0.5, -14)
        dropBtn.BackgroundColor3 = C.ELEVATED
        dropBtn.Text = displayText()
        dropBtn.TextColor3 = C.TEXT_1
        dropBtn.Font = Enum.Font.GothamMedium
        dropBtn.TextSize = 10
        dropBtn.AutoButtonColor = false
        dropBtn.ZIndex = 12

        Corner(dropBtn, 4)
        Stroke(dropBtn, C.DIVIDER)

        local arrow = Instance.new("TextLabel")
        arrow.Parent = dropBtn
        arrow.Size = UDim2.new(0, 20, 1, 0)
        arrow.Position = UDim2.new(1, -22, 0, 0)
        arrow.BackgroundTransparency = 1
        arrow.Text = "v"
        arrow.TextColor3 = C.TEXT_3
        arrow.Font = Enum.Font.GothamBold
        arrow.TextSize = 12
        arrow.ZIndex = 13

        local panel = Instance.new("Frame")
        panel.Parent = MainSG
        panel.Size = UDim2.new(0, 200, 0, math.min(#options * 28 + 36, 180))
        panel.BackgroundColor3 = C.ELEVATED
        panel.Visible = false
        panel.ZIndex = 50

        Corner(panel, 6)
        Stroke(panel, C.BORDER)

        local panelScale = Instance.new("UIScale")
        panelScale.Scale = 0.96
        panelScale.Parent = panel

        local panelScroll = Instance.new("ScrollingFrame")
        panelScroll.Parent = panel
        panelScroll.Size = UDim2.new(1, -4, 1, -4)
        panelScroll.Position = UDim2.new(0, 2, 0, 2)
        panelScroll.BackgroundTransparency = 1
        panelScroll.BorderSizePixel = 0
        panelScroll.ScrollBarThickness = 2
        panelScroll.ZIndex = 51

        local panelLayout = Instance.new("UIListLayout")
        panelLayout.Parent = panelScroll
        panelLayout.Padding = UDim.new(0, 2)
        panelLayout.SortOrder = Enum.SortOrder.LayoutOrder

        panelLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            panelScroll.CanvasSize = UDim2.new(0, 0, 0, panelLayout.AbsoluteContentSize.Y + 6)
        end)

        local function closePanel()
            if not panel.Visible then return end
            Tween(panelScale, T_FAST, {Scale = 0.96})
            task.delay(0.12, function()
                if panel.Parent then
                    panel.Visible = false
                    if activeDropdown == panel then activeDropdown = nil end
                end
            end)
        end

        local function rebuildOptions(optList)
            for _, child in ipairs(panelScroll:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end

            local clearBtn = Instance.new("TextButton")
            clearBtn.Parent = panelScroll
            clearBtn.Size = UDim2.new(1, 0, 0, 26)
            clearBtn.BackgroundTransparency = 1
            clearBtn.Text = "None"
            clearBtn.TextColor3 = C.TEXT_3
            clearBtn.Font = Enum.Font.GothamMedium
            clearBtn.TextSize = 10
            clearBtn.ZIndex = 52
            clearBtn.AutoButtonColor = false

            clearBtn.MouseButton1Click:Connect(function()
                if isMulti then table.clear(selected) else selected = "" end
                savedConfig[label] = selected
                saveConfig()
                dropBtn.Text = displayText()
                closePanel()
                if callback then callback(isMulti and {} or "") end
            end)

            for _, opt in ipairs(optList) do
                local isOn = (isMulti and type(selected) == "table" and selected[opt] == true) or (not isMulti and selected == opt)
                local optBtn = Instance.new("TextButton")
                optBtn.Parent = panelScroll
                optBtn.Size = UDim2.new(1, 0, 0, 26)
                optBtn.BackgroundColor3 = isOn and C.ACCENT_D or C.ELEVATED
                optBtn.BorderSizePixel = 0
                optBtn.Text = opt
                optBtn.TextColor3 = isOn and C.TEXT_1 or C.TEXT_2
                optBtn.Font = Enum.Font.GothamMedium
                optBtn.TextSize = 10
                optBtn.ZIndex = 52
                optBtn.AutoButtonColor = false

                Corner(optBtn, 4)

                optBtn.MouseButton1Click:Connect(function()
                    if isMulti then
                        if type(selected) ~= "table" then selected = {} end
                        selected[opt] = not selected[opt] or nil
                        for _, child in ipairs(panelScroll:GetChildren()) do
                            if child:IsA("TextButton") and child ~= clearBtn then
                                local on = selected[child.Text] == true
                                child.BackgroundColor3 = on and C.ACCENT_D or C.ELEVATED
                                child.TextColor3 = on and C.TEXT_1 or C.TEXT_2
                            end
                        end
                    else
                        selected = opt
                        closePanel()
                    end

                    savedConfig[label] = selected
                    saveConfig()
                    dropBtn.Text = displayText()

                    local result
                    if isMulti then
                        result = {}
                        if type(selected) == "table" then
                            for k, v in pairs(selected) do if v == true then result[#result + 1] = k end end
                        end
                    else
                        result = selected
                    end

                    if callback then callback(result) end
                end)
            end
        end

        rebuildOptions(options)

        dropBtn.MouseButton1Click:Connect(function()
            if panel.Visible then
                closePanel()
                return
            end

            if activeDropdown and activeDropdown ~= panel then
                activeDropdown.Visible = false
            end

            local absPos = dropBtn.AbsolutePosition
            local absSize = dropBtn.AbsoluteSize

            panel.Position = UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 4)
            panelScale.Scale = 0.96
            panel.Visible = true
            activeDropdown = panel

            Tween(panelScale, T_MED, {Scale = 1})
        end)

        return row, function(newOptions)
            rebuildOptions(newOptions)
            panel.Size = UDim2.new(0, 200, 0, math.min(#newOptions * 28 + 36, 180))
        end, function()
            if isMulti then
                local result = {}
                if type(selected) == "table" then
                    for k, v in pairs(selected) do if v == true then result[#result + 1] = k end end
                end
                return result
            end
            return selected
        end
    end

    S.UserInputService.InputBegan:Connect(function(input)
        if not activeDropdown or not activeDropdown.Visible then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end

        local p = input.Position
        local pos = activeDropdown.AbsolutePosition
        local size = activeDropdown.AbsoluteSize

        if p.X >= pos.X and p.X <= pos.X + size.X and p.Y >= pos.Y and p.Y <= pos.Y + size.Y then return end

        activeDropdown.Visible = false
        activeDropdown = nil
    end)

    local Root = Instance.new("Frame")
    Root.Name = "Root"
    Root.Parent = MainSG
    Root.Size = UDim2.new(0.9, 0, 0.78, 0)
    Root.SizeConstraint = Enum.SizeConstraint.RelativeYY
    Root.Position = UDim2.fromScale(0.5, 0.5)
    Root.AnchorPoint = Vector2.new(0.5, 0.5)
    Root.BackgroundTransparency = 1
    Root.ZIndex = 2

    local UIConstraint = Instance.new("UISizeConstraint")
    UIConstraint.Parent = Root
    UIConstraint.MinSize = Vector2.new(300, 250)
    UIConstraint.MaxSize = Vector2.new(460, 360)

    local RootScale = Instance.new("UIScale")
    RootScale.Scale = 0.88
    RootScale.Parent = Root

    local Win = Instance.new("Frame")
    Win.Name = "Window"
    Win.Parent = Root
    Win.Size = UDim2.fromScale(1, 1)
    Win.BackgroundColor3 = C.BASE
    Win.ClipsDescendants = true
    Win.ZIndex = 2

    Corner(Win, 9)
    Stroke(Win, C.BORDER, 1)
    AddDotWave(Win)

    local Header = Instance.new("Frame")
    Header.Parent = Win
    Header.Size = UDim2.new(1, 0, 0, 42)
    Header.BackgroundColor3 = C.SURFACE
    Header.BorderSizePixel = 0
    Header.ZIndex = 5

    Corner(Header, 9)

    local HeaderFix = Instance.new("Frame")
    HeaderFix.Parent = Header
    HeaderFix.Size = UDim2.new(1, 0, 0, 9)
    HeaderFix.Position = UDim2.new(0, 0, 1, -9)
    HeaderFix.BackgroundColor3 = C.SURFACE
    HeaderFix.BorderSizePixel = 0
    HeaderFix.ZIndex = 5

    local AccentLine = Instance.new("Frame")
    AccentLine.Parent = Header
    AccentLine.Size = UDim2.new(0, 42, 0, 3)
    AccentLine.Position = UDim2.new(0, 14, 0, 0)
    AccentLine.BackgroundColor3 = C.ACCENT
    AccentLine.BorderSizePixel = 0
    AccentLine.ZIndex = 7

    Corner(AccentLine, 2)

    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.Parent = Header
    TitleLbl.Size = UDim2.new(1, -70, 1, 0)
    TitleLbl.Position = UDim2.new(0, 14, 0, 0)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Text = "NULLTIME  R V3"
    TitleLbl.TextColor3 = C.TEXT_1
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.TextSize = 13
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.ZIndex = 7

    MakeDraggable(Root, Header)

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Parent = MainSG
    ToggleBtn.Size = UDim2.new(0, 46, 0, 46)
    ToggleBtn.Position = UDim2.new(0, 12, 0.5, -23)
    ToggleBtn.BackgroundColor3 = C.SURFACE
    ToggleBtn.Text = "N"
    ToggleBtn.TextColor3 = C.TEXT_1
    ToggleBtn.TextSize = 17
    ToggleBtn.AutoButtonColor = false
    ToggleBtn.ZIndex = 30

    Corner(ToggleBtn, 23)
    Stroke(ToggleBtn, C.BORDER, 1)
    AddPressAnimation(ToggleBtn)
    MakeDraggable(ToggleBtn, ToggleBtn)

    local isUiOpen = true

    ToggleBtn.MouseButton1Click:Connect(function()
        isUiOpen = not isUiOpen
        if isUiOpen then
            Root.Visible = true
            RootScale.Scale = 0.88
            Tween(RootScale, T_SMOOTH, {Scale = 1})
        else
            Tween(RootScale, T_MED, {Scale = 0.88})
            task.delay(0.2, function()
                if not isUiOpen then Root.Visible = false end
            end)
        end
    end)

    local MinBtn = Instance.new("TextButton")
    MinBtn.Parent = Header
    MinBtn.Size = UDim2.new(0, 24, 0, 24)
    MinBtn.Position = UDim2.new(1, -31, 0.5, -12)
    MinBtn.BackgroundColor3 = C.ELEVATED
    MinBtn.Text = "-"
    MinBtn.TextColor3 = C.TEXT_2
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = 13
    MinBtn.AutoButtonColor = false
    MinBtn.ZIndex = 8

    Corner(MinBtn, 5)
    AddPressAnimation(MinBtn)

    MinBtn.MouseButton1Click:Connect(function()
        isUiOpen = false
        Tween(RootScale, T_MED, {Scale = 0.88})
        task.delay(0.2, function()
            if not isUiOpen then Root.Visible = false end
        end)
    end)

    local NavFrame = Instance.new("Frame")
    NavFrame.Parent = Win
    NavFrame.Size = UDim2.new(0, 90, 1, -42)
    NavFrame.Position = UDim2.new(0, 0, 0, 42)
    NavFrame.BackgroundColor3 = C.SURFACE
    NavFrame.BorderSizePixel = 0
    NavFrame.ZIndex = 5

    local NavLayout = Instance.new("UIListLayout")
    NavLayout.Parent = NavFrame
    NavLayout.Padding = UDim.new(0, 4)
    NavLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local NavPad = Instance.new("UIPadding")
    NavPad.Parent = NavFrame
    NavPad.PaddingTop = UDim.new(0, 8)
    NavPad.PaddingLeft = UDim.new(0, 6)
    NavPad.PaddingRight = UDim.new(0, 6)

    local PagesFrame = Instance.new("Frame")
    PagesFrame.Parent = Win
    PagesFrame.Size = UDim2.new(1, -90, 1, -42)
    PagesFrame.Position = UDim2.new(0, 90, 0, 42)
    PagesFrame.BackgroundTransparency = 1
    PagesFrame.ZIndex = 4
    PagesFrame.ClipsDescendants = true

    local modules = {}
    local currentModule = nil

    local function CreateModule(name)
        local TabBtn = Instance.new("TextButton")
        TabBtn.Parent = NavFrame
        TabBtn.Size = UDim2.new(1, 0, 0, 32)
        TabBtn.BackgroundColor3 = C.ELEVATED
        TabBtn.Text = name
        TabBtn.TextColor3 = C.TEXT_2
        TabBtn.Font = Enum.Font.GothamBold
        TabBtn.TextSize = 10
        TabBtn.AutoButtonColor = false
        TabBtn.ZIndex = 6

        Corner(TabBtn, 5)
        local tabScale = Instance.new("UIScale")
        tabScale.Parent = TabBtn

        TabBtn.MouseButton1Down:Connect(function() Tween(tabScale, T_FAST, {Scale = 0.96}) end)
        TabBtn.MouseButton1Up:Connect(function() Tween(tabScale, T_FAST, {Scale = 1}) end)

        local Page = Instance.new("ScrollingFrame")
        Page.Parent = PagesFrame
        Page.Size = UDim2.fromScale(1, 1)
        Page.Position = UDim2.new(0, 8, 0, 0)
        Page.BackgroundTransparency = 1
        Page.BorderSizePixel = 0
        Page.ScrollBarThickness = 2
        Page.ScrollBarImageColor3 = C.ACCENT_D
        Page.Visible = false
        Page.ZIndex = 5

        local Layout = Instance.new("UIListLayout")
        Layout.Parent = Page
        Layout.Padding = UDim.new(0, 8)
        Layout.SortOrder = Enum.SortOrder.LayoutOrder

        local Pad = Instance.new("UIPadding")
        Pad.Parent = Page
        Pad.PaddingTop = UDim.new(0, 10)
        Pad.PaddingBottom = UDim.new(0, 10)
        Pad.PaddingLeft = UDim.new(0, 10)
        Pad.PaddingRight = UDim.new(0, 10)

        Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 20)
        end)

        local data = {Page = Page, Btn = TabBtn, Scale = tabScale}
        modules[name] = data

        TabBtn.MouseButton1Click:Connect(function()
            if currentModule == name then return end
            currentModule = name

            for _, m in pairs(modules) do
                if m ~= data then
                    m.Page.Visible = false
                    Tween(m.Btn, T_MED, {BackgroundColor3 = C.ELEVATED, TextColor3 = C.TEXT_2})
                    Tween(m.Scale, T_FAST, {Scale = 1})
                end
            end

            Page.Visible = true
            Page.Position = UDim2.new(0, 12, 0, 0)
            Tween(Page, T_MED, {Position = UDim2.new(0, 0, 0, 0)})
            Tween(TabBtn, T_MED, {BackgroundColor3 = C.ACCENT, TextColor3 = Color3.fromRGB(10, 10, 12)})
        end)

        return Page
    end

    local DupePage = CreateModule("Dupe")
    local FarmPage = CreateModule("Farm")
    local MovementPage = CreateModule("Movement")
    local ESPPage = CreateModule("ESP")
    local BoulderPage = CreateModule("Boulder")

    currentModule = "Dupe"
    modules.Dupe.Page.Visible = true
    modules.Dupe.Page.Position = UDim2.new(0, 0, 0, 0)
    modules.Dupe.Btn.BackgroundColor3 = C.ACCENT
    modules.Dupe.Btn.TextColor3 = Color3.fromRGB(10, 10, 12)

    local function isCrystalTool(child)
        if not child:IsA("Tool") then return false end
        return child:GetAttribute("CrystalName") ~= nil or child:GetAttribute("Tier") ~= nil or child.Name:find("Crystal") ~= nil
    end

    local function isRuneTool(child)
        if not child:IsA("Tool") then return false end
        return child:GetAttribute("RuneId") ~= nil or child:GetAttribute("RuneName") ~= nil or child:GetAttribute("IsRune") == true or child.Name:find("Rune", 1, true) ~= nil
    end

    local crystalOptions, runeOptions = {}, {}
    local crystalSetOpts, runeSetOpts
    local getCrystalSelected, getRuneSelected

    local function scanInventory()
        table.clear(crystalOptions)
        table.clear(runeOptions)
        table.insert(runeOptions, "ALL RUNES")

        local cMap, rMap = {}, {}
        local function check(child)
            if isRuneTool(child) then
                if not rMap[child.Name] then
                    rMap[child.Name] = true
                    table.insert(runeOptions, child.Name)
                end
            elseif isCrystalTool(child) then
                if not cMap[child.Name] then
                    cMap[child.Name] = true
                    table.insert(crystalOptions, child.Name)
                end
            end
        end

        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        if bp then for _, child in ipairs(bp:GetChildren()) do check(child) end end
        local char = LocalPlayer.Character
        if char then for _, child in ipairs(char:GetChildren()) do check(child) end end

        table.sort(crystalOptions)
        table.sort(runeOptions)
    end

    scanInventory()

    local dropRemoteCache
    local function getDropRemote()
        if dropRemoteCache and dropRemoteCache.Parent then return dropRemoteCache end
        local remotes = S.ReplicatedStorage:FindFirstChild("Remotes")
        dropRemoteCache = remotes and remotes:FindFirstChild("CrystalDropRequest")
        return dropRemoteCache
    end

    local dropRepeatAmount = tonumber(savedConfig["Dupe Multiplier"]) or 5

    local function executeDropAll()
        local remote = getDropRemote()
        if not remote then return end

        local selCrystals = getCrystalSelected and getCrystalSelected() or {}
        local selRunes = getRuneSelected and getRuneSelected() or {}
        if #selCrystals == 0 and #selRunes == 0 then return end

        local dropAllRunes = false
        local targetSet = {}
        for _, name in ipairs(selCrystals) do targetSet[name] = true end
        for _, name in ipairs(selRunes) do
            if name == "ALL RUNES" then dropAllRunes = true else targetSet[name] = true end
        end

        local itemsToDrop = {}
        local containers = {LocalPlayer:FindFirstChildOfClass("Backpack"), LocalPlayer.Character}

        for _, container in ipairs(containers) do
            if container then
                for _, child in ipairs(container:GetChildren()) do
                    if child:IsA("Tool") then
                        if targetSet[child.Name] or (dropAllRunes and isRuneTool(child)) then
                            table.insert(itemsToDrop, child.Name)
                        end
                    end
                end
            end
        end

        for i = 1, dropRepeatAmount do
            for _, itemName in ipairs(itemsToDrop) do
                pcall(function() remote:FireServer(itemName) end)
            end
            if i % 5 == 0 then task.wait() end
        end
    end

    CreateSection(DupePage, "Drop Selection")

    local _, cSetOpts, cGetSel = CreateDropdown(DupePage, "Crystals to Drop", crystalOptions, true, function() end)
    crystalSetOpts = cSetOpts
    getCrystalSelected = cGetSel

    local _, rSetOpts, rGetSel = CreateDropdown(DupePage, "Runes to Drop", runeOptions, true, function() end)
    runeSetOpts = rSetOpts
    getRuneSelected = rGetSel

    local RefreshBtn = CreateButton(DupePage, "Refresh Inventory")
    RefreshBtn.MouseButton1Click:Connect(function()
        scanInventory()
        if crystalSetOpts then crystalSetOpts(crystalOptions) end
        if runeSetOpts then runeSetOpts(runeOptions) end
    end)

    CreateSection(DupePage, "Actions & Automation")

    local DropAllBtn = CreateButton(DupePage, "Drop All Selection")
    DropAllBtn.MouseButton1Click:Connect(function() task.spawn(executeDropAll) end)

    local ResetCharBtn = CreateButton(DupePage, "Reset Character")
    ResetCharBtn.MouseButton1Click:Connect(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum.Health = 0 end) end
    end)

    CreateInput(DupePage, "Dupe Multiplier", "5", function(txt)
        local n = tonumber(txt)
        if n and n > 0 then dropRepeatAmount = math.clamp(math.floor(n), 1, 100) else dropRepeatAmount = 5 end
    end)

    -- AUTO DUPE OPTIMIZADO (INSTANTÁNEO AL DETECTAR KICK / ERROR)
    local autoDupeActive = false

    CreateToggle(DupePage, "Auto Dupe (Instant Kick Trigger)", false, function(active)
        autoDupeActive = active
        local connection
        
        if active then
            local function triggerInstantDupe()
                if not autoDupeActive or not env.__NullTimeActive then return end
                
                -- Ejecución inmediata y simultánea (0ms de retraso para clonación perfecta antes del guardado del servidor)
                task.spawn(executeDropAll)
                pcall(function()
                    local char = LocalPlayer.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if hum then hum.Health = 0 end
                end)
            end

            connection = S.LogService.MessageOut:Connect(function(message, messageType)
                local msg = message:lower()
                if messageType == Enum.MessageType.MessageError or msg:find("kick") or msg:find("disconnected") or msg:find("timeout") or msg:find("lost connection") then
                    triggerInstantDupe()
                end
            end)
            
            env.__NullTimeAutoDupeConn = connection
        else
            if env.__NullTimeAutoDupeConn then
                env.__NullTimeAutoDupeConn:Disconnect()
                env.__NullTimeAutoDupeConn = nil
            end
        end
    end)

    local TimerDupeBtn = CreateButton(DupePage, "Start Timer & Dupe")
    local isCountingDown = false

    TimerDupeBtn.MouseButton1Click:Connect(function()
        if isCountingDown then return end
        isCountingDown = true

        task.spawn(function()
            local txtLabel = TimerDupeBtn:FindFirstChild("BtnText")
            local duration = 5
            local startTime = os.clock()
            local endTime = startTime + duration

            while true do
                local remaining = math.max(0, endTime - os.clock())
                if txtLabel then
                    local seconds = math.floor(remaining)
                    local millis = math.floor((remaining - seconds) * 100)
                    txtLabel.Text = string.format("NULLTIME  00:%02d.%02d", seconds, millis)
                end
                if remaining <= 0 then break end
                task.wait(0.02)
            end

            if txtLabel then txtLabel.Text = "Executing " .. tostring(dropRepeatAmount) .. "x..." end

            task.spawn(executeDropAll)

            task.wait(0.05)
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum.Health = 0 end) end

            task.wait(1)
            isCountingDown = false
            if txtLabel then txtLabel.Text = "Start Timer & Dupe" end
        end)
    end)

    CreateSection(FarmPage, "AFK Protection")

    CreateToggle(FarmPage, "Anti-AFK", false, function(active)
        local afkConn = env.__NullTimeAfkConnection
        if active then
            if afkConn then afkConn:Disconnect() end
            afkConn = LocalPlayer.Idled:Connect(function()
                if not env.__NullTimeActive then return end
                pcall(function()
                    S.VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                    task.wait(1)
                    S.VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                end)
            end)
            env.__NullTimeAfkConnection = afkConn
        else
            if afkConn then afkConn:Disconnect() end
            env.__NullTimeAfkConnection = nil
        end
    end)

    CreateSection(FarmPage, "Auto-Farm Options")

    CreateToggle(FarmPage, "Auto-Swing Tool", false, function(active)
        env.__NullTimeAutoSwing = active
        if active then
            task.spawn(function()
                while env.__NullTimeAutoSwing and env.__NullTimeActive do
                    local char = LocalPlayer.Character
                    local tool = char and char:FindFirstChildOfClass("Tool")
                    if tool then pcall(function() tool:Activate() end) end
                    task.wait(0.1)
                end
            end)
        end
    end)

    CreateToggle(FarmPage, "Auto-Prompt (Ultra-Fast)", false, function(active)
        env.__NullTimeAutoPrompt = active
        local promptConn = env.__NullTimeAutoPromptConn
        local heartbeatConn = env.__NullTimeAutoPromptHeartbeat

        if active then
            local function processPrompt(prompt)
                if not env.__NullTimeAutoPrompt or not prompt:IsA("ProximityPrompt") then return end
                prompt.HoldDuration = 0
                if typeof(fireproximityprompt) == "function" then
                    fireproximityprompt(prompt)
                else
                    pcall(function()
                        prompt:InputHoldBegin()
                        prompt:InputHoldEnd()
                    end)
                end
            end

            for _, prompt in ipairs(S.Workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then prompt.HoldDuration = 0 end
            end

            if promptConn then promptConn:Disconnect() end
            promptConn = S.ProximityPromptService.PromptShown:Connect(processPrompt)
            env.__NullTimeAutoPromptConn = promptConn

            if heartbeatConn then heartbeatConn:Disconnect() end
            heartbeatConn = S.RunService.Heartbeat:Connect(function()
                if not env.__NullTimeAutoPrompt or not env.__NullTimeActive then return end
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")

                if root then
                    for _, prompt in ipairs(S.Workspace:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                            prompt.HoldDuration = 0
                            local parent = prompt.Parent
                            if parent then
                                local pos = parent:IsA("BasePart") and parent.Position or (parent:IsA("Model") and parent:GetPivot().Position)
                                if pos and (root.Position - pos).Magnitude <= (prompt.MaxActivationDistance or 10) then
                                    processPrompt(prompt)
                                end
                            end
                        end
                    end
                end
            end)
            env.__NullTimeAutoPromptHeartbeat = heartbeatConn
        else
            if promptConn then promptConn:Disconnect() end
            if heartbeatConn then heartbeatConn:Disconnect() end
            env.__NullTimeAutoPromptConn = nil
            env.__NullTimeAutoPromptHeartbeat = nil
        end
    end)

    CreateSection(MovementPage, "Player Speed & Jump")

    CreateToggle(MovementPage, "Speed Boost (60)", false, function(active)
        env.__NullTimeSpeed = active
    end)

    S.RunService.Stepped:Connect(function()
        if not env.__NullTimeSpeed then return end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 60 end
    end)

    CreateToggle(MovementPage, "High Jump (100)", false, function(active)
        env.__NullTimeJump = active
    end)

    S.RunService.Stepped:Connect(function()
        if not env.__NullTimeJump then return end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = 100 end
    end)

    CreateSection(MovementPage, "Interactions & Collision")

    CreateToggle(MovementPage, "Insta Pick Up", false, function(active)
        env.__NullTimeInstaPick = active
        local promptConn = env.__NullTimePromptConnection

        if active then
            for _, prompt in ipairs(S.Workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then prompt.HoldDuration = 0 end
            end
            if promptConn then promptConn:Disconnect() end
            promptConn = S.ProximityPromptService.PromptShown:Connect(function(prompt)
                if env.__NullTimeInstaPick then prompt.HoldDuration = 0 end
            end)
            env.__NullTimePromptConnection = promptConn
        else
            if promptConn then promptConn:Disconnect() end
            env.__NullTimePromptConnection = nil
        end
    end)

    CreateToggle(MovementPage, "Noclip", false, function(active)
        env.__NullTimeNoclip = active
    end)

    S.RunService.Stepped:Connect(function()
        if not env.__NullTimeNoclip then return end
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end)

    CreateSection(ESPPage, "Player Visuals")

    local espEnabled = false
    local espConnections = {}

    local function applyEsp(player)
        if player == LocalPlayer then return end
        local function highlightChar(char)
            if not espEnabled or not char then return end
            if not char:FindFirstChild("RedESP") then
                local hl = Instance.new("Highlight")
                hl.Name = "RedESP"
                hl.FillColor = Color3.fromRGB(225, 225, 230)
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.FillTransparency = 0.72
                hl.OutlineTransparency = 0.15
                hl.Parent = char
            end
        end

        if player.Character then highlightChar(player.Character) end
        if not espConnections[player] then
            espConnections[player] = player.CharacterAdded:Connect(highlightChar)
        end
    end

    local function removeEsp()
        for _, p in ipairs(S.Players:GetPlayers()) do
            if p.Character then
                local esp = p.Character:FindFirstChild("RedESP")
                if esp then esp:Destroy() end
            end
        end
    end

    CreateToggle(ESPPage, "Player ESP", false, function(active)
        espEnabled = active
        if espEnabled then
            for _, p in ipairs(S.Players:GetPlayers()) do applyEsp(p) end
        else
            removeEsp()
        end
    end)

    S.Players.PlayerAdded:Connect(function(player)
        if espEnabled then applyEsp(player) end
    end)

    local ExactBoulders = {"Mossite", "Voltite", "Gildrite", "Rimeveil", "Nocturnite"}
    local boulderList = {}
    local setBoulderOpts, getSelectedBoulders

    local function cleanExactBoulderName(rawName)
        for _, bType in ipairs(ExactBoulders) do
            if rawName:lower():find(bType:lower()) then return bType end
        end
        return nil
    end

    local function scanExactBoulders()
        table.clear(boulderList)
        for _, obj in ipairs(S.Workspace:GetDescendants()) do
            local exactName = cleanExactBoulderName(obj.Name)
            if exactName then
                table.insert(boulderList, {Instance = obj, Type = exactName})
            end
        end
    end

    scanExactBoulders()

    CreateSection(BoulderPage, "Boulder Selection")

    local _, bSetOpts, bGetSel = CreateDropdown(BoulderPage, "Target Boulders", ExactBoulders, true, function() end)
    setBoulderOpts = bSetOpts
    getSelectedBoulders = bGetSel

    local ScanBouldersBtn = CreateButton(BoulderPage, "Exact Map Scan")
    ScanBouldersBtn.MouseButton1Click:Connect(function()
        scanExactBoulders()
        if setBoulderOpts then setBoulderOpts(ExactBoulders) end
    end)

    CreateSection(BoulderPage, "Boulder ESP & Auto-Farm")

    local function applyBoulderESP()
        for _, item in ipairs(boulderList) do
            local obj = item.Instance
            local bType = item.Type
            if obj and obj.Parent then
                if not obj:FindFirstChild("BoulderESP") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "BoulderESP"
                    hl.FillColor = BoulderRarityColors[bType] or Color3.fromRGB(255, 255, 255)
                    hl.OutlineColor = Color3.fromRGB(0, 0, 0)
                    hl.FillTransparency = 0.45
                    hl.OutlineTransparency = 0.1
                    hl.Parent = obj
                end
            end
        end
    end

    local function removeBoulderESP()
        for _, item in ipairs(boulderList) do
            local obj = item.Instance
            if obj then
                local esp = obj:FindFirstChild("BoulderESP")
                if esp then esp:Destroy() end
            end
        end
    end

    CreateToggle(BoulderPage, "Boulder ESP", false, function(active)
        if active then
            scanExactBoulders()
            applyBoulderESP()
        else
            removeBoulderESP()
        end
    end)

    CreateToggle(BoulderPage, "Auto-Farm Boulders", false, function(active)
        env.__NullTimeBoulderFarm = active
        if active then
            task.spawn(function()
                while env.__NullTimeBoulderFarm and env.__NullTimeActive do
                    scanExactBoulders()
                    local targets = getSelectedBoulders and getSelectedBoulders() or {}
                    local targetSet = {}
                    for _, t in ipairs(targets) do targetSet[t] = true end

                    local closest = nil
                    local minDistance = math.huge
                    local char = LocalPlayer.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")

                    if root then
                        for _, item in ipairs(boulderList) do
                            if targetSet[item.Type] and item.Instance and item.Instance.Parent then
                                local pos = item.Instance:IsA("Model") and item.Instance:GetPivot().Position or (item.Instance:IsA("BasePart") and item.Instance.Position)
                                if pos then
                                    local dist = (root.Position - pos).Magnitude
                                    if dist < minDistance then
                                        minDistance = dist
                                        closest = item
                                    end
                                end
                            end
                        end

                        if closest and closest.Instance then
                            local pos = closest.Instance:IsA("Model") and closest.Instance:GetPivot().Position or (closest.Instance:IsA("BasePart") and closest.Instance.Position)
                            if pos then
                                root.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0))
                                local tool = char:FindFirstChildOfClass("Tool")
                                if tool then pcall(function() tool:Activate() end) end
                            end
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end)

    Tween(RootScale, T_SMOOTH, {Scale = 1})
end

local function executeLoginFlow()
    local robloxUser = LocalPlayer.Name:lower()

    if currentStep == 1 then
        StatusLabel.Text = "Searching database..."
        StatusLabel.TextColor3 = C.WARNING
        ActionBtn.Active = false

        task.spawn(function()
            dbCache = fetchRemoteDatabase()

            if not dbCache then
                promptError("Unable to get database.")
                ActionBtn.Active = true
                return
            end

            local userFound = false
            for _, record in ipairs(dbCache) do
                if record.user:lower() == robloxUser then
                    userFound = true
                    break
                end
            end

            if userFound then
                validatedUser = robloxUser
                currentStep = 2
                StatusLabel.Text = "User found. Enter your key."
                StatusLabel.TextColor3 = C.SUCCESS

                InputBox.Text = ""
                InputBox.TextEditable = true
                InputBox.PlaceholderText = "Key..."
                ActionBtn.Text = "Login"
                ActionBtn.Active = true

                Tween(InputBox, T_MED, {BackgroundColor3 = C.ELEVATED})
            else
                promptError("You are not authorized.")
                ActionBtn.Active = true
            end
        end)

    elseif currentStep == 2 then
        local keyInput = InputBox.Text:match("^%s*(.-)%s*$")
        if keyInput == "" then return end

        StatusLabel.Text = "Validating key..."
        StatusLabel.TextColor3 = C.WARNING
        ActionBtn.Active = false

        task.spawn(function()
            local keyValid = false
            if dbCache then
                for _, record in ipairs(dbCache) do
                    if record.user:lower() == validatedUser and record.key == keyInput then
                        if record.days == 0 or record.days > 0 then
                            keyValid = true
                            break
                        end
                    end
                end
            end

            if keyValid then
                StatusLabel.Text = "Access granted."
                StatusLabel.TextColor3 = C.SUCCESS
                task.wait(0.35)

                Tween(AuthScale, T_SMOOTH, {Scale = 0.86})
                task.wait(0.28)

                if AuthSG then AuthSG:Destroy() end
                loadMainScript()
            else
                promptError("Invalid or expired key.")
                ActionBtn.Active = true
            end
        end)
    end
end

ActionBtn.MouseButton1Click:Connect(executeLoginFlow)
InputBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then executeLoginFlow() end
end)

--all this made for Time and NullBreach

