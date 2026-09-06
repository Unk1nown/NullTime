local function safeGetService(serviceName)
    local service = game:GetService(serviceName)
    return (type(cloneref) == "function" and cloneref(service)) or service
end

local S = {
    Players           = safeGetService("Players"),
    CoreGui           = safeGetService("CoreGui"),
    UserInputService  = safeGetService("UserInputService"),
    TweenService      = safeGetService("TweenService"),
    ReplicatedStorage = safeGetService("ReplicatedStorage"),
    RunService        = safeGetService("RunService"),
    Workspace         = safeGetService("Workspace"),
    VirtualUser       = safeGetService("VirtualUser"),
    ProximityPromptService = safeGetService("ProximityPromptService"),
}
local LocalPlayer = S.Players.LocalPlayer

local function resolveGuiRoot()
    if type(gethui) == "function" then
        local ok, h = pcall(gethui)
        if ok and typeof(h) == "Instance" then return h end
    end
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if pg then return pg end
    return LocalPlayer:WaitForChild("PlayerGui", 5) or S.CoreGui
end

local GuiRoot = resolveGuiRoot()

local C = {
    BASE       = Color3.fromRGB(20, 10, 10),
    SURFACE    = Color3.fromRGB(35, 15, 15),
    ELEVATED   = Color3.fromRGB(50, 20, 20),
    BORDER     = Color3.fromRGB(150, 30, 30),
    DIVIDER    = Color3.fromRGB(60, 20, 20),
    TEXT_1     = Color3.fromRGB(255, 235, 235),
    TEXT_2     = Color3.fromRGB(230, 150, 150),
    TEXT_3     = Color3.fromRGB(160, 80, 80),
    ACCENT     = Color3.fromRGB(220, 35, 35),
    ACCENT_D   = Color3.fromRGB(150, 20, 20),
}

local function Corner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = UDim.new(0, r or 6)
end

local function Stroke(p, col, th)
    local s = Instance.new("UIStroke", p)
    s.Color = col or C.BORDER; s.Thickness = th or 1
    return s
end

pcall(function()
    local oldAuth = GuiRoot:FindFirstChild("NullTime-Auth") or S.CoreGui:FindFirstChild("NullTime-Auth")
    if oldAuth then oldAuth:Destroy() end
    local oldUI = GuiRoot:FindFirstChild("NullTime-UI") or S.CoreGui:FindFirstChild("NullTime-UI")
    if oldUI then oldUI:Destroy() end
end)

local KEYS_URL = "https://raw.githubusercontent.com/Unk1nown/FTI/refs/heads/main/keys.txt"

local function fetchRemoteDatabase()
    local ok, res = pcall(function()
        return game:HttpGet(KEYS_URL)
    end)
    if not ok or type(res) ~= "string" then return nil end
    
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
                key  = currentBlock.key,
                days = tonumber(currentBlock.days) or -1
            })
            currentBlock = {}
        end
    end
    return blocks
end

local AuthSG = Instance.new("ScreenGui")
AuthSG.Name = "NullTime-Auth"
AuthSG.ResetOnSpawn = false
if type(syn) == "table" and type(syn.protect_gui) == "function" then
    pcall(syn.protect_gui, AuthSG)
    AuthSG.Parent = S.CoreGui
else
    AuthSG.Parent = GuiRoot
end

local AuthFrame = Instance.new("Frame", AuthSG)
AuthFrame.Size = UDim2.new(0, 300, 0, 200)
AuthFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
AuthFrame.BackgroundColor3 = C.BASE
Corner(AuthFrame, 8); Stroke(AuthFrame, C.BORDER, 1)

local AuthTitle = Instance.new("TextLabel", AuthFrame)
AuthTitle.Size = UDim2.new(1, 0, 0, 35)
AuthTitle.BackgroundTransparency = 1
AuthTitle.Text = "NULLTIME AUTH"
AuthTitle.TextColor3 = C.ACCENT
AuthTitle.Font = Enum.Font.GothamBold
AuthTitle.TextSize = 14

local StatusLabel = Instance.new("TextLabel", AuthFrame)
StatusLabel.Size = UDim2.new(1, -20, 0, 20)
StatusLabel.Position = UDim2.new(0, 10, 0, 35)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Verificando cuenta..."
StatusLabel.TextColor3 = C.TEXT_2
StatusLabel.Font = Enum.Font.GothamMedium
StatusLabel.TextSize = 11

local InputBox = Instance.new("TextBox", AuthFrame)
InputBox.Size = UDim2.new(1, -40, 0, 36)
InputBox.Position = UDim2.new(0, 20, 0, 65)
InputBox.BackgroundColor3 = C.SURFACE
InputBox.Text = LocalPlayer.Name
InputBox.PlaceholderText = "Roblox User..."
InputBox.TextColor3 = C.TEXT_1
InputBox.PlaceholderColor3 = C.TEXT_3
InputBox.Font = Enum.Font.GothamBold
InputBox.TextSize = 12
InputBox.ClearTextOnFocus = false
InputBox.TextEditable = false
Corner(InputBox, 6); Stroke(InputBox, C.BORDER)

local ActionBtn = Instance.new("TextButton", AuthFrame)
ActionBtn.Size = UDim2.new(1, -40, 0, 36)
ActionBtn.Position = UDim2.new(0, 20, 0, 115)
ActionBtn.BackgroundColor3 = C.ACCENT
ActionBtn.Text = "Verificar Roblox User"
ActionBtn.TextColor3 = C.TEXT_1
ActionBtn.Font = Enum.Font.GothamBold
ActionBtn.TextSize = 13
Corner(ActionBtn, 6)

local currentStep = 1
local validatedUser = ""
local dbCache = nil

local function promptError(msg)
    StatusLabel.Text = msg
    StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    task.wait(1.5)
    StatusLabel.TextColor3 = C.TEXT_2
end

local function executeLoginFlow()
    local robloxUser = LocalPlayer.Name:lower()

    if currentStep == 1 then
        StatusLabel.Text = "Validando Roblox User..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
        ActionBtn.Active = false

        task.spawn(function()
            dbCache = fetchRemoteDatabase()
            if not dbCache then
                promptError("Error al obtener la base de datos!")
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
                StatusLabel.Text = "Usuario verificado! Ingresa la Key"
                StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                InputBox.Text = ""
                InputBox.TextEditable = true
                InputBox.PlaceholderText = "Key..."
                ActionBtn.Text = "Login"
                ActionBtn.Active = true
            else
                promptError("Esta cuenta de Roblox no está autorizada!")
                ActionBtn.Active = true
            end
        end)

    elseif currentStep == 2 then
        local keyInput = InputBox.Text:match("^%s*(.-)%s*$")
        if keyInput == "" then return end

        StatusLabel.Text = "Validando Key..."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
        ActionBtn.Active = false

        task.spawn(function()
            local keyValid = false
            for _, record in ipairs(dbCache) do
                if record.user:lower() == validatedUser and record.key == keyInput then
                    if record.days == 0 or record.days > 0 then
                        keyValid = true
                        break
                    end
                end
            end

            if keyValid then
                StatusLabel.Text = "Acceso Concedido!"
                StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                task.wait(0.5)
                AuthSG:Destroy()
                loadMainScript()
            else
                promptError("Key inválida o expirada!")
                ActionBtn.Active = true
            end
        end)
    end
end

ActionBtn.MouseButton1Click:Connect(executeLoginFlow)
InputBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then executeLoginFlow() end
end)

function loadMainScript()
    local __DHubEnv = (type(getgenv) == "function" and getgenv()) or _G
    if __DHubEnv.__NullTimeActive then return end
    __DHubEnv.__NullTimeActive = true

    local BoulderRarityColors = {
        Mossite    = Color3.fromRGB(50, 205, 50),
        Voltite    = Color3.fromRGB(0, 191, 255),
        Gildrite   = Color3.fromRGB(255, 215, 0),
        Rimeveil   = Color3.fromRGB(138, 43, 226),
        Nocturnite = Color3.fromRGB(255, 0, 85)
    }

    local function MakeDraggable(frame, handle)
        local drag, ds, sp
        handle.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                drag = true; ds = inp.Position; sp = frame.Position
                inp.Changed:Connect(function()
                    if inp.UserInputState == Enum.UserInputState.End then drag = false end
                end)
            end
        end)
        S.UserInputService.InputChanged:Connect(function(inp)
            if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement
                or inp.UserInputType == Enum.UserInputType.Touch) then
                local d = inp.Position - ds
                frame.Position = UDim2.new(
                    sp.X.Scale, sp.X.Offset + d.X,
                    sp.Y.Scale, sp.Y.Offset + d.Y)
            end
        end)
    end

    local MainSG = Instance.new("ScreenGui")
    MainSG.Name = "NullTime-UI"
    MainSG.ResetOnSpawn = false

    if type(syn) == "table" and type(syn.protect_gui) == "function" then
        pcall(syn.protect_gui, MainSG)
        MainSG.Parent = S.CoreGui
    else
        MainSG.Parent = GuiRoot
    end

    local activeDropdown = nil

    local function CreateSection(parent, text)
        local Lbl = Instance.new("TextLabel", parent)
        Lbl.Size = UDim2.new(1, 0, 0, 20)
        Lbl.BackgroundTransparency = 1
        Lbl.Font = Enum.Font.GothamBold
        Lbl.TextColor3 = C.TEXT_2
        Lbl.Text = text:upper()
        Lbl.TextSize = 11
        Lbl.TextXAlignment = Enum.TextXAlignment.Left
    end

    local function CreateButton(parent, label)
        local Row = Instance.new("TextButton", parent)
        Row.Size = UDim2.new(1, 0, 0, 38)
        Row.BackgroundColor3 = C.SURFACE
        Row.Text = ""; Row.AutoButtonColor = false
        Corner(Row, 6); Stroke(Row, C.BORDER)
        local LeftAccent = Instance.new("Frame", Row)
        LeftAccent.Size = UDim2.new(0, 3, 0, 18)
        LeftAccent.Position = UDim2.new(0, 0, 0.5, -9)
        LeftAccent.BackgroundColor3 = C.ACCENT; Corner(LeftAccent, 1)
        local LabelTxt = Instance.new("TextLabel", Row)
        LabelTxt.Name = "BtnText"
        LabelTxt.Size = UDim2.new(1, -20, 1, 0)
        LabelTxt.Position = UDim2.new(0, 14, 0, 0)
        LabelTxt.BackgroundTransparency = 1
        LabelTxt.Text = label
        LabelTxt.TextColor3 = C.TEXT_1
        LabelTxt.Font = Enum.Font.GothamBold
        LabelTxt.TextSize = 12
        LabelTxt.TextXAlignment = Enum.TextXAlignment.Left
        return Row
    end

    local function CreateInput(parent, label, defaultText, callback)
        local Row = Instance.new("Frame", parent)
        Row.Size = UDim2.new(1, 0, 0, 42)
        Row.BackgroundColor3 = C.SURFACE
        Corner(Row, 6); Stroke(Row, C.BORDER)

        local LabelTxt = Instance.new("TextLabel", Row)
        LabelTxt.Size = UDim2.new(0.5, 0, 1, 0)
        LabelTxt.Position = UDim2.new(0, 14, 0, 0)
        LabelTxt.BackgroundTransparency = 1
        LabelTxt.Text = label
        LabelTxt.TextColor3 = C.TEXT_2
        LabelTxt.Font = Enum.Font.GothamMedium
        LabelTxt.TextSize = 11
        LabelTxt.TextXAlignment = Enum.TextXAlignment.Left

        local Box = Instance.new("TextBox", Row)
        Box.Size = UDim2.new(0.45, 0, 0, 28)
        Box.Position = UDim2.new(0.52, 0, 0.5, -14)
        Box.BackgroundColor3 = C.ELEVATED
        Corner(Box, 4); Stroke(Box, C.DIVIDER)
        Box.Text = tostring(defaultText or "")
        Box.TextColor3 = C.TEXT_1
        Box.Font = Enum.Font.GothamBold
        Box.TextSize = 12
        Box.ClearTextOnFocus = false

        Box.FocusLost:Connect(function()
            if callback then callback(Box.Text) end
        end)

        return Row, Box
    end

    local function CreateDropdown(parent, label, options, isMulti, callback)
        local selected = isMulti and {} or ""
        local function displayText()
            if isMulti then
                local keys = {}
                for k in pairs(selected) do keys[#keys+1] = k end
                if #keys == 0 then return "None" end
                table.sort(keys)
                if #keys == 1 then return keys[1] end
                return keys[1] .. " +" .. tostring(#keys - 1)
            else
                return selected == "" and "None" or selected
            end
        end
        local Row = Instance.new("Frame", parent)
        Row.Size = UDim2.new(1, 0, 0, 42)
        Row.BackgroundColor3 = C.SURFACE
        Corner(Row, 6); Stroke(Row, C.BORDER)
        local LabelTxt = Instance.new("TextLabel", Row)
        LabelTxt.Size = UDim2.new(0.42, 0, 1, 0)
        LabelTxt.Position = UDim2.new(0, 14, 0, 0)
        LabelTxt.BackgroundTransparency = 1
        LabelTxt.Text = label
        LabelTxt.TextColor3 = C.TEXT_2
        LabelTxt.Font = Enum.Font.GothamMedium
        LabelTxt.TextSize = 11
        LabelTxt.TextXAlignment = Enum.TextXAlignment.Left
        local DropBtn = Instance.new("TextButton", Row)
        DropBtn.Size = UDim2.new(0.53, 0, 0, 28)
        DropBtn.Position = UDim2.new(0.44, 0, 0.5, -14)
        DropBtn.BackgroundColor3 = C.ELEVATED
        Corner(DropBtn, 4); Stroke(DropBtn, C.DIVIDER)
        DropBtn.Text = displayText()
        DropBtn.TextColor3 = C.TEXT_1
        DropBtn.Font = Enum.Font.GothamMedium
        DropBtn.TextSize = 11
        DropBtn.AutoButtonColor = false

        local Panel = Instance.new("Frame", MainSG)
        Panel.Size = UDim2.new(0, 200, 0, math.min(#options * 28 + 36, 180))
        Panel.BackgroundColor3 = C.ELEVATED
        Corner(Panel, 6); Stroke(Panel, C.BORDER)
        Panel.Visible = false; Panel.ZIndex = 20

        local PanelScroll = Instance.new("ScrollingFrame", Panel)
        PanelScroll.Size = UDim2.new(1, -4, 1, -4)
        PanelScroll.Position = UDim2.new(0, 2, 0, 2)
        PanelScroll.BackgroundTransparency = 1
        PanelScroll.BorderSizePixel = 0
        PanelScroll.ScrollBarThickness = 3
        PanelScroll.ZIndex = 20

        local PanelLayout = Instance.new("UIListLayout", PanelScroll)
        PanelLayout.Padding = UDim.new(0, 2)
        PanelLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PanelLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            PanelScroll.CanvasSize = UDim2.new(0, 0, 0, PanelLayout.AbsoluteContentSize.Y + 6)
        end)

        local function rebuildOptions(optList)
            for _, ch in ipairs(PanelScroll:GetChildren()) do
                if ch:IsA("TextButton") then ch:Destroy() end
            end
            local clearBtn = Instance.new("TextButton", PanelScroll)
            clearBtn.Size = UDim2.new(1, 0, 0, 26)
            clearBtn.BackgroundTransparency = 1
            clearBtn.Text = "None"; clearBtn.TextColor3 = C.TEXT_3
            clearBtn.Font = Enum.Font.GothamMedium
            clearBtn.TextSize = 11; clearBtn.ZIndex = 21
            clearBtn.MouseButton1Click:Connect(function()
                if isMulti then table.clear(selected) else selected = "" end
                DropBtn.Text = displayText()
                Panel.Visible = false; activeDropdown = nil
                callback(isMulti and {} or "")
            end)
            for _, opt in ipairs(optList) do
                local isOn = isMulti and selected[opt] == true or selected == opt
                local OBtn = Instance.new("TextButton", PanelScroll)
                OBtn.Size = UDim2.new(1, 0, 0, 26)
                OBtn.BackgroundColor3 = isOn and C.ACCENT_D or C.ELEVATED
                OBtn.BorderSizePixel = 0; Corner(OBtn, 4)
                OBtn.Text = opt
                OBtn.TextColor3 = isOn and C.TEXT_1 or C.TEXT_2
                OBtn.Font = Enum.Font.GothamMedium
                OBtn.TextSize = 11; OBtn.ZIndex = 21
                OBtn.MouseButton1Click:Connect(function()
                    if isMulti then
                        if selected[opt] then selected[opt] = nil else selected[opt] = true end
                        for _, child in ipairs(PanelScroll:GetChildren()) do
                            if child:IsA("TextButton") and child ~= clearBtn then
                                local on = selected[child.Text] == true
                                child.BackgroundColor3 = on and C.ACCENT_D or C.ELEVATED
                                child.TextColor3 = on and C.TEXT_1 or C.TEXT_2
                            end
                        end
                    else
                        selected = (opt == "None") and "" or opt
                        Panel.Visible = false; activeDropdown = nil
                    end
                    DropBtn.Text = displayText()
                    local result
                    if isMulti then
                        result = {}
                        for k in pairs(selected) do result[#result+1] = k end
                    else
                        result = selected
                    end
                    callback(result)
                end)
            end
        end

        rebuildOptions(options)

        DropBtn.MouseButton1Click:Connect(function()
            if Panel.Visible then Panel.Visible = false; activeDropdown = nil; return end
            if activeDropdown and activeDropdown ~= Panel then
                activeDropdown.Visible = false
            end
            local absPos  = DropBtn.AbsolutePosition
            local absSize = DropBtn.AbsoluteSize
            Panel.Position = UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 4)
            Panel.Visible = true; activeDropdown = Panel
        end)

        local function SetOptions(newOpts)
            rebuildOptions(newOpts)
            Panel.Size = UDim2.new(0, 200, 0, math.min(#newOpts * 28 + 36, 180))
        end
        local function GetSelected()
            if isMulti then
                local r = {}
                for k in pairs(selected) do r[#r+1] = k end
                return r
            end
            return selected
        end

        return Row, SetOptions, GetSelected
    end

    S.UserInputService.InputBegan:Connect(function(input)
        if not activeDropdown or not activeDropdown.Visible then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local p    = input.Position
        local pos  = activeDropdown.AbsolutePosition
        local size = activeDropdown.AbsoluteSize
        if p.X >= pos.X and p.X <= pos.X + size.X
            and p.Y >= pos.Y and p.Y <= pos.Y + size.Y then return end
        activeDropdown.Visible = false; activeDropdown = nil
    end)

    local Root = Instance.new("Frame", MainSG)
    Root.Size = UDim2.new(0.9, 0, 0.8, 0)
    Root.SizeConstraint = Enum.SizeConstraint.RelativeYY
    Root.Position = UDim2.new(0.5, 0, 0.5, 0)
    Root.AnchorPoint = Vector2.new(0.5, 0.5)
    Root.BackgroundTransparency = 1

    local UIConstraint = Instance.new("UISizeConstraint", Root)
    UIConstraint.MinSize = Vector2.new(340, 280)
    UIConstraint.MaxSize = Vector2.new(460, 360)

    local Win = Instance.new("Frame", Root)
    Win.Size = UDim2.new(1, 0, 1, 0)
    Win.BackgroundColor3 = C.BASE
    Win.ClipsDescendants = true
    Corner(Win, 8); Stroke(Win, C.BORDER, 1)

    local Header = Instance.new("Frame", Win)
    Header.Size = UDim2.new(1, 0, 0, 42)
    Header.BackgroundColor3 = C.SURFACE; Corner(Header, 8)

    local HFix = Instance.new("Frame", Header)
    HFix.Size = UDim2.new(1, 0, 0, 8)
    HFix.Position = UDim2.new(0, 0, 1, -8)
    HFix.BackgroundColor3 = C.SURFACE; HFix.BorderSizePixel = 0

    local AccentLine = Instance.new("Frame", Header)
    AccentLine.Size = UDim2.new(0, 40, 0, 3)
    AccentLine.Position = UDim2.new(0, 14, 0, 0)
    AccentLine.BackgroundColor3 = C.ACCENT
    AccentLine.BorderSizePixel = 0; Corner(AccentLine, 2)

    local TitleLbl = Instance.new("TextLabel", Header)
    TitleLbl.Size = UDim2.new(1, -70, 1, 0)
    TitleLbl.Position = UDim2.new(0, 14, 0, 0)
    TitleLbl.BackgroundTransparency = 1; TitleLbl.RichText = true
    TitleLbl.Text = "NULLTIME <font color='#FF4D4D'>RED EDITION V2</font>"
    TitleLbl.TextColor3 = C.TEXT_1
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.TextSize = 13
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left

    MakeDraggable(Root, Header)

    local ToggleBtn = Instance.new("TextButton", MainSG)
    ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
    ToggleBtn.Position = UDim2.new(0, 15, 0.5, -25)
    ToggleBtn.BackgroundColor3 = C.SURFACE
    ToggleBtn.Text = "🔴"
    ToggleBtn.TextSize = 20
    Corner(ToggleBtn, 25)
    Stroke(ToggleBtn, C.ACCENT, 2)

    local isUiOpen = true
    ToggleBtn.MouseButton1Click:Connect(function()
        isUiOpen = not isUiOpen
        Root.Visible = isUiOpen
    end)

    local MinBtn = Instance.new("TextButton", Header)
    MinBtn.Size = UDim2.new(0, 24, 0, 24)
    MinBtn.Position = UDim2.new(1, -30, 0.5, -12)
    MinBtn.BackgroundColor3 = C.SURFACE; MinBtn.BorderSizePixel = 0
    MinBtn.Text = "—"; MinBtn.TextColor3 = C.TEXT_2
    MinBtn.Font = Enum.Font.GothamBold; MinBtn.TextSize = 14
    MinBtn.AutoButtonColor = false; Corner(MinBtn, 4)

    MinBtn.MouseButton1Click:Connect(function()
        isUiOpen = false
        Root.Visible = false
    end)

    local NavFrame = Instance.new("Frame", Win)
    NavFrame.Size = UDim2.new(0, 90, 1, -42)
    NavFrame.Position = UDim2.new(0, 0, 0, 42)
    NavFrame.BackgroundColor3 = C.SURFACE
    NavFrame.BorderSizePixel = 0

    local NavLayout = Instance.new("UIListLayout", NavFrame)
    NavLayout.Padding = UDim.new(0, 4)
    NavLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local NavPad = Instance.new("UIPadding", NavFrame)
    NavPad.PaddingTop = UDim.new(0, 8)
    NavPad.PaddingLeft = UDim.new(0, 6)
    NavPad.PaddingRight = UDim.new(0, 6)

    local PagesFrame = Instance.new("Frame", Win)
    PagesFrame.Size = UDim2.new(1, -90, 1, -42)
    PagesFrame.Position = UDim2.new(0, 90, 0, 42)
    PagesFrame.BackgroundTransparency = 1

    local modules = {}
    local function CreateModule(name)
        local TabBtn = Instance.new("TextButton", NavFrame)
        TabBtn.Size = UDim2.new(1, 0, 0, 32)
        TabBtn.BackgroundColor3 = C.ELEVATED
        TabBtn.Text = name
        TabBtn.TextColor3 = C.TEXT_2
        TabBtn.Font = Enum.Font.GothamBold
        TabBtn.TextSize = 11
        Corner(TabBtn, 4)

        local Page = Instance.new("ScrollingFrame", PagesFrame)
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.BorderSizePixel = 0
        Page.ScrollBarThickness = 3
        Page.ScrollBarImageColor3 = C.ACCENT
        Page.Visible = false

        local Layout = Instance.new("UIListLayout", Page)
        Layout.Padding = UDim.new(0, 8)
        Layout.SortOrder = Enum.SortOrder.LayoutOrder

        local Pad = Instance.new("UIPadding", Page)
        Pad.PaddingTop = UDim.new(0, 10); Pad.PaddingBottom = UDim.new(0, 10)
        Pad.PaddingLeft = UDim.new(0, 10); Pad.PaddingRight = UDim.new(0, 10)

        Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 20)
        end)

        TabBtn.MouseButton1Click:Connect(function()
            for _, m in pairs(modules) do
                m.Page.Visible = false
                m.Btn.BackgroundColor3 = C.ELEVATED
                m.Btn.TextColor3 = C.TEXT_2
            end
            Page.Visible = true
            TabBtn.BackgroundColor3 = C.ACCENT
            TabBtn.TextColor3 = C.TEXT_1
        end)

        local modData = {Page = Page, Btn = TabBtn}
        modules[name] = modData
        return Page
    end

    local DupePage     = CreateModule("Dupe")
    local MovementPage = CreateModule("Movement")
    local ESPPage      = CreateModule("ESP")
    local BoulderPage  = CreateModule("Boulder")

    modules["Dupe"].Page.Visible = true
    modules["Dupe"].Btn.BackgroundColor3 = C.ACCENT
    modules["Dupe"].Btn.TextColor3 = C.TEXT_1

    local function isCrystalTool(child)
        if not child:IsA("Tool") then return false end
        return child:GetAttribute("CrystalName") ~= nil
            or child:GetAttribute("Tier") ~= nil
            or child.Name:find("Crystal") ~= nil
    end

    local function isRuneTool(child)
        if not child:IsA("Tool") then return false end
        return child:GetAttribute("RuneId") ~= nil
            or child:GetAttribute("RuneName") ~= nil
            or child:GetAttribute("IsRune") == true
            or child.Name:find("Rune", 1, true) ~= nil
    end

    local crystalOptions = {}
    local runeOptions    = {}
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
        if bp then for _, c in ipairs(bp:GetChildren()) do check(c) end end
        local char = LocalPlayer.Character
        if char then for _, c in ipairs(char:GetChildren()) do check(c) end end
        table.sort(crystalOptions); table.sort(runeOptions)
    end

    scanInventory()

    local dropRemoteCache = nil
    local function getDropRemote()
        if dropRemoteCache and dropRemoteCache.Parent then return dropRemoteCache end
        local r = S.ReplicatedStorage:FindFirstChild("Remotes")
        dropRemoteCache = r and r:FindFirstChild("CrystalDropRequest")
        return dropRemoteCache
    end

    local function executeDropAll(instant)
        local remote = getDropRemote()
        if not remote then return end

        local selCrystals = getCrystalSelected and getCrystalSelected() or {}
        local selRunes    = getRuneSelected    and getRuneSelected()    or {}

        if #selCrystals == 0 and #selRunes == 0 then return end

        local dropAllRunes = false
        local targetSet = {}
        for _, name in ipairs(selCrystals) do targetSet[name] = true end
        for _, name in ipairs(selRunes) do 
            if name == "ALL RUNES" then
                dropAllRunes = true
            else
                targetSet[name] = true 
            end
        end

        local itemsToDrop = {}
        local containers = {
            LocalPlayer:FindFirstChildOfClass("Backpack"),
            LocalPlayer.Character
        }

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

        for _, itemName in ipairs(itemsToDrop) do
            pcall(function() remote:FireServer(itemName) end)
        end
    end

    CreateSection(DupePage, "Drop Selection")

    local _, cSetOpts, cGetSel = CreateDropdown(
        DupePage, "Crystals to Drop", crystalOptions, true,
        function() end
    )
    crystalSetOpts     = cSetOpts
    getCrystalSelected = cGetSel

    local _, rSetOpts, rGetSel = CreateDropdown(
        DupePage, "Runes to Drop", runeOptions, true,
        function() end
    )
    runeSetOpts     = rSetOpts
    getRuneSelected = rGetSel

    local RefreshBtn = CreateButton(DupePage, "🔄 Refresh Inventory")
    RefreshBtn.MouseButton1Click:Connect(function()
        scanInventory()
        if crystalSetOpts then crystalSetOpts(crystalOptions) end
        if runeSetOpts    then runeSetOpts(runeOptions)    end
    end)

    CreateSection(DupePage, "Actions")

    local DropAllBtn = CreateButton(DupePage, "🗑️ Drop All Selection")
    DropAllBtn.MouseButton1Click:Connect(function()
        task.spawn(function() executeDropAll(false) end)
    end)

    local ResetCharBtn = CreateButton(DupePage, "⟳ Reset Character")
    ResetCharBtn.MouseButton1Click:Connect(function()
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum.Health = 0 end) end
    end)

    local TimerDupeBtn = CreateButton(DupePage, "⏱️ Start Timer & Dupe")
    local isCountingDown = false
    local dropRepeatAmount = 5

    CreateInput(DupePage, "Dupe Multiplier (Amount)", "5", function(txt)
        local n = tonumber(txt)
        if n and n > 0 then
            dropRepeatAmount = math.clamp(math.floor(n), 1, 100)
        else
            dropRepeatAmount = 5
        end
    end)

    TimerDupeBtn.MouseButton1Click:Connect(function()
        if isCountingDown then return end
        isCountingDown = true

        task.spawn(function()
            local txtLabel = TimerDupeBtn:FindFirstChild("BtnText")
            local duration = 5.00
            local startTime = os.clock()
            local endTime = startTime + duration

            while true do
                local now = os.clock()
                local remaining = math.max(0, endTime - now)

                if txtLabel then
                    local seconds = math.floor(remaining)
                    local millis = math.floor((remaining - seconds) * 100)
                    txtLabel.Text = string.format("[NULLTIME] 00:%02d.%02d", seconds, millis)
                end

                if remaining <= 0 then break end
                task.wait(0.02)
            end

            if txtLabel then
                txtLabel.Text = "[NULLTIME] Executing " .. dropRepeatAmount .. "x Dupe..."
            end

            for i = 1, dropRepeatAmount do
                task.spawn(function() executeDropAll(true) end)
                if i % 5 == 0 then task.wait() end
            end

            task.wait(0.15)
            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum.Health = 0 end) end

            task.wait(1.0)
            isCountingDown = false
            if txtLabel then txtLabel.Text = "⏱️ Start Timer & Dupe" end
        end)
    end)

    CreateSection(MovementPage, "Player Speed & Jump")

    local SpeedBtn = CreateButton(MovementPage, "⚡ Speed Boost (60)")
    local speedEnabled = false
    SpeedBtn.MouseButton1Click:Connect(function()
        speedEnabled = not speedEnabled
        local txt = SpeedBtn:FindFirstChild("BtnText")
        if txt then txt.Text = speedEnabled and "⚡ Speed Boost: ACTIVE (60)" or "⚡ Speed Boost (60)" end
    end)

    S.RunService.Stepped:Connect(function()
        if speedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 60
        end
    end)

    local JumpBtn = CreateButton(MovementPage, "🦘 Toggle High Jump (100)")
    local jumpEnabled = false
    JumpBtn.MouseButton1Click:Connect(function()
        jumpEnabled = not jumpEnabled
        local txt = JumpBtn:FindFirstChild("BtnText")
        if txt then txt.Text = jumpEnabled and "🦘 Jump: ACTIVE (100)" or "🦘 Toggle High Jump (100)" end
    end)

    S.RunService.Stepped:Connect(function()
        if jumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = 100
        end
    end)

    CreateSection(MovementPage, "Interactions & Collision")

    local InstaPickBtn = CreateButton(MovementPage, "⚡ Toggle Insta Pick Up")
    local instaPickEnabled = false
    local promptConn = nil

    InstaPickBtn.MouseButton1Click:Connect(function()
        instaPickEnabled = not instaPickEnabled
        local txt = InstaPickBtn:FindFirstChild("BtnText")
        if txt then txt.Text = instaPickEnabled and "⚡ Insta Pick Up: ACTIVE" or "⚡ Toggle Insta Pick Up" end

        if instaPickEnabled then
            for _, prompt in ipairs(S.Workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then prompt.HoldDuration = 0 end
            end
            promptConn = S.ProximityPromptService.PromptShown:Connect(function(prompt)
                if instaPickEnabled then prompt.HoldDuration = 0 end
            end)
        else
            if promptConn then promptConn:Disconnect() end
        end
    end)

    local NoclipBtn = CreateButton(MovementPage, "👻 Toggle Noclip")
    local noclipEnabled = false
    NoclipBtn.MouseButton1Click:Connect(function()
        noclipEnabled = not noclipEnabled
        local txt = NoclipBtn:FindFirstChild("BtnText")
        if txt then txt.Text = noclipEnabled and "👻 Noclip: ACTIVE" or "👻 Toggle Noclip" end
    end)

    S.RunService.Stepped:Connect(function()
        if noclipEnabled and LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end)

    CreateSection(ESPPage, "Player Visuals")

    local EspBtn = CreateButton(ESPPage, "👁️ Toggle Player ESP")
    local espEnabled = false

    local function applyEsp(player)
        if player == LocalPlayer then return end
        local function highlightChar(char)
            if not char then return end
            if not char:FindFirstChild("RedESP") then
                local hl = Instance.new("Highlight")
                hl.Name = "RedESP"
                hl.FillColor = Color3.fromRGB(255, 0, 0)
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.FillTransparency = 0.5
                hl.OutlineTransparency = 0
                hl.Parent = char
            end
        end
        if player.Character then highlightChar(player.Character) end
        player.CharacterAdded:Connect(highlightChar)
    end

    local function removeEsp()
        for _, p in ipairs(S.Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("RedESP") then
                p.Character.RedESP:Destroy()
            end
        end
    end

    EspBtn.MouseButton1Click:Connect(function()
        espEnabled = not espEnabled
        local txt = EspBtn:FindFirstChild("BtnText")
        if txt then txt.Text = espEnabled and "👁️ Player ESP: ACTIVE" or "👁️ Toggle Player ESP" end

        if espEnabled then
            for _, p in ipairs(S.Players:GetPlayers()) do applyEsp(p) end
            S.Players.PlayerAdded:Connect(applyEsp)
        else
            removeEsp()
        end
    end)

    local ExactBoulders = { "Mossite", "Voltite", "Gildrite", "Rimeveil", "Nocturnite" }
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
            if exactName then table.insert(boulderList, { Instance = obj, Type = exactName }) end
        end
    end

    scanExactBoulders()

    CreateSection(BoulderPage, "Boulder Selection")

    local _, bSetOpts, bGetSel = CreateDropdown(
        BoulderPage, "Target Boulders", ExactBoulders, true,
        function() end
    )
    setBoulderOpts      = bSetOpts
    getSelectedBoulders = bGetSel

    local ScanBouldersBtn = CreateButton(BoulderPage, "🔍 Exact Map Scan")
    ScanBouldersBtn.MouseButton1Click:Connect(scanExactBoulders)

    CreateSection(BoulderPage, "Boulder ESP & Auto-Farm")

    local BoulderEspBtn = CreateButton(BoulderPage, "🪨 Toggle Boulder ESP")
    local boulderEspActive = false

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
                    hl.FillTransparency = 0.4
                    hl.Parent = obj
                end
            end
        end
    end

    local function removeBoulderESP()
        for _, item in ipairs(boulderList) do
            local obj = item.Instance
            if obj and obj:FindFirstChild("BoulderESP") then obj.BoulderESP:Destroy() end
        end
    end

    BoulderEspBtn.MouseButton1Click:Connect(function()
        boulderEspActive = not boulderEspActive
        local txt = BoulderEspBtn:FindFirstChild("BtnText")
        if txt then txt.Text = boulderEspActive and "🪨 Boulder ESP: ACTIVE" or "🪨 Toggle Boulder ESP" end

        if boulderEspActive then
            scanExactBoulders()
            applyBoulderESP()
        else
            removeBoulderESP()
        end
    end)

    local AutoFarmBtn = CreateButton(BoulderPage, "⛏️ Toggle Auto-Farm Boulders")
    local autoFarmActive = false

    AutoFarmBtn.MouseButton1Click:Connect(function()
        autoFarmActive = not autoFarmActive
        local txt = AutoFarmBtn:FindFirstChild("BtnText")
        if txt then txt.Text = autoFarmActive and "⛏️ Auto-Farm: ACTIVE" or "⛏️ Toggle Auto-Farm Boulders" end

        if autoFarmActive then
            task.spawn(function()
                while autoFarmActive do
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
                                local pos = item.Instance:IsA("Model") and item.Instance:GetPivot().Position or item.Instance.Position
                                local dist = (root.Position - pos).Magnitude
                                if dist < minDistance then
                                    minDistance = dist
                                    closest = item
                                end
                            end
                        end

                        if closest and closest.Instance then
                            local pos = closest.Instance:IsA("Model") and closest.Instance:GetPivot().Position or closest.Instance.Position
                            root.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0))
                            local tool = char:FindFirstChildOfClass("Tool")
                            if tool then tool:Activate() end
                        end
                    end
                    task.wait(0.5)
                end
            end)
        end
    end)
end
