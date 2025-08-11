-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

-- Carrega Rayfield UI
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source"))()

-- Variáveis globais para desenhos e highlights
local Drawings = {ESP = {}, Skeleton = {}}
local Highlights = {}

-- Configurações padrão (você pode modificar via UI)
local Settings = {
    Enabled = true,
    TracerESP = true,
    TracerThickness = 1,
    HealthESP = true,
    HealthStyle = "Both", -- "Both", "Text", "Bar", "None"
    HealthTextSuffix = " HP",
    NameESP = true,
    Snaplines = true,
    ChamsEnabled = true,
    ChamsFillColor = Color3.fromRGB(255, 0, 0),
    ChamsOutlineColor = Color3.fromRGB(0, 0, 0),
    ChamsTransparency = 0.5,
    ChamsOutlineTransparency = 0.5,
    SkeletonESP = true,
    SkeletonColor = Color3.fromRGB(0, 255, 0),
    SkeletonThickness = 1,
    SkeletonTransparency = 1,
    MaxDistance = 1000,
    TeamCheck = true,
    ShowTeam = false,
    RainbowEnabled = false,
    RainbowTracers = false,
    RainbowText = false,
    TracerOrigin = "Bottom" -- "Bottom", "Top", "Mouse", "Center"
}

local Colors = {
    Enemy = Color3.fromRGB(255, 0, 0),
    Ally = Color3.fromRGB(0, 255, 0),
    Health = Color3.fromRGB(0, 255, 0),
    Rainbow = Color3.fromHSV(0, 1, 1)
}

-- Função para criar os desenhos para um jogador
local function SetupESP(player)
    if Drawings.ESP[player] then return end

    -- Cria os desenhos (Tracer, HealthBar, Info, Snapline)
    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = Colors.Enemy
    tracer.Thickness = Settings.TracerThickness

    local healthBar = {
        Outline = Drawing.new("Square"),
        Fill = Drawing.new("Square"),
        Text = Drawing.new("Text")
    }
    for _, obj in pairs(healthBar) do
        obj.Visible = false
        if obj == healthBar.Fill then
            obj.Color = Colors.Health
            obj.Filled = true
        elseif obj == healthBar.Text then
            obj.Center = true
            obj.Size = 16
            obj.Color = Colors.Health
            obj.Font = Enum.Font.SourceSansBold
        end
    end

    local info = {
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text")
    }
    for _, text in pairs(info) do
        text.Visible = false
        text.Center = true
        text.Size = 16
        text.Color = Colors.Enemy
        text.Font = Enum.Font.SourceSansBold
        text.Outline = true
    end

    local snapline = Drawing.new("Line")
    snapline.Visible = false
    snapline.Color = Colors.Enemy
    snapline.Thickness = 1

    local highlight = Instance.new("Highlight")
    highlight.FillColor = Settings.ChamsFillColor
    highlight.OutlineColor = Settings.ChamsOutlineColor
    highlight.FillTransparency = Settings.ChamsTransparency
    highlight.OutlineTransparency = Settings.ChamsOutlineTransparency
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = Settings.ChamsEnabled
    Highlights[player] = highlight

    local skeleton = {
        Head = Drawing.new("Line"),
        Neck = Drawing.new("Line"),
        UpperSpine = Drawing.new("Line"),
        LowerSpine = Drawing.new("Line"),
        LeftShoulder = Drawing.new("Line"),
        LeftUpperArm = Drawing.new("Line"),
        LeftLowerArm = Drawing.new("Line"),
        LeftHand = Drawing.new("Line"),
        RightShoulder = Drawing.new("Line"),
        RightUpperArm = Drawing.new("Line"),
        RightLowerArm = Drawing.new("Line"),
        RightHand = Drawing.new("Line"),
        LeftHip = Drawing.new("Line"),
        LeftUpperLeg = Drawing.new("Line"),
        LeftLowerLeg = Drawing.new("Line"),
        LeftFoot = Drawing.new("Line"),
        RightHip = Drawing.new("Line"),
        RightUpperLeg = Drawing.new("Line"),
        RightLowerLeg = Drawing.new("Line"),
        RightFoot = Drawing.new("Line")
    }
    for _, line in pairs(skeleton) do
        line.Visible = false
        line.Color = Settings.SkeletonColor
        line.Thickness = Settings.SkeletonThickness
        line.Transparency = Settings.SkeletonTransparency
    end
    Drawings.Skeleton[player] = skeleton

    Drawings.ESP[player] = {
        Tracer = tracer,
        HealthBar = healthBar,
        Info = info,
        Snapline = snapline
    }
end

-- Função para remover todos desenhos de um jogador
local function RemoveESP(player)
    local esp = Drawings.ESP[player]
    if esp then
        esp.Tracer:Remove()
        for _, obj in pairs(esp.HealthBar) do obj:Remove() end
        for _, obj in pairs(esp.Info) do obj:Remove() end
        esp.Snapline:Remove()
        Drawings.ESP[player] = nil
    end

    local highlight = Highlights[player]
    if highlight then
        highlight:Destroy()
        Highlights[player] = nil
    end

    local skeleton = Drawings.Skeleton[player]
    if skeleton then
        for _, line in pairs(skeleton) do
            line:Remove()
        end
        Drawings.Skeleton[player] = nil
    end
end

-- Função para obter cor do jogador (com rainbow placeholder)
local function GetPlayerColor(player)
    if Settings.RainbowEnabled then
        -- Espaco para logica de rainbow
        return Colors.Rainbow
    end
    return player.Team == LocalPlayer.Team and Colors.Ally or Colors.Enemy
end

-- Função para obter origem do tracer
local function GetTracerOrigin()
    local origin = Settings.TracerOrigin
    if origin == "Bottom" then
        return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
    elseif origin == "Top" then
        return Vector2.new(Camera.ViewportSize.X/2, 0)
    elseif origin == "Mouse" then
        return UserInputService:GetMouseLocation()
    else
        return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    end
end

-- Atualiza o ESP (AQUI VOCÊ COLOCA SUA LÓGICA DENTRO)
local function UpdateESP(player)
    if not Settings.Enabled then return end
    local esp = Drawings.ESP[player]
    if not esp then return end

    local character = player.Character
    if not character then
        -- Esconde todos desenhos
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false

        local skeleton = Drawings.Skeleton[player]
        if skeleton then
            for _, line in pairs(skeleton) do line.Visible = false end
        end
        return
    end

    -- Verifique o HumanoidRootPart, humanoid, distance, time de forma básica (pode ajustar depois)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not rootPart or not humanoid or humanoid.Health <= 0 then
        -- Esconde todos desenhos
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        local skeleton = Drawings.Skeleton[player]
        if skeleton then
            for _, line in pairs(skeleton) do line.Visible = false end
        end
        return
    end

    local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
    if not onScreen or distance > Settings.MaxDistance then
        -- Esconde todos desenhos
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        return
    end

    if Settings.TeamCheck and player.Team == LocalPlayer.Team and not Settings.ShowTeam then
        -- Esconde para aliados
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        return
    end

    -- Pega a cor (você pode modificar essa função)
    local color = GetPlayerColor(player)

    -- ============================
--[[
  ESP System (sem todas as funções e variáveis relacionadas a Box)
  - Tracer
  - Healthbar
  - Name/Distance info
  - Snapline
  - Chams (Highlight)
  - Skeleton
  - Proper cleanup and disable logic
]]

Drawings = Drawings or {ESP = {}, Skeleton = {}}
Highlights = Highlights or {}

local function SetupESP(player)
    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = Colors.Enemy
    tracer.Thickness = Settings.TracerThickness

    local healthBar = {
        Outline = Drawing.new("Square"),
        Fill = Drawing.new("Square"),
        Text = Drawing.new("Text")
    }
    for _, obj in pairs(healthBar) do
        obj.Visible = false
        if obj == healthBar.Fill then
            obj.Color = Colors.Health
            obj.Filled = true
        elseif obj == healthBar.Text then
            obj.Center = true
            obj.Size = Settings.TextSize
            obj.Color = Colors.Health
            obj.Font = Settings.TextFont
        end
    end

    local info = {
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text")
    }
    for _, text in pairs(info) do
        text.Visible = false
        text.Center = true
        text.Size = Settings.TextSize
        text.Color = Colors.Enemy
        text.Font = Settings.TextFont
        text.Outline = true
    end

    local snapline = Drawing.new("Line")
    snapline.Visible = false
    snapline.Color = Colors.Enemy
    snapline.Thickness = 1

    local highlight = Instance.new("Highlight")
    highlight.FillColor = Settings.ChamsFillColor
    highlight.OutlineColor = Settings.ChamsOutlineColor
    highlight.FillTransparency = Settings.ChamsTransparency
    highlight.OutlineTransparency = Settings.ChamsOutlineTransparency
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = Settings.ChamsEnabled
    Highlights[player] = highlight

    local skeleton = {
        -- Spine & Head
        Head = Drawing.new("Line"),
        Neck = Drawing.new("Line"),
        UpperSpine = Drawing.new("Line"),
        LowerSpine = Drawing.new("Line"),
        -- Left Arm
        LeftShoulder = Drawing.new("Line"),
        LeftUpperArm = Drawing.new("Line"),
        LeftLowerArm = Drawing.new("Line"),
        LeftHand = Drawing.new("Line"),
        -- Right Arm
        RightShoulder = Drawing.new("Line"),
        RightUpperArm = Drawing.new("Line"),
        RightLowerArm = Drawing.new("Line"),
        RightHand = Drawing.new("Line"),
        -- Left Leg
        LeftHip = Drawing.new("Line"),
        LeftUpperLeg = Drawing.new("Line"),
        LeftLowerLeg = Drawing.new("Line"),
        LeftFoot = Drawing.new("Line"),
        -- Right Leg
        RightHip = Drawing.new("Line"),
        RightUpperLeg = Drawing.new("Line"),
        RightLowerLeg = Drawing.new("Line"),
        RightFoot = Drawing.new("Line")
    }
    for _, line in pairs(skeleton) do
        line.Visible = false
        line.Color = Settings.SkeletonColor
        line.Thickness = Settings.SkeletonThickness
        line.Transparency = Settings.SkeletonTransparency
    end
    Drawings.Skeleton[player] = skeleton

    Drawings.ESP[player] = {
        Tracer = tracer,
        HealthBar = healthBar,
        Info = info,
        Snapline = snapline
    }
end

local function RemoveESP(player)
    local esp = Drawings.ESP[player]
    if esp then
        esp.Tracer:Remove()
        for _, obj in pairs(esp.HealthBar) do obj:Remove() end
        for _, obj in pairs(esp.Info) do obj:Remove() end
        esp.Snapline:Remove()
        Drawings.ESP[player] = nil
    end
    local highlight = Highlights[player]
    if highlight then
        highlight:Destroy()
        Highlights[player] = nil
    end
    local skeleton = Drawings.Skeleton[player]
    if skeleton then
        for _, line in pairs(skeleton) do
            line:Remove()
        end
        Drawings.Skeleton[player] = nil
    end
end

local function GetPlayerColor(player)
    if Settings.RainbowEnabled then
        if Settings.RainbowTracers and Settings.TracerESP then return Colors.Rainbow end
        if Settings.RainbowText and (Settings.NameESP or Settings.HealthESP) then return Colors.Rainbow end
    end
    return player.Team == LocalPlayer.Team and Colors.Ally or Colors.Enemy
end

local function GetTracerOrigin()
    local origin = Settings.TracerOrigin
    if origin == "Bottom" then
        return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
    elseif origin == "Top" then
        return Vector2.new(Camera.ViewportSize.X/2, 0)
    elseif origin == "Mouse" then
        return UserInputService:GetMouseLocation()
    else
        return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    end
end

local function UpdateESP(player)
    if not Settings.Enabled then return end
    local esp = Drawings.ESP[player]
    if not esp then return end
    local character = player.Character
    if not character then
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        local skeleton = Drawings.Skeleton[player]
        if skeleton then for _, line in pairs(skeleton) do line.Visible = false end end
        return
    end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        local skeleton = Drawings.Skeleton[player]
        if skeleton then for _, line in pairs(skeleton) do line.Visible = false end end
        return
    end
    local _, isOnScreen = Camera:WorldToViewportPoint(rootPart.Position)
    if not isOnScreen then
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        local skeleton = Drawings.Skeleton[player]
        if skeleton then for _, line in pairs(skeleton) do line.Visible = false end end
        return
    end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        local skeleton = Drawings.Skeleton[player]
        if skeleton then for _, line in pairs(skeleton) do line.Visible = false end end
        return
    end
    local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
    if not onScreen or distance > Settings.MaxDistance then
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        return
    end
    if Settings.TeamCheck and player.Team == LocalPlayer.Team and not Settings.ShowTeam then
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        return
    end

    local color = GetPlayerColor(player)
    local size = character:GetExtentsSize()
    local cf = rootPart.CFrame
    local top, top_onscreen = Camera:WorldToViewportPoint(cf * CFrame.new(0, size.Y/2, 0).Position)
    local bottom, bottom_onscreen = Camera:WorldToViewportPoint(cf * CFrame.new(0, -size.Y/2, 0).Position)
    if not top_onscreen or not bottom_onscreen then return end
    local screenSize = bottom.Y - top.Y
    local boxWidth = screenSize * 0.65
    local boxPosition = Vector2.new(top.X - boxWidth/2, top.Y)
    -- local boxSize = Vector2.new(boxWidth, screenSize) -- Não usado sem box

    -- TRACER
    if Settings.TracerESP then
        esp.Tracer.From = GetTracerOrigin()
        esp.Tracer.To = Vector2.new(pos.X, pos.Y)
        esp.Tracer.Color = color
        esp.Tracer.Visible = true
    else
        esp.Tracer.Visible = false
    end

    -- HEALTHBAR
    if Settings.HealthESP then
        local health = humanoid.Health
        local maxHealth = humanoid.MaxHealth
        local healthPercent = health/maxHealth

        local barHeight = screenSize * 0.8
        local barWidth = 4
        local barPos = Vector2.new(
            boxPosition.X - barWidth - 2,
            boxPosition.Y + (screenSize - barHeight)/2
        )
        esp.HealthBar.Outline.Size = Vector2.new(barWidth, barHeight)
        esp.HealthBar.Outline.Position = barPos
        esp.HealthBar.Outline.Visible = true

        esp.HealthBar.Fill.Size = Vector2.new(barWidth - 2, barHeight * healthPercent)
        esp.HealthBar.Fill.Position = Vector2.new(barPos.X + 1, barPos.Y + barHeight * (1-healthPercent))
        esp.HealthBar.Fill.Color = Color3.fromRGB(255 - (255 * healthPercent), 255 * healthPercent, 0)
        esp.HealthBar.Fill.Visible = true

        if Settings.HealthStyle == "Both" or Settings.HealthStyle == "Text" then
            esp.HealthBar.Text.Text = math.floor(health) .. Settings.HealthTextSuffix
            esp.HealthBar.Text.Position = Vector2.new(barPos.X + barWidth + 2, barPos.Y + barHeight/2)
            esp.HealthBar.Text.Visible = true
        else
            esp.HealthBar.Text.Visible = false
        end
    else
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
    end

    -- NAME
    if Settings.NameESP then
        esp.Info.Name.Text = player.DisplayName
        esp.Info.Name.Position = Vector2.new(
            boxPosition.X + boxWidth/2,
            boxPosition.Y - 20
        )
        esp.Info.Name.Color = color
        esp.Info.Name.Visible = true
    else
        esp.Info.Name.Visible = false
    end

    -- SNAPLINE
    if Settings.Snaplines then
        esp.Snapline.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
        esp.Snapline.To = Vector2.new(pos.X, pos.Y)
        esp.Snapline.Color = color
        esp.Snapline.Visible = true
    else
        esp.Snapline.Visible = false
    end

    -- CHAMS
    local highlight = Highlights[player]
    if highlight then
        if Settings.ChamsEnabled and character then
            highlight.Parent = character
            highlight.FillColor = Settings.ChamsFillColor
            highlight.OutlineColor = Settings.ChamsOutlineColor
            highlight.FillTransparency = Settings.ChamsTransparency
            highlight.OutlineTransparency = Settings.ChamsOutlineTransparency
            highlight.Enabled = true
        else
            highlight.Enabled = false
        end
    end

    -- SKELETON
    if Settings.SkeletonESP then
        local function getBonePositions(character)
            if not character then return nil end
            local bones = {
                Head = character:FindFirstChild("Head"),
                UpperTorso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"),
                LowerTorso = character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso"),
                RootPart = character:FindFirstChild("HumanoidRootPart"),
                LeftUpperArm = character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm"),
                LeftLowerArm = character:FindFirstChild("LeftLowerArm") or character:FindFirstChild("Left Arm"),
                LeftHand = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm"),
                RightUpperArm = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm"),
                RightLowerArm = character:FindFirstChild("RightLowerArm") or character:FindFirstChild("Right Arm"),
                RightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"),
                LeftUpperLeg = character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg"),
                LeftLowerLeg = character:FindFirstChild("LeftLowerLeg") or character:FindFirstChild("Left Leg"),
                LeftFoot = character:FindFirstChild("LeftFoot") or character:FindFirstChild("Left Leg"),
                RightUpperLeg = character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg"),
                RightLowerLeg = character:FindFirstChild("RightLowerLeg") or character:FindFirstChild("Right Leg"),
                RightFoot = character:FindFirstChild("RightFoot") or character:FindFirstChild("Right Leg")
            }
            if not (bones.Head and bones.UpperTorso) then return nil end
            return bones
        end
        local function drawBone(from, to, line)
            if not from or not to then line.Visible = false return end
            local fromPos = (from.CFrame * CFrame.new(0, 0, 0)).Position
            local toPos = (to.CFrame * CFrame.new(0, 0, 0)).Position
            local fromScreen, fromVisible = Camera:WorldToViewportPoint(fromPos)
            local toScreen, toVisible = Camera:WorldToViewportPoint(toPos)
            if not (fromVisible and toVisible) or fromScreen.Z < 0 or toScreen.Z < 0 then
                line.Visible = false return
            end
            local screenBounds = Camera.ViewportSize
            if fromScreen.X < 0 or fromScreen.X > screenBounds.X or
               fromScreen.Y < 0 or fromScreen.Y > screenBounds.Y or
               toScreen.X < 0 or toScreen.X > screenBounds.X or
               toScreen.Y < 0 or toScreen.Y > screenBounds.Y then
                line.Visible = false
                return
            end
            line.From = Vector2.new(fromScreen.X, fromScreen.Y)
            line.To = Vector2.new(toScreen.X, toScreen.Y)
            line.Color = Settings.SkeletonColor
            line.Thickness = Settings.SkeletonThickness
            line.Transparency = Settings.SkeletonTransparency
            line.Visible = true
        end
        local bones = getBonePositions(character)
        if bones then
            local skeleton = Drawings.Skeleton[player]
            if skeleton then
                drawBone(bones.Head, bones.UpperTorso, skeleton.Head)
                drawBone(bones.UpperTorso, bones.LowerTorso, skeleton.UpperSpine)
                drawBone(bones.UpperTorso, bones.LeftUpperArm, skeleton.LeftShoulder)
                drawBone(bones.LeftUpperArm, bones.LeftLowerArm, skeleton.LeftUpperArm)
                drawBone(bones.LeftLowerArm, bones.LeftHand, skeleton.LeftLowerArm)
                drawBone(bones.UpperTorso, bones.RightUpperArm, skeleton.RightShoulder)
                drawBone(bones.RightUpperArm, bones.RightLowerArm, skeleton.RightUpperArm)
                drawBone(bones.RightLowerArm, bones.RightHand, skeleton.RightLowerArm)
                drawBone(bones.LowerTorso, bones.LeftUpperLeg, skeleton.LeftHip)
                drawBone(bones.LeftUpperLeg, bones.LeftLowerLeg, skeleton.LeftUpperLeg)
                drawBone(bones.LeftLowerLeg, bones.LeftFoot, skeleton.LeftLowerLeg)
                drawBone(bones.LowerTorso, bones.RightUpperLeg, skeleton.RightHip)
                drawBone(bones.RightUpperLeg, bones.RightLowerLeg, skeleton.RightUpperLeg)
                drawBone(bones.RightLowerLeg, bones.RightFoot, skeleton.RightLowerLeg)
            end
        end
    else
        local skeleton = Drawings.Skeleton[player]
        if skeleton then
            for _, line in pairs(skeleton) do line.Visible = false end
        end
    end
end

local function DisableESP()
    for _, player in ipairs(Players:GetPlayers()) do
        local esp = Drawings.ESP[player]
        if esp then
            esp.Tracer.Visible = false
            for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
            for _, obj in pairs(esp.Info) do obj.Visible = false end
            esp.Snapline.Visible = false
        end
        local skeleton = Drawings.Skeleton[player]
        if skeleton then
            for _, line in pairs(skeleton) do line.Visible = false end
        end
    end
end

local function CleanupESP()
    for _, player in ipairs(Players:GetPlayers()) do
        RemoveESP(player)
    end
    Drawings.ESP = {}
    Drawings.Skeleton = {}
    Highlights = {}
    end

end

-- Desabilita todo ESP
local function DisableESP()
    for _, player in ipairs(Players:GetPlayers()) do
        local esp = Drawings.ESP[player]
        if esp then
            esp.Tracer.Visible = false
            for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
            for _, obj in pairs(esp.Info) do obj.Visible = false end
            esp.Snapline.Visible = false
        end
        local skeleton = Drawings.Skeleton[player]
        if skeleton then
            for _, line in pairs(skeleton) do line.Visible = false end
        end
        local highlight = Highlights[player]
        if highlight then
            highlight.Enabled = false
        end
    end
end

-- Limpa tudo, remove desenhos e highlights
local function CleanupESP()
    for _, player in ipairs(Players:GetPlayers()) do
        RemoveESP(player)
    end
    Drawings.ESP = {}
    Drawings.Skeleton = {}
    Highlights = {}
end

-- Setup inicial para todos jogadores
for _, player in ipairs(Players:GetPlayers()) do
    SetupESP(player)
end

-- Conecta eventos de jogador para setup/remove ESP
Players.PlayerAdded:Connect(function(player)
    SetupESP(player)
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

-- Loop principal que atualiza o ESP
RunService.RenderStepped:Connect(function()
    if not Settings.Enabled then
        DisableESP()
        return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            UpdateESP(player)
        end
    end
end)

-- ============================
-- Rayfield UI para controle das configurações (você pode expandir conforme quiser)
local Window = Rayfield:CreateWindow({
    Name = "ESP Settings",
    LoadingTitle = "Carregando ESP...",
    LoadingSubtitle = "Por favor aguarde",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "MeuESP", 
        FileName = "Config"
    },
    Discord = {
        Enabled = false
    }
})

Window:CreateToggle({
    Name = "Ativar ESP",
    CurrentValue = Settings.Enabled,
    Flag = "Enabled",
    Callback = function(value)
        Settings.Enabled = value
        if not value then
            DisableESP()
        end
    end
})

Window:CreateToggle({
    Name = "Tracer ESP",
    CurrentValue = Settings.TracerESP,
    Flag = "TracerESP",
    Callback = function(value) Settings.TracerESP = value end
})

Window:CreateSlider({
    Name = "Espessura do Tracer",
    Min = 1,
    Max = 5,
    Default = Settings.TracerThickness,
    Flag = "TracerThickness",
    Callback = function(value) Settings.TracerThickness = value end
})

Window:CreateToggle({
    Name = "Health ESP",
    CurrentValue = Settings.HealthESP,
    Flag = "HealthESP",
    Callback = function(value) Settings.HealthESP = value end
})

Window:CreateToggle({
    Name = "Name ESP",
    CurrentValue = Settings.NameESP,
    Flag = "NameESP",
    Callback = function(value) Settings.NameESP = value end
})

Window:CreateToggle({
    Name = "Snaplines",
    CurrentValue = Settings.Snaplines,
    Flag = "Snaplines",
    Callback = function(value) Settings.Snaplines = value end
})

Window:CreateToggle({
    Name = "Chams (Highlight)",
    CurrentValue = Settings.ChamsEnabled,
    Flag = "ChamsEnabled",
    Callback = function(value) Settings.ChamsEnabled = value end
})

Window:CreateToggle({
    Name = "Skeleton ESP",
    CurrentValue = Settings.SkeletonESP,
    Flag = "SkeletonESP",
    Callback = function(value) Settings.SkeletonESP = value end
})

-- Você pode criar mais controles aqui conforme quiser
