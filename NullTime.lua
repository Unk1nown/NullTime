-- NullTime V3 (Ultra-Fast Auto Dupe, Local Config & All Options)

local function safeGetService(serviceName)
    local ok, service = pcall(game.GetService, game, serviceName)
    if not ok then return nil end

    if type(cloneref) == "function" then
        local success, ref = pcall(cloneref, service)
        if success and ref then return ref end
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
}

local LocalPlayer = S.Players.LocalPlayer

local function resolveGuiRoot()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if pg then return pg end

    local ok, playerGui = pcall(function()
        return LocalPlayer:WaitForChild("PlayerGui", 2)
    end)
    if ok and playerGui then return playerGui end

    if type(gethui) == "function" then
        local success, h = pcall(gethui)
        if success and typeof(h) == "Instance" then return h end
    end

    return S.CoreGui
end

local GuiRoot = resolveGuiRoot()

-- Sistema de guardado local de configuraciones
local CONFIG_FILE = "NullTime_Config_V3.json"
local function saveLocalConfig(data)
    if type(writefile) == "function" and HttpService then
        pcall(function()
            writefile(CONFIG_FILE, game:GetService("HttpService"):JSONEncode(data))
        end)
    end
end

local function loadLocalConfig()
    if type(readfile) == "function" and type(isfile) == "function" and isfile(CONFIG_FILE) then
        local ok, res = pcall(function()
            return game:GetService("HttpService"):JSONDecode(readfile(CONFIG_FILE))
        end)
        if ok and type(res) == "table" then
            return res
        end
    end
    return {}
end

local savedConfig = loadLocalConfig()

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

local T_FAST = TweenInfo.new(0.06, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local T_MED = TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function Tween(obj, info, props)
    if not obj or not obj.Parent then return end
    pcall(function() S.TweenService:Create(obj, info, props):Play() end)
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
    s.Parent = obj
    return s
end

local function AddPressAnimation(button)
    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = button

    button.MouseButton1Down:Connect(function() Tween(scale, T_FAST, {Scale = 0.98}) end)
    button.MouseButton1Up:Connect(function() Tween(scale, T_FAST, {Scale = 1}) end)
    button.MouseEnter:Connect(function() Tween(button, T_FAST, {BackgroundColor3 = C.ELEVATED}) end)
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

    local targets = {GuiRoot, S.CoreGui}
    if type(gethui) == "function" then
        local ok, h = pcall(gethui)
        if ok and typeof(h) == "Instance" then table.insert(targets, h) end
    end

    for _, target in ipairs(targets) do
        local ok = pcall(function() gui.Parent = target end)
        if ok and gui.Parent == target then return true end
    end
    return false
end

pcall(function()
    local names = {"NullTime-Auth", "NullTime-UI"}
    for _, root in ipairs({GuiRoot, S.CoreGui}) do
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

local AuthSG = Instance.new("ScreenGui")
AuthSG.Name = "NullTime-Auth"
if not mountGui(AuthSG) then return end

local AuthFrame = Instance.new("Frame")
AuthFrame.Parent = AuthSG
AuthFrame.Size = UDim2.new(0, 320, 0, 215)
AuthFrame.Position = UDim2.fromScale(0.5, 0.5)
AuthFrame.AnchorPoint = Vector2.new(0.5, 0.5)
AuthFrame.BackgroundColor3 = C.BASE
AuthFrame.ClipsDescendants = true
AuthFrame.ZIndex = 5

Corner(AuthFrame, 9)
Stroke(AuthFrame, C.BORDER, 1)

local AuthHeader = Instance.new("Frame")
AuthHeader.Parent = AuthFrame
AuthHeader.Size = UDim2.new(1, 0, 0, 42)
AuthHeader.BackgroundColor3 = C.SURFACE
AuthHeader.BorderSizePixel = 0
AuthHeader.ZIndex = 5
Corner(AuthHeader, 9)

local AuthTitle = Instance.new("TextLabel")
AuthTitle.Parent = AuthHeader
AuthTitle.Size = UDim2.new(1, -25, 1, 0)
AuthTitle.Position = UDim2.new(0, 14, 0, 0)
AuthTitle.BackgroundTransparency = 1
AuthTitle.Text = "NULLTIME R V3"
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
InputBox.TextColor3 = C.TEXT_1
InputBox.Font = Enum.Font.GothamBold
InputBox.TextSize = 12
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
AddPressAnimation(ActionBtn)

local currentStep = 1

function loadMainScript()
    local env = (type(getgenv) == "function" and getgenv()) or _G
    env.__NullTimeActive = true

    local MainSG = Instance.new("ScreenGui")
    MainSG.Name = "NullTime-UI"
    if not mountGui(MainSG) then return end

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
        local state = default == true
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
        switch.ZIndex = 12
        Corner(switch, 10)
        local switchStroke = Stroke(switch, C.BORDER, 1)

        local knob = Instance.new("Frame")
        knob.Parent = switch
        knob.Size = UDim2.new(0, 14, 0, 14)
        knob.Position = UDim2.new(0, 3, 0.5, -7)
        knob.BackgroundColor3 = C.TEXT_3
        knob.BorderSizePixel = 0
        knob.ZIndex = 13
        Corner(knob, 50)

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
            updateVisual(false)
            if fireCallback and callback then callback(state) end
        end

        row.MouseButton1Click:Connect(function() setState(not state, true) end)
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
        box.Text = tostring(defaultText or "")
        box.TextColor3 = C.TEXT_1
        box.Font = Enum.Font.GothamBold
        box.TextSize = 11
        box.ClearTextOnFocus = false
        box.ZIndex = 12
        Corner(box, 4)
        Stroke(box, C.DIVIDER)

        box.FocusLost:Connect(function()
            if callback then callback(box.Text) end
        end)

        return row, box
    end

    local function CreateDropdown(parent, label, options, isMulti, initialSelected, callback)
        local selected = initialSelected or (isMulti and {} or "")

        local function displayText()
            if isMulti then
                local keys = {}
                for k in pairs(selected) do keys[#keys + 1] = k end
                if #keys == 0 then return "None" end
                table.sort(keys)
                if #keys == 1 then return keys[1] end
                return keys[1] .. " +" .. tostring(#keys - 1)
            end
            return selected == "" and "None" or selected
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

        local panel = Instance.new("Frame")
        panel.Parent = MainSG
        panel.Size = UDim2.new(0, 200, 0, math.min(#options * 28 + 36, 180))
        panel.BackgroundColor3 = C.ELEVATED
        panel.Visible = false
        panel.ZIndex = 50
        Corner(panel, 6)
        Stroke(panel, C.BORDER)

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

        panelLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            panelScroll.CanvasSize = UDim2.new(0, 0, 0, panelLayout.AbsoluteContentSize.Y + 6)
        end)

        local function closePanel()
            if not panel.Visible then return end
            panel.Visible = false
            if activeDropdown == panel then activeDropdown = nil end
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
                dropBtn.Text = displayText()
                closePanel()
                if callback then callback(isMulti and {} or "") end
            end)

            for _, opt in ipairs(optList) do
                local isOn = (isMulti and selected[opt] == true) or (not isMulti and selected == opt)
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
                Corner(optBtn, 4)

                optBtn.MouseButton1Click:Connect(function()
                    if isMulti then
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

                    dropBtn.Text = displayText()
                    if callback then callback(selected) end
                end)
            end
        end

        rebuildOptions(options)

        dropBtn.MouseButton1Click:Connect(function()
            if panel.Visible then closePanel() return end
            if activeDropdown and activeDropdown ~= panel then activeDropdown.Visible = false end

            local absPos = dropBtn.AbsolutePosition
            local absSize = dropBtn.AbsoluteSize
            panel.Position = UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 4)
            panel.Visible = true
            activeDropdown = panel
        end)

        return row, function(newOpts) rebuildOptions(newOpts) end, function() return selected end
    end

    local Root = Instance.new("Frame")
    Root.Parent = MainSG
    Root.Size = UDim2.new(0.9, 0, 0.78, 0)
    Root.SizeConstraint = Enum.SizeConstraint.RelativeYY
    Root.Position = UDim2.fromScale(0.5, 0.5)
    Root.AnchorPoint = Vector2.new(0.5, 0.5)
    Root.BackgroundTransparency = 1

    local Win = Instance.new("Frame")
    Win.Parent = Root
    Win.Size = UDim2.fromScale(1, 1)
    Win.BackgroundColor3 = C.BASE
    Win.ClipsDescendants = true
    Corner(Win, 9)
    Stroke(Win, C.BORDER, 1)

    local Header = Instance.new("Frame")
    Header.Parent = Win
    Header.Size = UDim2.new(1, 0, 0, 42)
    Header.BackgroundColor3 = C.SURFACE
    Header.BorderSizePixel = 0
    Corner(Header, 9)

    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.Parent = Header
    TitleLbl.Size = UDim2.new(1, -70, 1, 0)
    TitleLbl.Position = UDim2.new(0, 14, 0, 0)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Text = "NULLTIME R V3"
    TitleLbl.TextColor3 = C.TEXT_1
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.TextSize = 13
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

    local NavFrame = Instance.new("Frame")
    NavFrame.Parent = Win
    NavFrame.Size = UDim2.new(0, 90, 1, -42)
    NavFrame.Position = UDim2.new(0, 0, 0, 42)
    NavFrame.BackgroundColor3 = C.SURFACE
    NavFrame.BorderSizePixel = 0

    local NavLayout = Instance.new("UIListLayout")
    NavLayout.Parent = NavFrame
    NavLayout.Padding = UDim.new(0, 4)
    NavLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local PagesFrame = Instance.new("Frame")
    PagesFrame.Parent = Win
    PagesFrame.Size = UDim2.new(1, -90, 1, -42)
    PagesFrame.Position = UDim2.new(0, 90, 0, 42)
    PagesFrame.BackgroundTransparency = 1

    local modules = {}
    local currentModule = nil

    local function CreateModule(name)
        local TabBtn = Instance.new("TextButton")
        TabBtn.Parent = NavFrame
        TabBtn.Size = UDim2.new(0, 80, 0, 32)
        TabBtn.BackgroundColor3 = C.ELEVATED
        TabBtn.Text = name
        TabBtn.TextColor3 = C.TEXT_2
        TabBtn.Font = Enum.Font.GothamBold
        TabBtn.TextSize = 10
        TabBtn.AutoButtonColor = false
        Corner(TabBtn, 5)

        local Page = Instance.new("ScrollingFrame")
        Page.Parent = PagesFrame
        Page.Size = UDim2.fromScale(1, 1)
        Page.BackgroundTransparency = 1
        Page.BorderSizePixel = 0
        Page.ScrollBarThickness = 2
        Page.Visible = false

        local Layout = Instance.new("UIListLayout")
        Layout.Parent = Page
        Layout.Padding = UDim.new(0, 8)

        Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 20)
        end)

        modules[name] = {Page = Page, Btn = TabBtn}

        TabBtn.MouseButton1Click:Connect(function()
            if currentModule == name then return end
            currentModule = name
            for _, m in pairs(modules) do
                m.Page.Visible = (m.Page == Page)
                m.Btn.BackgroundColor3 = (m.Page == Page) and C.ACCENT or C.ELEVATED
                m.Btn.TextColor3 = (m.Page == Page) and Color3.fromRGB(10, 10, 12) or C.TEXT_2
            end
        end)

        return Page
    end

    local DupePage = CreateModule("Dupe")
    local FarmPage = CreateModule("Farm")
    local MovementPage = CreateModule("Movement")

    currentModule = "Dupe"
    modules.Dupe.Page.Visible = true
    modules.Dupe.Btn.BackgroundColor3 = C.ACCENT
    modules.Dupe.Btn.TextColor3 = Color3.fromRGB(10, 10, 12)

    local function isCrystalTool(child)
        return child:IsA("Tool") and (child:GetAttribute("CrystalName") or child.Name:find("Crystal"))
    end

    local function isRuneTool(child)
        return child:IsA("Tool") and (child:GetAttribute("RuneId") or child.Name:find("Rune"))
    end

    local crystalOptions, runeOptions = {}, {}
    local function scanInventory()
        table.clear(crystalOptions)
        table.clear(runeOptions)
        table.insert(runeOptions, "ALL RUNES")
        local cMap, rMap = {}, {}
        local function check(child)
            if isRuneTool(child) and not rMap[child.Name] then
                rMap[child.Name] = true
                table.insert(runeOptions, child.Name)
            elseif isCrystalTool(child) and not cMap[child.Name] then
                cMap[child.Name] = true
                table.insert(crystalOptions, child.Name)
            end
        end
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        if bp then for _, c in ipairs(bp:GetChildren()) do check(c) end end
        local char = LocalPlayer.Character
        if char then for _, c in ipairs(char:GetChildren()) do check(c) end end
    end
    scanInventory()

    local function getDropRemote()
        local remotes = S.ReplicatedStorage:FindFirstChild("Remotes")
        return remotes and remotes:FindFirstChild("CrystalDropRequest")
    end

    local dropRepeatAmount = savedConfig.dropMultiplier or 5

    local function executeDropAll()
        local remote = getDropRemote()
        if not remote then return end
        local selCrystals = savedConfig.crystals or {}
        local selRunes = savedConfig.runes or {}

        local dropAllRunes = false
        local targetSet = {}
        for k in pairs(selCrystals) do targetSet[k] = true end
        for k in pairs(selRunes) do
            if k == "ALL RUNES" then dropAllRunes = true else targetSet[k] = true end
        end

        local itemsToDrop = {}
        for _, container in ipairs({LocalPlayer:FindFirstChildOfClass("Backpack"), LocalPlayer.Character}) do
            if container then
                for _, child in ipairs(container:GetChildren()) do
                    if child:IsA("Tool") and (targetSet[child.Name] or (dropAllRunes and isRuneTool(child))) then
                        table.insert(itemsToDrop, child.Name)
                    end
                end
            end
        end

        for i = 1, dropRepeatAmount do
            for _, itemName in ipairs(itemsToDrop) do
                pcall(function() remote:FireServer(itemName) end)
            end
        end
    end

    -- PESTAÑA DUPE
    CreateSection(DupePage, "Drop Selection")
    CreateDropdown(DupePage, "Crystals to Drop", crystalOptions, true, savedConfig.crystals, function(res)
        savedConfig.crystals = res
        saveLocalConfig(savedConfig)
    end)
    CreateDropdown(DupePage, "Runes to Drop", runeOptions, true, savedConfig.runes, function(res)
        savedConfig.runes = res
        saveLocalConfig(savedConfig)
    end)

    CreateSection(DupePage, "Actions & Automation")
    CreateButton(DupePage, "Drop All Selection").MouseButton1Click:Connect(executeDropAll)

    CreateInput(DupePage, "Dupe Multiplier", tostring(dropRepeatAmount), function(txt)
        local n = tonumber(txt)
        if n and n > 0 then 
            dropRepeatAmount = math.clamp(math.floor(n), 1, 100) 
            savedConfig.dropMultiplier = dropRepeatAmount
            saveLocalConfig(savedConfig)
        end
    end)

    CreateToggle(DupePage, "Auto Dupe (Kick Trigger)", savedConfig.autoDupe == true, function(active)
        savedConfig.autoDupe = active
        saveLocalConfig(savedConfig)
        if active then
            env.__NullTimeAutoDupeConn = S.LogService.MessageOut:Connect(function(msg, mType)
                if mType == Enum.MessageType.MessageError or msg:lower().find("kick") or msg:lower().find("disconnected") then
                    task.spawn(function()
                        local char = LocalPlayer.Character
                        local hum = char and char:FindFirstChildOfClass("Humanoid")
                        if hum then hum.Health = 0 end
                    end)
                    task.spawn(executeDropAll)
                end
            end)
        elseif env.__NullTimeAutoDupeConn then
            env.__NullTimeAutoDupeConn:Disconnect()
        end
    end)

    -- PESTAÑA FARM
    CreateSection(FarmPage, "AFK Protection")
    CreateToggle(FarmPage, "Anti-AFK", savedConfig.antiAfk == true, function(active)
        savedConfig.antiAfk = active
        saveLocalConfig(savedConfig)
        if active then
            env.__NullTimeAfkConnection = LocalPlayer.Idled:Connect(function()
                S.VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(0.1)
                S.VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        elseif env.__NullTimeAfkConnection then
            env.__NullTimeAfkConnection:Disconnect()
        end
    end)

    -- PESTAÑA MOVEMENT (Restaurada)
    CreateSection(MovementPage, "Character Enhancements")
    CreateToggle(MovementPage, "Speed Boost", savedConfig.speedBoost == true, function(active)
        savedConfig.speedBoost = active
        saveLocalConfig(savedConfig)
    end)
    CreateToggle(MovementPage, "Infinite Jump", savedConfig.infJump == true, function(active)
        savedConfig.infJump = active
        saveLocalConfig(savedConfig)
        if active then
            env.__NullTimeJumpConn = S.UserInputService.JumpRequest:Connect(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        elseif env.__NullTimeJumpConn then
            env.__NullTimeJumpConn:Disconnect()
        end
    end)
end

ActionBtn.MouseButton1Click:Connect(function()
    if currentStep == 1 then
        currentStep = 2
        StatusLabel.Text = "Access granted."
        StatusLabel.TextColor3 = C.SUCCESS
        task.wait(0.1)
        if AuthSG then AuthSG:Destroy() end
        loadMainScript()
    end
end)

