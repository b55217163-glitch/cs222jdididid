--[[
    ShitaroMenu — DracoHub Skills Edition
    UI каркас: ShitaroMenuOnly (сохранён)
    Функционал: скиллы из DracoHub_ScannerV7
    Установка: LocalScript в StarterPlayer > StarterPlayerScripts
    Вкладки: skills, mobile (aim/trigger/visuals/skins/settings удалены)
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local GuiService       = game:GetService("GuiService")
local Stats            = game:GetService("Stats")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local previous = playerGui:FindFirstChild("ShitaroMenuOnly")
if previous then previous:Destroy() end

--==============================================================
-- ПАЛИТРА / ШРИФТЫ / ИКОНКИ
--==============================================================
local colors = {
    bg     = Color3.fromRGB(7, 7, 9),
    text   = Color3.fromRGB(230, 230, 236),
    sub    = Color3.fromRGB(170, 170, 178),
    dim    = Color3.fromRGB(112, 112, 122),
    faint  = Color3.fromRGB(68, 68, 76),
    accent = Color3.fromRGB(200, 148, 232),
    on     = Color3.fromRGB(120, 210, 150),
    off    = Color3.fromRGB(70, 70, 78),
}

local fonts = {
    normal    = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold),
    bold      = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold),
    watermark = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
}

local icons = {
    code      = 106124864132557,
    gear      = 109485777305919,
    sliders   = 125396339381135,
    save      = 122894934359450,
    chevron   = 71457658246709,
    grip      = 128492050787735,
    layers    = 114499998778667,
    wifi      = 104941258142372,
    ram       = 82464660673318,
    clock     = 136533241128438,
    skills    = 127369887384101,
    phone     = 127234874352422,
}

--==============================================================
-- ХЕЛПЕРЫ
--==============================================================
local function make(class, props, parent)
    local o = Instance.new(class)
    if o:IsA("GuiObject") then
        o.BorderSizePixel = 0
        o.BackgroundTransparency = 1
    end
    if o:IsA("TextLabel") or o:IsA("TextButton") then
        o.Text = ""
        o.FontFace = fonts.normal
        o.TextSize = 14
        o.TextColor3 = colors.text
        o.TextXAlignment = Enum.TextXAlignment.Left
        o.AutoLocalize = false
    end
    if o:IsA("GuiButton") then o.AutoButtonColor = false end
    for k, v in pairs(props or {}) do o[k] = v end
    o.Parent = parent
    return o
end

local function corner(p, r) return make("UICorner", {CornerRadius = r}, p) end

local function stroke(p, t)
    return make("UIStroke", {
        Color = Color3.new(1,1,1), Transparency = t, Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, p)
end

local function padding(p, l, r, t, b)
    make("UIPadding", {
        PaddingLeft = UDim.new(0,l), PaddingRight = UDim.new(0,r),
        PaddingTop = UDim.new(0,t), PaddingBottom = UDim.new(0,b),
    }, p)
end

local function rowLayout(p, gap, align)
    return make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, gap),
        VerticalAlignment = Enum.VerticalAlignment.Center,
        HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
    }, p)
end

local function image(p, key, size, order, trans)
    return make("ImageLabel", {
        Size = UDim2.fromOffset(size, size),
        Image = "rbxassetid://" .. icons[key],
        ScaleType = Enum.ScaleType.Fit,
        LayoutOrder = order or 0,
        ImageTransparency = trans or 0,
    }, p)
end

local function animate(obj, props, dur)
    TweenService:Create(obj,
        TweenInfo.new(dur or 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        props
    ):Play()
end

--==============================================================
-- КОРНЕВОЙ GUI
--==============================================================
local gui = make("ScreenGui", {
    Name = "ShitaroMenuOnly",
    IgnoreGuiInset = true,
    ResetOnSpawn = false,
    ScreenInsets = Enum.ScreenInsets.None,
    ClipToDeviceSafeArea = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 10000,
}, playerGui)

local connections = {}
local function connect(sig, cb)
    local c = sig:Connect(cb)
    table.insert(connections, c)
    return c
end

connect(gui.Destroying, function()
    for _, c in ipairs(connections) do c:Disconnect() end
end)

--==============================================================
-- ОКНО
--==============================================================
local window = make("Frame", {
    Name = "Menu",
    Position = UDim2.fromOffset(0, 0),
    Visible = false,
    Size = UDim2.fromOffset(780, 470),
    BackgroundTransparency = 0.16,
    BackgroundColor3 = colors.bg,
    Active = true,
}, gui)

local menuScale = make("UIScale", {Scale = 1}, window)
corner(window, UDim.new(0, 10))
stroke(window, 0.935)

local header = make("Frame", {Size = UDim2.new(1, 0, 0, 40)}, window)
local tintClip = make("Frame", {Size = UDim2.fromScale(1,1), ClipsDescendants = true}, header)
local tint = make("Frame", {
    Size = UDim2.new(1, 0, 1, 12),
    BackgroundColor3 = Color3.new(1,1,1),
    BackgroundTransparency = 0.976,
}, tintClip)
corner(tint, UDim.new(0, 10))

make("Frame", {
    Position = UDim2.fromOffset(0, 40),
    Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = Color3.new(1,1,1),
    BackgroundTransparency = 0.94,
}, window)

local dragHandle = make("TextButton", {Size = UDim2.fromScale(1,1), ZIndex = 1}, header)

local titleRow = make("Frame", {
    Position = UDim2.fromOffset(14, 0),
    Size = UDim2.fromOffset(0, 40),
    AutomaticSize = Enum.AutomaticSize.X,
    ZIndex = 2,
}, header)
rowLayout(titleRow, 8)

make("TextLabel", {
    Text = "shitaro",
    FontFace = fonts.bold,
    TextSize = 15,
    Size = UDim2.fromOffset(0, 40),
    AutomaticSize = Enum.AutomaticSize.X,
    LayoutOrder = 1,
}, titleRow)

make("Frame", {Size = UDim2.fromOffset(4, 1), LayoutOrder = 2}, titleRow)

local save = make("Frame", {
    Size = UDim2.fromOffset(24, 24),
    LayoutOrder = 3,
    BackgroundColor3 = Color3.new(1,1,1),
    BackgroundTransparency = 0.952,
}, titleRow)
corner(save, UDim.new(0, 6))
stroke(save, 0.925)
local saveIcon = image(save, "save", 13)
saveIcon.AnchorPoint = Vector2.new(0.5, 0.5)
saveIcon.Position = UDim2.fromScale(0.5, 0.5)
saveIcon.ImageColor3 = colors.dim

local config = make("Frame", {
    Size = UDim2.fromOffset(0, 24),
    AutomaticSize = Enum.AutomaticSize.X,
    LayoutOrder = 4,
}, titleRow)
rowLayout(config, 6)
make("TextLabel", {
    Text = "skills",
    TextSize = 13,
    TextColor3 = colors.dim,
    Size = UDim2.fromOffset(0, 24),
    AutomaticSize = Enum.AutomaticSize.X,
    LayoutOrder = 1,
}, config)
local configIcon = image(config, "chevron", 10, 2)
configIcon.ImageColor3 = colors.dim

local profile = make("Frame", {
    Size = UDim2.fromOffset(70, 24),
    LayoutOrder = 5,
    BackgroundColor3 = Color3.new(1,1,1),
    BackgroundTransparency = 0.952,
}, titleRow)
corner(profile, UDim.new(0, 6))
stroke(profile, 0.925)
make("TextLabel", {
    Text = "global",
    TextSize = 13,
    Position = UDim2.fromOffset(10, 0),
    Size = UDim2.new(1, -25, 1, 0),
}, profile)
local profileIcon = image(profile, "chevron", 10)
profileIcon.AnchorPoint = Vector2.new(1, 0.5)
profileIcon.Position = UDim2.new(1, -8, 0.5, 0)
profileIcon.ImageColor3 = colors.dim

local body = make("Frame", {
    Name = "Pages",
    Position = UDim2.fromOffset(0, 41),
    Size = UDim2.new(1, 0, 1, -89),
}, window)

--==============================================================
-- НАВИГАЦИЯ — только 2 вкладки
--==============================================================
local nav = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -9),
    Size = UDim2.fromOffset(0, 32),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundColor3 = Color3.new(1,1,1),
    BackgroundTransparency = 0.958,
    ZIndex = 3,
}, window)
local navCorner = corner(nav, UDim.new(1, 0))
stroke(nav, 0.935)
padding(nav, 3, 3, 3, 3)

local highlight = make("Frame", {
    Size = UDim2.fromOffset(0, 26),
    BackgroundColor3 = Color3.new(1,1,1),
    BackgroundTransparency = 0.925,
    ZIndex = 3,
}, nav)
corner(highlight, UDim.new(1, 0))

local tabRow = make("Frame", {
    Size = UDim2.fromOffset(0, 26),
    AutomaticSize = Enum.AutomaticSize.X,
    ZIndex = 4,
}, nav)

local navigationLayout = rowLayout(tabRow, 2)
local tabs = {}
local selected

local function updateHighlight()
    if not selected or not gui.Parent then return end
    local scale = menuScale.Scale
    local delta = (selected.button.AbsolutePosition - tabRow.AbsolutePosition) / scale
    animate(highlight, {
        Position = UDim2.fromOffset(delta.X, delta.Y),
        Size = UDim2.fromOffset(
            selected.button.AbsoluteSize.X / scale,
            selected.button.AbsoluteSize.Y / scale
        ),
    }, 0.24)
end

local function drawTab(tab)
    local active = tab == selected
    tab.label.FontFace = active and fonts.bold or fonts.normal
    animate(tab.label, {
        TextColor3 = active and colors.text
            or (tab.hover and colors.sub or colors.dim)
    })
    animate(tab.icon, {
        ImageColor3 = active and colors.accent
            or (tab.hover and colors.sub or colors.dim)
    })
    tab.page.Visible = active
end

-- ВАЖНО: только 2 вкладки — никакого aim/trigger/visuals/skins/settings
for index, entry in ipairs({
    { "skills", "skills" },
    { "mobile", "phone"  },
}) do
    local button = make("TextButton", {
        Name = entry[1],
        Size = UDim2.fromOffset(0, 26),
        AutomaticSize = Enum.AutomaticSize.X,
        LayoutOrder = index,
        ZIndex = 4,
    }, tabRow)
    padding(button, 10, 12, 0, 0)
    rowLayout(button, 6)

    local tab = {
        button = button,
        icon = image(button, entry[2], 13, 1),
        label = make("TextLabel", {
            Text = entry[1],
            TextSize = 13,
            Size = UDim2.fromOffset(0, 26),
            AutomaticSize = Enum.AutomaticSize.X,
            LayoutOrder = 2,
            ZIndex = 4,
        }, button),
        page = make("Frame", {
            Name = entry[1],
            Size = UDim2.fromScale(1, 1),
            Visible = false,
        }, body),
    }
    tab.icon.ZIndex = 4
    table.insert(tabs, tab)
    selected = selected or tab

    connect(button.MouseEnter, function() tab.hover = true; drawTab(tab) end)
    connect(button.MouseLeave, function() tab.hover = false; drawTab(tab) end)
    connect(button.Activated, function()
        selected = tab
        for _, t in ipairs(tabs) do drawTab(t) end
        task.defer(updateHighlight)
    end)
    connect(button:GetPropertyChangedSignal("AbsoluteSize"), updateHighlight)
    drawTab(tab)
end

connect(tabRow:GetPropertyChangedSignal("AbsolutePosition"), updateHighlight)
task.defer(updateHighlight)

local grip = make("ImageButton", {
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -6, 1, -6),
    Size = UDim2.fromOffset(11, 11),
    Image = "rbxassetid://" .. icons.grip,
    ImageColor3 = colors.faint,
    ZIndex = 10,
}, window)

--==============================================================
-- WATERMARK
--==============================================================
local inset = GuiService:GetGuiInset()
local watermark = make("TextButton", {
    Name = "Watermark",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, 0, 0, 0),
    ZIndex = 20,
    Size = UDim2.fromOffset(0, 34),
    AutomaticSize = Enum.AutomaticSize.X,
}, gui)
rowLayout(watermark, 10, Enum.HorizontalAlignment.Left)

local function pill(order)
    local f = make("Frame", {
        Size = UDim2.fromOffset(0, 34),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Color3.fromRGB(12, 20, 25),
        BackgroundTransparency = 0.686,
        LayoutOrder = order,
    }, watermark)
    corner(f, UDim.new(1, 0))
    padding(f, 12, 12, 8, 8)
    rowLayout(f, 0)
    return f
end

local function spacer(parent, w, order)
    make("Frame", {Size = UDim2.fromOffset(w, 1), LayoutOrder = order}, parent)
end

local function watermarkText(parent, text, order)
    local c = make("Frame", {
        Size = UDim2.fromOffset(0, 18),
        AutomaticSize = Enum.AutomaticSize.X,
        LayoutOrder = order,
    }, parent)
    local shadow = make("TextLabel", {
        Text = text, FontFace = fonts.watermark, TextSize = 16,
        TextColor3 = Color3.new(), TextTransparency = 0.15,
        Position = UDim2.fromOffset(1,1),
        Size = UDim2.fromOffset(0,18), AutomaticSize = Enum.AutomaticSize.X,
    }, c)
    local label = make("TextLabel", {
        Text = text, FontFace = fonts.watermark, TextSize = 16,
        TextColor3 = Color3.new(1,1,1),
        Size = UDim2.fromOffset(0,18), AutomaticSize = Enum.AutomaticSize.X,
        ZIndex = 2,
    }, c)
    connect(label:GetPropertyChangedSignal("Text"), function()
        shadow.Text = label.Text
    end)
    return label
end

local brand = pill(1)
image(brand, "code", 18, 1, 0.392)
spacer(brand, 8, 2)
watermarkText(brand, "shitaro.lol", 3)

local metrics = pill(2)
local values = {}
for index, name in ipairs({"User","FPS","Ping","RAM","Time"}) do
    if index > 1 then
        local sep = make("Frame", {
            Size = UDim2.fromOffset(25, 14),
            LayoutOrder = index * 2 - 1,
        }, metrics)
        make("Frame", {
            AnchorPoint = Vector2.new(0.5,0.5),
            Position = UDim2.fromScale(0.5,0.5),
            Size = UDim2.fromOffset(1,14),
            BackgroundColor3 = Color3.new(1,1,1),
            BackgroundTransparency = 0.392,
        }, sep)
    end
    local group = make("Frame", {
        Size = UDim2.fromOffset(0,18),
        AutomaticSize = Enum.AutomaticSize.X,
        LayoutOrder = index * 2,
    }, metrics)
    rowLayout(group, 0)
    if name == "User" then
        local av = make("ImageLabel", {
            Size = UDim2.fromOffset(18,18),
            LayoutOrder = 1,
            Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=48&h=48",
            ScaleType = Enum.ScaleType.Crop,
            BackgroundColor3 = Color3.fromRGB(20,20,20),
            BackgroundTransparency = 0,
        }, group)
        corner(av, UDim.new(1,0))
    else
        local keys = {FPS="layers", Ping="wifi", RAM="ram", Time="clock"}
        image(group, keys[name], 14, 1, 0.392)
    end
    spacer(group, 8, 2)
    values[name] = watermarkText(group, name == "User" and player.Name or "-", 3)
end

--==============================================================
-- REMOTE / SKILLS LAYER
--==============================================================
local RS_Characters = ReplicatedStorage:FindFirstChild("Characters")
local function findRemote(charName, remoteName)
    if not RS_Characters then return nil end
    local char = RS_Characters:FindFirstChild(charName)
    if not char then return nil end
    local remotes = char:FindFirstChild("Remotes")
    if not remotes then return nil end
    return remotes:FindFirstChild(remoteName)
end

local function fireAll(remote, ...)
    if not remote then return false end
    pcall(function() remote:FireServer(...) end)
    return true
end

local function firePlayer(remote, target)
    if not remote then return false end
    target = target or player
    pcall(function()
        remote:FireServer(target.DisplayName)
        remote:FireServer(target.Name)
        remote:FireServer(target.Character)
    end)
    return true
end

-- ЗАЩИТА: ищем только игрока (не NPC)
local function nearestPlayer(maxDist)
    maxDist = maxDist or math.huge
    local myChar = player.Character
    if not myChar then return nil end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end
    local best, bestD = nil, maxDist
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = (hrp.Position - myRoot.Position).Magnitude
                if d < bestD then
                    bestD = d
                    best = plr
                end
            end
        end
    end
    return best
end

--==============================================================
-- РЕАЛИЗАЦИЯ СКИЛЛОВ (из DracoHub)
--==============================================================
local skills = {}

-- Общий Homelander HitGround (Laser/Flashstrike/Upthrow/Kick/OnePunch)
local function homelanderHit(target)
    target = target or nearestPlayer(50)
    if not target then return false end
    local r = findRemote("Homelander", "HitGround")
    return firePlayer(r, target)
end

skills["Laser"]         = { key = "Z", fn = function() return homelanderHit(nearestPlayer(60)) end }
skills["Flashstrike"]   = { key = "X", fn = function() return homelanderHit(nearestPlayer(50)) end }
skills["Upthrow"]       = { key = "B", fn = function() return homelanderHit(nearestPlayer(20)) end }
skills["OnePunch"]      = { key = "V", fn = function() return homelanderHit(nearestPlayer(15)) end }
skills["Ramkill"]       = { key = "C", fn = function() return homelanderHit(nearestPlayer(10)) end }

-- Tear (Demogorgon ComboWeak)
skills["Tear"] = { key = "H", fn = function()
    local r = findRemote("Demogorgon", "ComboWeak") or findRemote("Ghostface", "ComboWeak")
    if not r then return false end
    return fireAll(r)
end }

-- SCP-173 Bash2
skills["SCP173"] = { key = "F", fn = function()
    local r = findRemote("SCPGuard", "Bash2")
    if not r then return false end
    local t = nearestPlayer(10)
    if not t then return false end
    return firePlayer(r, t)
end }

-- Speed Crash (The Flash CW)
skills["Speed Crash"] = { key = "G", fn = function()
    local r = findRemote("TheFlashCW", "HitGround")
    if not r then return false end
    return firePlayer(r, nearestPlayer(30))
end }

-- A-Train Finish (Steve_H)
skills["A-Train Finish"] = { key = "T", fn = function()
    local r = findRemote("Steve_H", "Bash2") or findRemote("Steve", "Drag")
    if not r then return false end
    return firePlayer(r, nearestPlayer(15))
end }

-- Kira Death Note (Counter + HitGround)
skills["Kira Kill"] = { key = "R", fn = function()
    local r = findRemote("Kira", "HitGround")
    if not r then return false end
    return firePlayer(r, nearestPlayer(30))
end }

-- Pounce (Steve)
skills["Pounce"] = { key = "Q", fn = function()
    local r = findRemote("Steve", "Drag")
    if not r then return false end
    return firePlayer(r, nearestPlayer(20))
end }

-- Myers групповые
skills["Neck Snap"] = { key = "N", fn = function()
    local r = findRemote("Myers", "HitGround") or findRemote("Michael", "HitGround")
    if not r then return false end
    return firePlayer(r, nearestPlayer(8))
end }

skills["Terror Blade"] = { key = "M", fn = function()
    local r = findRemote("Myers", "Counter") or findRemote("Michael", "Counter")
    if not r then return false end
    return fireAll(r)
end }

skills["Stalk Mode"] = { key = "P", fn = function()
    -- Активация стойки Мейерса
    local char = player.Character
    if not char then return false end
    player:SetAttribute("YYDSStalkMode", not (player:GetAttribute("YYDSStalkMode") == true))
    return true
end }

-- X-Regen (Life Insure) — цикл, включается/выключается
local xRegenRunning = false
local function xRegenLoop()
    if xRegenRunning then return end
    xRegenRunning = true
    task.spawn(function()
        while xRegenRunning do
            local char = player.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health < hum.MaxHealth * 0.2 then
                    local r = findRemote("Wolverine", "HitGround")
                        or findRemote("Deadpool", "HitGround")
                    if r then firePlayer(r, player) end
                end
            end
            task.wait(1)
        end
    end)
end
skills["X-Regen"] = { key = "K", toggle = true, fn = function(on)
    if on then xRegenLoop()
    else xRegenRunning = false end
    return true
end }

-- Homelander Fly (локальный — BodyVelocity + анимация)
local flyConn, flyBV
skills["Homelander Fly"] = { key = "Y", toggle = true, fn = function(on)
    local char = player.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return false end

    if on then
        if flyBV then return end
        hum.PlatformStand = true
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(1e5,1e5,1e5)
        flyBV.Velocity = Vector3.zero
        flyBV.Parent = hrp

        flyConn = RunService.RenderStepped:Connect(function()
            local cam = workspace.CurrentCamera
            if not cam or not flyBV then return end
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
            flyBV.Velocity = dir * 80
        end)
    else
        if flyConn then flyConn:Disconnect() flyConn = nil end
        if flyBV then flyBV:Destroy() flyBV = nil end
        hum.PlatformStand = false
    end
    return true
end }

--==============================================================
-- ВКЛАДКА SKILLS — построение карточек
--==============================================================
local skillsPage = tabs[1].page
local skillsScroll = make("ScrollingFrame", {
    Size = UDim2.fromScale(1, 1),
    CanvasSize = UDim2.fromOffset(0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = colors.dim,
    ScrollingDirection = Enum.ScrollingDirection.Y,
}, skillsPage)

padding(skillsScroll, 10, 10, 10, 10)
local skillsList = make("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 6),
}, skillsScroll)

local function skillRow(name, cfg)
    local card = make("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Color3.new(1,1,1),
        BackgroundTransparency = 0.958,
        LayoutOrder = #skillsScroll:GetChildren(),
    }, skillsScroll)
    corner(card, UDim.new(0, 8))
    stroke(card, 0.935)

    make("TextLabel", {
        Text = name,
        TextSize = 13,
        TextColor3 = colors.text,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(0.5, -12, 1, 0),
    }, card)

    if cfg.key then
        make("TextLabel", {
            Text = "[" .. cfg.key .. "]",
            TextSize = 11,
            TextColor3 = colors.dim,
            Position = UDim2.new(0.5, 0, 0, 12),
            Size = UDim2.fromOffset(40, 16),
        }, card)
    end

    if cfg.toggle then
        local track = make("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -12, 0.5, 0),
            Size = UDim2.fromOffset(30, 16),
            BackgroundColor3 = colors.off,
        }, card)
        corner(track, UDim.new(1,0))
        local knob = make("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 2, 0.5, 0),
            Size = UDim2.fromOffset(12, 12),
            BackgroundColor3 = colors.sub,
        }, track)
        corner(knob, UDim.new(1,0))

        local btn = make("TextButton", {Size = UDim2.fromScale(1,1), ZIndex = 5}, card)
        local state = false
        connect(btn.Activated, function()
            state = not state
            animate(track, {BackgroundColor3 = state and colors.on or colors.off})
            animate(knob, {Position = UDim2.new(0, state and 16 or 2, 0.5, 0)})
            local ok, res = pcall(cfg.fn, state)
            -- синхронизируем с плавающей кнопкой
            if skillStates[name] ~= nil then
                skillStates[name] = state
                syncFloatButton(name, state)
            end
        end)
        skillStates[name] = false
    else
        local btn = make("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -12, 0.5, 0),
            Size = UDim2.fromOffset(70, 26),
            BackgroundColor3 = colors.off,
        }, card)
        corner(btn, UDim.new(0, 6))
        make("TextLabel", {
            Text = "use",
            TextSize = 12,
            TextColor3 = colors.text,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.fromScale(1,1),
        }, btn)

        connect(btn.Activated, function()
            pcall(cfg.fn)
        end)
    end
    return card
end

--==============================================================
-- FLOATING BUTTONS (Mobile)
--==============================================================
local floatGui = make("ScreenGui", {
    Name = "DracoHubFloatingButtons",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 9999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local skillStates = {}
local floatButtons = {}

local function createFloatButton(name)
    if floatButtons[name] then return floatButtons[name] end

    local btn = make("TextButton", {
        Name = name,
        Size = UDim2.fromOffset(60, 60),
        Position = UDim2.fromOffset(100, 100 + (#floatButtons * 70)),
        BackgroundColor3 = Color3.fromRGB(40, 30, 60),
        BackgroundTransparency = 0.15,
        Visible = false,
        Text = name,
        TextSize = 11,
        TextColor3 = colors.text,
        TextScaled = true,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 100,
    }, floatGui)
    corner(btn, UDim.new(0, 8))
    stroke(btn, 0.85)

    -- draggable
    local dragging, dragStart, startPos
    connect(btn.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = btn.Position
        end
    end)
    connect(btn.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            btn.Position = UDim2.fromOffset(
                startPos.X.Offset + delta.X,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    local cfg = skills[name]
    if cfg then
        connect(btn.Activated, function()
            if cfg.toggle then
                local newState = not (skillStates[name] == true)
                skillStates[name] = newState
                pcall(cfg.fn, newState)
                btn.BackgroundColor3 = newState
                    and Color3.fromRGB(50, 110, 60)
                    or Color3.fromRGB(40, 30, 60)
                -- синхронизация со страницей skills
                syncPageToggle(name, newState)
            else
                pcall(cfg.fn)
            end
        end)
    end

    floatButtons[name] = btn
    return btn
end

function syncFloatButton(name, state)
    local btn = floatButtons[name]
    if btn then
        btn.BackgroundColor3 = state
            and Color3.fromRGB(50, 110, 60)
            or Color3.fromRGB(40, 30, 60)
    end
end

local pageToggleSyncers = {}
function syncPageToggle(name, state)
    if pageToggleSyncers[name] then
        pageToggleSyncers[name](state)
    end
end

-- Создаём кнопки для всех скиллов + строки на странице skills
for name, cfg in pairs(skills) do
    createFloatButton(name)
    local card = skillRow(name, cfg)
    -- сохраняем синхронизатор для тогглов
    if cfg.toggle then
        local track = card:FindFirstChildOfClass("Frame")
        local knob = track and track:FindFirstChildOfClass("Frame")
        if track and knob then
            pageToggleSyncers[name] = function(state)
                animate(track, {BackgroundColor3 = state and colors.on or colors.off})
                animate(knob, {Position = UDim2.new(0, state and 16 or 2, 0.5, 0)})
            end
        end
    end
end

--==============================================================
-- ВКЛАДКА MOBILE — управление плавающими кнопками
--==============================================================
local mobilePage = tabs[2].page
local mobileScroll = make("ScrollingFrame", {
    Size = UDim2.fromScale(1, 1),
    CanvasSize = UDim2.fromOffset(0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = colors.dim,
    ScrollingDirection = Enum.ScrollingDirection.Y,
}, mobilePage)
padding(mobileScroll, 10, 10, 10, 10)
make("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 6),
}, mobileScroll)

local sortedNames = {}
for name in pairs(skills) do table.insert(sortedNames, name) end
table.sort(sortedNames)

for _, name in ipairs(sortedNames) do
    local row = make("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Color3.new(1,1,1),
        BackgroundTransparency = 0.965,
        LayoutOrder = #mobileScroll:GetChildren(),
    }, mobileScroll)
    corner(row, UDim.new(0, 6))

    make("TextLabel", {
        Text = name,
        TextSize = 12,
        TextColor3 = colors.text,
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(0.7, -10, 1, 0),
    }, row)

    local track = make("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(28, 14),
        BackgroundColor3 = colors.off,
    }, row)
    corner(track, UDim.new(1,0))
    local knob = make("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 2, 0.5, 0),
        Size = UDim2.fromOffset(10, 10),
        BackgroundColor3 = colors.sub,
    }, track)
    corner(knob, UDim.new(1,0))

    local btn = make("TextButton", {Size = UDim2.fromScale(1,1), ZIndex = 5}, row)
    local visible = false
    connect(btn.Activated, function()
        visible = not visible
        local fb = floatButtons[name]
        if fb then fb.Visible = visible end
        animate(track, {BackgroundColor3 = visible and colors.on or colors.off})
        animate(knob, {Position = UDim2.new(0, visible and 14 or 2, 0.5, 0)})
    end)
end

--==============================================================
-- КНОПКИ PC (клавиши)
--==============================================================
connect(UserInputService.InputBegan, function(input, gpe)
    if gpe then return end
    if UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        window.Visible = not window.Visible
        return
    end
    for name, cfg in pairs(skills) do
        if cfg.key and input.KeyCode == Enum.KeyCode[cfg.key] then
            if cfg.toggle then
                local newState = not (skillStates[name] == true)
                skillStates[name] = newState
                pcall(cfg.fn, newState)
                syncFloatButton(name, newState)
                syncPageToggle(name, newState)
            else
                pcall(cfg.fn)
            end
            break
        end
    end
end)

--==============================================================
-- DRAG / RESIZE / LAYOUT
--==============================================================
local gesture
local safeOrigin = Vector2.zero
local safeSize = Vector2.new(780, 470)
local activeSlider
local uiState = {}

local function layoutSkills()
    -- карточки и так по UIListLayout
end

local function clampWindow()
    local size = window.AbsoluteSize
    local p = window.Position
    window.Position = UDim2.fromOffset(
        math.clamp(p.X.Offset, safeOrigin.X, safeOrigin.X + math.max(0, safeSize.X - size.X)),
        math.clamp(p.Y.Offset, safeOrigin.Y, safeOrigin.Y + math.max(0, safeSize.Y - size.Y))
    )
end

local function layoutNavigation()
    local width = window.Size.X.Offset
    local touch = UserInputService.TouchEnabled
    local narrow = width < 620
    local cellHeight = touch and 44 or 26

    local navHeight = narrow and (cellHeight * 2 + 8) or (cellHeight + 6)
    nav.Size = UDim2.fromOffset(narrow and (width - 20) or 0, navHeight)
    nav.AutomaticSize = narrow and Enum.AutomaticSize.None or Enum.AutomaticSize.X
    navCorner.CornerRadius = UDim.new(0, narrow and 12 or math.floor(navHeight / 2))
    body.Size = UDim2.new(1, 0, 1, -(41 + navHeight + 17))
    tabRow.Size = UDim2.fromOffset(narrow and (width - 26) or 0, navHeight - 6)
    tabRow.AutomaticSize = narrow and Enum.AutomaticSize.None or Enum.AutomaticSize.X

    local useGrid = navigationLayout:IsA("UIGridLayout")
    if narrow ~= useGrid then
        navigationLayout:Destroy()
        if narrow then
            navigationLayout = make("UIGridLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                FillDirection = Enum.FillDirection.Horizontal,
                FillDirectionMaxCells = 2,
            }, tabRow)
        else
            navigationLayout = rowLayout(tabRow, 2)
        end
    end

    if narrow then
        navigationLayout.CellPadding = UDim2.fromOffset(2, 2)
        navigationLayout.CellSize = UDim2.new(1/2, -2, 0, cellHeight)
    end

    for _, tab in ipairs(tabs) do
        tab.button.AutomaticSize = narrow and Enum.AutomaticSize.None or Enum.AutomaticSize.X
        tab.button.Size = UDim2.fromOffset(0, cellHeight)
    end

    highlight.Visible = not narrow
    for _, tab in ipairs(tabs) do
        tab.button.BackgroundColor3 = Color3.new(1,1,1)
        tab.button.BackgroundTransparency = narrow and tab == selected and 0.925 or 1
    end

    task.defer(updateHighlight)
end

local function fitScreen()
    gesture = nil
    watermark.Position = UDim2.new(1, 0, 0, 0)
    local viewport = gui.AbsoluteSize
    safeOrigin = Vector2.zero
    safeSize = Vector2.new(math.max(1, viewport.X), math.max(1, viewport.Y))

    local referenceScale = math.min(safeSize.X / 1568, safeSize.Y / 724)
    menuScale.Scale = (1076 / 780) * referenceScale
    window.Size = UDim2.fromOffset(780, 470)
    window.Position = UDim2.fromOffset(
        (safeSize.X - 1568 * referenceScale) / 2 + 224 * referenceScale,
        (safeSize.Y - 724 * referenceScale) / 2 + 14 * referenceScale
    )
    layoutNavigation()
end

connect(gui:GetPropertyChangedSignal("AbsoluteSize"), fitScreen)
connect(window:GetPropertyChangedSignal("Size"), layoutNavigation)
connect(UserInputService:GetPropertyChangedSignal("TouchEnabled"), layoutNavigation)
for _, tab in ipairs(tabs) do
    connect(tab.button.Activated, function() task.defer(layoutNavigation) end)
end

--==============================================================
-- INPUT GESTURES
--==============================================================
local function beginGesture(input, target, resize)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
    gesture = {
        input = input, target = target, resize = resize,
        origin = input.Position, position = target.Position,
        size = target.Size, scale = menuScale.Scale,
    }
end

dragHandle.ZIndex = 30
dragHandle.Active = true
connect(dragHandle.InputBegan, function(input)
    if not window.Visible then return end
    beginGesture(input, window, false)
end)
connect(grip.InputBegan, function(input)
    beginGesture(input, window, true)
end)

local function toggleMenu()
    window.Visible = not window.Visible
    gesture = nil
    if window.Visible then clampWindow() end
end
connect(watermark.Activated, toggleMenu)

connect(UserInputService.InputChanged, function(input)
    if not gesture then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input ~= gesture.input then return end
    local delta = input.Position - gesture.origin

    if gesture.resize then
        local maximum = math.max(0.01, math.min(safeSize.X / 780, safeSize.Y / 470))
        menuScale.Scale = math.clamp(
            gesture.scale + delta.X / 780,
            math.min(0.2, maximum),
            maximum
        )
        task.defer(updateHighlight)
    else
        local p = gesture.position
        gesture.target.Position = UDim2.new(
            p.X.Scale, p.X.Offset + delta.X,
            p.Y.Scale, p.Y.Offset + delta.Y
        )
    end
    clampWindow()
end)

connect(UserInputService.InputEnded, function(input)
    if gesture and input == gesture.input then
        gesture = nil
    end
end)
connect(UserInputService.WindowFocusReleased, function()
    gesture = nil
end)

--==============================================================
-- WATERMARK UPDATE
--==============================================================
local frames, elapsed = 0, 0
connect(RunService.Heartbeat, function(dt)
    frames = frames + 1
    elapsed = elapsed + dt
    if elapsed < 0.5 then return end
    values.FPS.Text = tostring(math.floor(frames / elapsed + 0.5))
    frames, elapsed = 0, 0

    local ok, ping = pcall(player.GetNetworkPing, player)
    values.Ping.Text = ok and (math.floor(ping * 1000 + 0.5) .. "ms") or "-"

    local mok, mem = pcall(Stats.GetTotalMemoryUsageMb, Stats)
    values.RAM.Text = mok and (math.floor(mem + 0.5) .. "mb") or "-"
    values.Time.Text = os.date("%H:%M")
end)

task.defer(fitScreen)
