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
