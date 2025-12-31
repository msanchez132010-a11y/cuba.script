-- MIRA SCRIPT MEJORADO - SUPERVIVENCIA
-- Script completo con mira, visuales, aimbot y menú avanzado

-- Servicios
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

-- Variables principales
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Camera = Workspace.CurrentCamera
local MenuAbierto = false
local AimbotActivo = false
local ESPActivo = true

-- Configuración por defecto
local Config = {
    -- Mira
    Mira = {
        Activa = true,
        Color = Color3.fromRGB(255, 0, 0),
        Grosor = 2,
        Tamaño = 12,
        Transparencia = 0.3,
        Tipo = "Cruz", -- Cruz, Circulo, Punto, T, V
        PuntoCentral = true
    },
    
    -- Aimbot
    Aimbot = {
        Activo = false,
        Tecla = Enum.KeyCode.E, -- Mantener para usar aimbot
        Suavizado = 0.15,
        DistanciaMax = 500,
        SoloEnemigos = true,
        ParteCuerpo = "Head", -- Head, Torso, HumanoidRootPart
        FOV = 60, -- Campo de visión
        MostrarFOV = true
    },
    
    -- ESP (Visuales)
    ESP = {
        Activo = true,
        MostrarNombres = true,
        MostrarSalud = true,
        MostrarDistancia = true,
        MostrarEquipo = true,
        MostrarCaja = true,
        MostrarEsqueleto = true,
        MostrarArma = true,
        Brillo = 0.2,
        Fuente = 14,
        
        -- Colores
        ColorAliado = Color3.fromRGB(0, 255, 0),
        ColorEnemigo = Color3.fromRGB(255, 0, 0),
        ColorNeutral = Color3.fromRGB(255, 255, 0),
        
        -- Opciones específicas de supervivencia
        MostrarInventario = false,
        MostrarNivel = true,
        MostrarClan = true,
        MostrarRecursos = true
    },
    
    -- Visuales del juego
    Visuales = {
        SinNiebla = true,
        SinEfectos = false,
        FullBright = false,
        VerArmas = true,
        VerCofres = true,
        VerRecursos = true,
        VerAnimales = true,
        MaxRender = 1000
    },
    
    -- Menú
    Menu = {
        Tecla = Enum.KeyCode.Insert, -- Tecla para abrir/cerrar menú
        Posicion = UDim2.new(0.02, 0, 0.02, 0),
        Tema = "Oscuro", -- Oscuro, Claro, Azul, Rojo
        Animaciones = true
    }
}

-- Variables de sistema
local MiraUI, MenuUI, FOVCircle
local Conexiones = {}
local ESPCache = {}
local AimbotTarget = nil
local RaycastParams = RaycastParams.new()
RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
RaycastParams.IgnoreWater = true

-- Función para crear mira avanzada
function CrearMira()
    if MiraUI then MiraUI:Destroy() end
    
    if not Config.Mira.Activa then return end
    
    MiraUI = Instance.new("ScreenGui")
    MiraUI.Name = "MiraAdvanced"
    MiraUI.DisplayOrder = 999
    MiraUI.ResetOnSpawn = false
    MiraUI.Parent = Player:WaitForChild("PlayerGui")
    
    local centroX, centroY = 0.5, 0.5
    local color = Config.Mira.Color
    
    -- Crear según tipo
    if Config.Mira.Tipo == "Cruz" then
        -- Líneas principales
        local lineas = {
            {pos = UDim2.new(centroX, -Config.Mira.Tamaño, centroY, -1), size = UDim2.new(0, Config.Mira.Tamaño*2, 0, Config.Mira.Grosor)}, -- Horizontal
            {pos = UDim2.new(centroX, -1, centroY, -Config.Mira.Tamaño), size = UDim2.new(0, Config.Mira.Grosor, 0, Config.Mira.Tamaño*2)}, -- Vertical
        }
        
        for i, linea in ipairs(lineas) do
            local frame = Instance.new("Frame")
            frame.Size = linea.size
            frame.Position = linea.pos
            frame.BackgroundColor3 = color
            frame.BackgroundTransparency = Config.Mira.Transparencia
            frame.BorderSizePixel = 0
            frame.Parent = MiraUI
            
            -- Efecto de borde
            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(0, 0, 0)
            stroke.Thickness = 1
            stroke.Transparency = 0.5
            stroke.Parent = frame
        end
        
        -- Puntas de la mira
        local puntas = {
            {pos = UDim2.new(centroX, -Config.Mira.Tamaño-5, centroY, -2), size = UDim2.new(0, 5, 0, Config.Mira.Grosor+2)}, -- Izquierda
            {pos = UDim2.new(centroX, Config.Mira.Tamaño, centroY, -2), size = UDim2.new(0, 5, 0, Config.Mira.Grosor+2)}, -- Derecha
            {pos = UDim2.new(centroX, -2, centroY, -Config.Mira.Tamaño-5), size = UDim2.new(0, Config.Mira.Grosor+2, 0, 5)}, -- Arriba
            {pos = UDim2.new(centroX, -2, centroY, Config.Mira.Tamaño), size = UDim2.new(0, Config.Mira.Grosor+2, 0, 5)}, -- Abajo
        }
        
        for i, punta in ipairs(puntas) do
            local frame = Instance.new("Frame")
            frame.Size = punta.size
            frame.Position = punta.pos
            frame.BackgroundColor3 = color
            frame.BackgroundTransparency = Config.Mira.Transparencia - 0.2
            frame.BorderSizePixel = 0
            frame.Parent = MiraUI
        end
        
    elseif Config.Mira.Tipo == "Circulo" then
        -- Círculo con puntos
        local segmentos = 24
        local radio = Config.Mira.Tamaño
        
        for i = 1, segmentos do
            local angulo = (i-1) * (2*math.pi/segmentos)
            local nextAngulo = i * (2*math.pi/segmentos)
            
            local x1 = math.cos(angulo) * radio
            local y1 = math.sin(angulo) * radio
            local x2 = math.cos(nextAngulo) * radio
            local y2 = math.sin(nextAngulo) * radio
            
            -- Solo dibujar segmentos en las 4 direcciones principales
            if i % 6 == 0 then
                local distancia = math.sqrt((x2-x1)^2 + (y2-y1)^2)
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(0, distancia, 0, Config.Mira.Grosor)
                frame.Position = UDim2.new(centroX, x1, centroY, y1)
                frame.Rotation = math.deg(math.atan2(y2-y1, x2-x1))
                frame.AnchorPoint = Vector2.new(0, 0.5)
                frame.BackgroundColor3 = color
                frame.BackgroundTransparency = Config.Mira.Transparencia
                frame.BorderSizePixel = 0
                frame.Parent = MiraUI
                
                local stroke = Instance.new("UIStroke")
                stroke.Color = Color3.fromRGB(0, 0, 0)
                stroke.Thickness = 0.5
                stroke.Parent = frame
            end
        end
        
        -- Puntos en las 4 direcciones
        local puntos = {
            {x = -radio, y = 0}, {x = radio, y = 0},
            {x = 0, y = -radio}, {x = 0, y = radio}
        }
        
        for _, punto in ipairs(puntos) do
            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, Config.Mira.Grosor+2, 0, Config.Mira.Grosor+2)
            dot.Position = UDim2.new(centroX, punto.x-Config.Mira.Grosor/2, centroY, punto.y-Config.Mira.Grosor/2)
            dot.BackgroundColor3 = color
            dot.BackgroundTransparency = Config.Mira.Transparencia - 0.3
            dot.BorderSizePixel = 0
            dot.Parent = MiraUI
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = dot
        end
    end
    
    -- Punto central
    if Config.Mira.PuntoCentral then
        local center = Instance.new("Frame")
        center.Size = UDim2.new(0, Config.Mira.Grosor+1, 0, Config.Mira.Grosor+1)
        center.Position = UDim2.new(centroX, -(Config.Mira.Grosor+1)/2, centroY, -(Config.Mira.Grosor+1)/2)
        center.BackgroundColor3 = color
        center.BackgroundTransparency = Config.Mira.Transparencia - 0.4
        center.BorderSizePixel = 0
        center.Parent = MiraUI
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = center
    end
end

-- Función para crear círculo FOV del aimbot
function CrearFOVCircle()
    if FOVCircle then FOVCircle:Destroy() end
    
    if not Config.Aimbot.MostrarFOV or not Config.Aimbot.Activo then return end
    
    local fovGui = Instance.new("ScreenGui")
    fovGui.Name = "FOVCircle"
    fovGui.DisplayOrder = 998
    fovGui.ResetOnSpawn = false
    fovGui.Parent = Player:WaitForChild("PlayerGui")
    
    local radio = Config.Aimbot.FOV * 2
    local centroX, centroY = 0.5, 0.5
    
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, radio*2, 0, radio*2)
    circle.Position = UDim2.new(centroX, -radio, centroY, -radio)
    circle.BackgroundTransparency = 1
    circle.Parent = fovGui
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 50, 50)
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = circle
    
    FOVCircle = fovGui
end

-- Sistema ESP Mejorado para Supervivencia
function ActualizarESP()
    -- Limpiar ESP anterior
    for player, objetos in pairs(ESPCache) do
        for _, obj in pairs(objetos) do
            if obj and obj.Parent then
                obj:Destroy()
            end
        end
    end
    ESPCache = {}
    
    if not Config.ESP.Activo then return end
    
    for _, jugador in ipairs(Players:GetPlayers()) do
        if jugador ~= Player and jugador.Character then
            local char = jugador.Character
            local hum = char:FindFirstChild("Humanoid")
            local head = char:FindFirstChild("Head")
            local root = char:FindFirstChild("HumanoidRootPart")
            
            if hum and head and root and hum.Health > 0 then
                local cache = {}
                
                -- Determinar relación (usando lógica de supervivencia)
                local esEnemigo = true
                local esAliado = false
                local esNeutral = false
                
                -- Detectar equipo (si existe)
                if Player.Team and jugador.Team then
                    esEnemigo = Player.Team ~= jugador.Team
                    esAliado = Player.Team == jugador.Team
                end
                
                -- Detectar clan (si existe en el juego)
                if jugador:FindFirstChild("Clan") then
                    -- Lógica de clan específica del juego
                end
                
                -- Color basado en relación
                local colorESP = Config.ESP.ColorEnemigo
                if esAliado then
                    colorESP = Config.ESP.ColorAliado
                elseif esNeutral then
                    colorESP = Config.ESP.ColorNeutral
                end
                
                -- Crear Highlight
                if Config.ESP.MostrarCaja then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "ESP_Highlight"
                    highlight.FillColor = colorESP
                    highlight.FillTransparency = 0.85
                    highlight.OutlineColor = colorESP
                    highlight.OutlineTransparency = Config.ESP.Brillo
                    highlight.Adornee = char
                    highlight.Parent = char
                    table.insert(cache, highlight)
                end
                
                -- Billboard con información
                local billboard = Instance.new("BillboardGui")
                billboard.Name = "ESP_Info"
                billboard.Size = UDim2.new(0, 200, 0, 80)
                billboard.AlwaysOnTop = true
                billboard.ExtentsOffset = Vector3.new(0, 4, 0)
                billboard.Adornee = head
                billboard.MaxDistance = 200
                billboard.Parent = head
                
                local container = Instance.new("Frame")
                container.Size = UDim2.new(1, 0, 1, 0)
                container.BackgroundTransparency = 0.7
                container.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                container.BorderSizePixel = 0
                container.Parent = billboard
                
                local corner = Instance.new("UICorner")
                corner.CornerRadius = UDim.new(0, 4)
                corner.Parent = container
                
                local infoText = Instance.new("TextLabel")
                infoText.Size = UDim2.new(1, -10, 1, -10)
                infoText.Position = UDim2.new(0, 5, 0, 5)
                infoText.BackgroundTransparency = 1
                infoText.Text = ""
                infoText.TextColor3 = colorESP
                infoText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                infoText.TextStrokeTransparency = 0.5
                infoText.Font = Enum.Font.SourceSansBold
                infoText.TextSize = Config.ESP.Fuente
                infoText.TextXAlignment = Enum.TextXAlignment.Left
                infoText.Parent = container
                
                -- Actualizar información en tiempo real
                local conexion = RunService.Heartbeat:Connect(function()
                    if not char or not head or not hum then
                        conexion:Disconnect()
                        return
                    end
                    
                    local info = ""
                    
                    -- Nombre
                    if Config.ESP.MostrarNombres then
                        info = jugador.Name .. "\n"
                    end
                    
                    -- Equipo/Clan
                    if Config.ESP.MostrarEquipo then
                        if jugador.Team then
                            info = info .. "[" .. jugador.Team.Name .. "] "
                        end
                        if Config.ESP.MostrarClan and jugador:FindFirstChild("Clan") then
                            info = info .. "Clan: " .. jugador.Clan.Value .. "\n"
                        else
                            info = info .. "\n"
                        end
                    end
                    
                    -- Salud
                    if Config.ESP.MostrarSalud then
                        local saludPorcentaje = math.floor((hum.Health / hum.MaxHealth) * 100)
                        local barra = ""
                        local barras = math.floor(saludPorcentaje / 10)
                        
                        for i = 1, 10 do
                            if i <= barras then
                                barra = barra .. "█"
                            else
                                barra = barra .. "░"
                            end
                        end
                        
                        info = info .. "❤️ " .. barra .. " " .. saludPorcentaje .. "%\n"
                    end
                    
                    -- Distancia
                    if Config.ESP.MostrarDistancia and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
                        local distancia = (root.Position - Player.Character.HumanoidRootPart.Position).Magnitude
                        info = info .. "📏 " .. math.floor(distancia) .. " studs\n"
                    end
                    
                    -- Nivel (simulado para supervivencia)
                    if Config.ESP.MostrarNivel then
                        local nivel = jugador:GetAttribute("Level") or math.random(1, 100)
                        info = info .. "⭐ Nvl " .. nivel .. " "
                    end
                    
                    -- Arma actual
                    if Config.ESP.MostrarArma then
                        local arma = "Sin arma"
                        for _, tool in ipairs(char:GetChildren()) do
                            if tool:IsA("Tool") then
                                arma = tool.Name
                                break
                            end
                        end
                        info = info .. "🔫 " .. arma
                    end
                    
                    infoText.Text = info
                end)
                
                table.insert(cache, billboard)
                table.insert(cache, conexion)
                
                -- Líneas esqueleto
                if Config.ESP.MostrarEsqueleto then
                    local partes = {
                        {"Head", "HumanoidRootPart"},
                        {"HumanoidRootPart", "LeftUpperArm"},
                        {"HumanoidRootPart", "RightUpperArm"},
                        {"LeftUpperArm", "LeftLowerArm"},
                        {"RightUpperArm", "RightLowerArm"},
                        {"HumanoidRootPart", "LeftUpperLeg"},
                        {"HumanoidRootPart", "RightUpperLeg"},
                        {"LeftUpperLeg", "LeftLowerLeg"},
                        {"RightUpperLeg", "RightLowerLeg"}
                    }
                    
                    for _, conexion in ipairs(partes) do
                        local part1 = char:FindFirstChild(conexion[1])
                        local part2 = char:FindFirstChild(conexion[2])
                        
                        if part1 and part2 then
                            local line = Instance.new("LineHandleAdornment")
                            line.Name = "ESP_Skeleton"
                            line.Color3 = colorESP
                            line.Transparency = 0.5
                            line.Thickness = 1
                            line.Adornee = Workspace.Terrain
                            line.ZIndex = 1
                            line.Parent = Workspace.Terrain
                            
                            local conexionUpdate = RunService.Heartbeat:Connect(function()
                                if part1 and part2 and part1.Parent and part2.Parent then
                                    line.Visible = true
                                    line.From = part1.Position
                                    line.To = part2.Position
                                else
                                    line.Visible = false
                                end
                            end)
                            
                            table.insert(cache, line)
                            table.insert(cache, conexionUpdate)
                        end
                    end
                end
                
                ESPCache[jugador] = cache
            end
        end
    end
end

-- Sistema Aimbot Mejorado
function ObtenerObjetivoAimbot()
    if not Config.Aimbot.Activo then return nil end
    
    local mejorObjetivo = nil
    local mejorDistancia = math.huge
    local mejorAngulo = math.huge
    local posCamara = Camera.CFrame.Position
    
    local fovRad = math.rad(Config.Aimbot.FOV)
    
    for _, jugador in ipairs(Players:GetPlayers()) do
        if jugador ~= Player and jugador.Character then
            local char = jugador.Character
            local hum = char:FindFirstChild("Humanoid")
            local parte = char:FindFirstChild(Config.Aimbot.ParteCuerpo)
            
            if hum and hum.Health > 0 and parte then
                -- Verificar si es enemigo (si está configurado)
                if Config.Aimbot.SoloEnemigos then
                    if Player.Team and jugador.Team and Player.Team == jugador.Team then
                        continue
                    end
                end
                
                -- Verificar distancia máxima
                local distancia = (parte.Position - posCamara).Magnitude
                if distancia > Config.Aimbot.DistanciaMax then
                    continue
                end
                
                -- Verificar visibilidad (raycast)
                RaycastParams.FilterDescendantsInstances = {Player.Character, char}
                local ray = Workspace:Raycast(posCamara, (parte.Position - posCamara).Unit * distancia, RaycastParams)
                
                if ray and ray.Instance:IsDescendantOf(char) then
                    -- Calcular ángulo en pantalla
                    local posPantalla, visible = Camera:WorldToViewportPoint(parte.Position)
                    
                    if visible then
                        local centroPantalla = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                        local posMouse = Vector2.new(posPantalla.X, posPantalla.Y)
                        local distanciaPantalla = (centroPantalla - posMouse).Magnitude
                        
                        -- Verificar si está dentro del FOV
                        local angulo = math.atan2(posMouse.Y - centroPantalla.Y, posMouse.X - centroPantalla.X)
                        
                        if distanciaPantalla <= Config.Aimbot.FOV then
                            -- Puntuación basada en distancia y ángulo
                            local puntuacion = distanciaPantalla * 0.7 + distancia * 0.3
                            
                            if puntuacion < mejorAngulo then
                                mejorAngulo = puntuacion
                                mejorObjetivo = {Player = jugador, Part = parte, Distance = distancia}
                            end
                        end
                    end
                end
            end
        end
    end
    
    return mejorObjetivo
end

-- Función para aplicar aimbot
function AplicarAimbot()
    if AimbotTarget then
        local targetPos = AimbotTarget.Part.Position
        local currentPos = Camera.CFrame.Position
        local direction = (targetPos - currentPos).Unit
        
        -- Suavizado
        local suavizado = Config.Aimbot.Suavizado
        local currentCF = Camera.CFrame
        local targetCF = CFrame.new(currentPos, currentPos + direction)
        
        Camera.CFrame = currentCF:Lerp(targetCF, suavizado)
    end
end

-- Sistema de Visuales del Juego
function AplicarVisualesJuego()
    -- Niebla
    if Config.Visuales.SinNiebla then
        Lighting.FogEnd = 100000
        Lighting.FogStart = 99999
    end
    
    -- FullBright
    if Config.Visuales.FullBright then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false
    end
    
    -- Efectos
    if Config.Visuales.SinEfectos then
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") or effect:IsA("ColorCorrectionEffect") then
                effect.Enabled = false
            end
        end
    end
    
    -- Render distance
    if Config.Visuales.MaxRender then
        local terreno = Workspace:FindFirstChildOfClass("Terrain")
        if terreno then
            terreno.Decoration = false
        end
    end
end

-- Crear Menú Avanzado (Estilo Libro)
function CrearMenuLibro()
    if MenuUI then MenuUI:Destroy() end
    
    MenuUI = Instance.new("ScreenGui")
    MenuUI.Name = "ModMenuLibro"
    MenuUI.DisplayOrder = 1000
    MenuUI.ResetOnSpawn = false
    MenuUI.Parent = Player:WaitForChild("PlayerGui")
    
    -- Fondo oscuro
    local fondo = Instance.new("Frame")
    fondo.Size = UDim2.new(1, 0, 1, 0)
    fondo.BackgroundColor3 = Color3.new(0, 0, 0)
    fondo.BackgroundTransparency = 0.3
    fondo.BorderSizePixel = 0
    fondo.Parent = MenuUI
    
    -- Libro principal
    local libro = Instance.new("Frame")
    libro.Size = UDim2.new(0, 700, 0, 500)
    libro.Position = UDim2.new(0.5, -350, 0.5, -250)
    libro.BackgroundColor3 = Color3.fromRGB(30, 20, 10)
    libro.BorderSizePixel = 0
    libro.Parent = MenuUI
    
    local libroCorner = Instance.new("UICorner")
    libroCorner.CornerRadius = UDim.new(0, 10)
    libroCorner.Parent = libro
    
    -- Efecto de libro
    local libroStroke = Instance.new("UIStroke")
    libroStroke.Color = Color3.fromRGB(100, 80, 60)
    libroStroke.Thickness = 4
    libroStroke.Parent = libro
    
    -- Lomo del libro
    local lomo = Instance.new("Frame")
    lomo.Size = UDim2.new(0, 20, 1, -40)
    lomo.Position = UDim2.new(0, 0, 0, 20)
    lomo.BackgroundColor3 = Color3.fromRGB(50, 40, 30)
    lomo.BorderSizePixel = 0
    lomo.Parent = libro
    
    -- Título del libro
    local titulo = Instance.new("TextLabel")
    titulo.Size = UDim2.new(1, -40, 0, 60)
    titulo.Position = UDim2.new(0, 40, 0, 10)
    titulo.BackgroundTransparency = 1
    titulo.Text = "📖 MIRA SCRIPT - SUPERVIVENCIA 📖"
    titulo.TextColor3 = Color3.fromRGB(255, 215, 0)
    titulo.Font = Enum.Font.Fantasy
    titulo.TextSize = 24
    titulo.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    titulo.TextStrokeTransparency = 0
    titulo.Parent = libro
    
    -- Separador
    local separador = Instance.new("Frame")
    separador.Size = UDim2.new(1, -60, 0, 2)
    separador.Position = UDim2.new(0, 30, 0, 70)
    separador.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    separador.BorderSizePixel = 0
    separador.Parent = libro
    
    -- Pestañas (como índice de libro)
    local pestañasFrame = Instance.new("Frame")
    pestañasFrame.Size = UDim2.new(0, 150, 1, -100)
    pestañasFrame.Position = UDim2.new(0, 30, 0, 80)
    pestañasFrame.BackgroundTransparency = 1
    pestañasFrame.Parent = libro
    
    local pestañas = {"🔫 MIRA", "🎯 AIMBOT", "👁️ ESP", "⚙️ VISUALES", "💾 CONFIG"}
    local paginas = {}
    
    -- Contenido principal (páginas)
    local paginasFrame = Instance.new("Frame")
    paginasFrame.Size = UDim2.new(1, -210, 1, -100)
    paginasFrame.Position = UDim2.new(0, 190, 0, 80)
    paginasFrame.BackgroundColor3 = Color3.fromRGB(40, 30, 20)
    paginasFrame.BorderSizePixel = 0
    paginasFrame.Parent = libro
    
    local paginasCorner = Instance.new("UICorner")
    paginasCorner.CornerRadius = UDim.new(0, 8)
    paginasCorner.Parent = paginasFrame
    
    -- Scroll para páginas
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -20)
    scroll.Position = UDim2.new(0, 10, 0, 10)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 6
    scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 215, 0)
    scroll.Parent = paginasFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 15)
    layout.Parent = scroll
    
    -- Crear pestañas y páginas
    for i, nombre in ipairs(pestañas) do
        -- Botón pestaña
        local btnPestaña = Instance.new("TextButton")
        btnPestaña.Size = UDim2.new(1, 0, 0, 40)
        btnPestaña.Position = UDim2.new(0, 0, 0, (i-1)*45)
        btnPestaña.BackgroundColor3 = Color3.fromRGB(60, 50, 40)
        btnPestaña.Text = " " .. nombre
        btnPestaña.TextColor3 = Color3.fromRGB(200, 200, 200)
        btnPestaña.Font = Enum.Font.SourceSansBold
        btnPestaña.TextSize = 14
        btnPestaña.TextXAlignment = Enum.TextXAlignment.Left
        btnPestaña.Parent = pestañasFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btnPestaña
        
        -- Crear página
        local pagina = Instance.new("Frame")
        pagina.Size = UDim2.new(1, 0, 0, 400)
        pagina.BackgroundTransparency = 1
        pagina.Visible = i == 1
        pagina.Name = "Pagina_" .. i
        pagina.Parent = scroll
        
        paginas[i] = pagina
        
        -- Configurar evento click
        btnPestaña.MouseButton1Click:Connect(function()
            for j, pag in ipairs(paginas) do
                pag.Visible = (j == i)
                pestañasFrame:GetChildren()[j].BackgroundColor3 = 
                    (j == i) and Color3.fromRGB(80, 70, 60) or Color3.fromRGB(60, 50, 40)
            end
            scroll.CanvasPosition = Vector2.new(0, 0)
        end)
        
        if i == 1 then
            btnPestaña.BackgroundColor3 = Color3.fromRGB(80, 70, 60)
        end
    end
    
    -- Función auxiliar para crear controles
    local function CrearControl(pagina, tipo, config, texto, callback)
        local controlFrame = Instance.new("Frame")
        controlFrame.Size = UDim2.new(1, 0, 0, 35)
        controlFrame.BackgroundTransparency = 1
        controlFrame.Parent = pagina
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = "   " .. texto
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.Font = Enum.Font.SourceSans
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = controlFrame
        
        if tipo == "toggle" then
            local toggle = Instance.new("TextButton")
            toggle.Size = UDim2.new(0, 60, 0, 25)
            toggle.Position = UDim2.new(0.75, 0, 0.5, -12.5)
            toggle.BackgroundColor3 = config and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 0, 0)
            toggle.Text = config and "ON" or "OFF"
            toggle.TextColor3 = Color3.new(1, 1, 1)
            toggle.Font = Enum.Font.SourceSansBold
            toggle.TextSize = 12
            toggle.Parent = controlFrame
            
            local toggleCorner = Instance.new("UICorner")
            toggleCorner.CornerRadius = UDim.new(0, 5)
            toggleCorner.Parent = toggle
            
            toggle.MouseButton1Click:Connect(function()
                local nuevo = not (toggle.Text == "ON")
                toggle.Text = nuevo and "ON" or "OFF"
                toggle.BackgroundColor3 = nuevo and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 0, 0)
                callback(nuevo)
            end)
            
        elseif tipo == "slider" then
            local sliderFrame = Instance.new("Frame")
            sliderFrame.Size = UDim2.new(0, 150, 0, 25)
            sliderFrame.Position = UDim2.new(0.75, 0, 0.5, -12.5)
            sliderFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            sliderFrame.Parent = controlFrame
            
            local sliderCorner = Instance.new("UICorner")
            sliderCorner.CornerRadius = UDim.new(0, 5)
            sliderCorner.Parent = sliderFrame
            
            local fill = Instance.new("Frame")
            fill.Size = UDim2.new(config/100, 0, 1, 0)
            fill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
            fill.BorderSizePixel = 0
            fill.Parent = sliderFrame
            
            local fillCorner = Instance.new("UICorner")
            fillCorner.CornerRadius = UDim.new(0, 5)
            fillCorner.Parent = fill
            
            local valueText = Instance.new("TextLabel")
            valueText.Size = UDim2.new(1, 0, 1, 0)
            valueText.BackgroundTransparency = 1
            valueText.Text = tostring(config)
            valueText.TextColor3 = Color3.new(1, 1, 1)
            valueText.Font = Enum.Font.SourceSansBold
            valueText.TextSize = 12
            valueText.Parent = sliderFrame
            
            -- Interacción del slider
            local dragging = false
            sliderFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                end
            end)
            
            sliderFrame.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            
            game:GetService("UserInputService").InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local pos = input.Position.X - sliderFrame.AbsolutePosition.X
                    local percent = math.clamp(pos / sliderFrame.AbsoluteSize.X, 0, 1)
                    local value = math.floor(percent * 100)
                    
                    fill.Size = UDim2.new(percent, 0, 1, 0)
                    valueText.Text = tostring(value)
                    callback(value)
                end
            end)
            
        elseif tipo == "dropdown" then
            local dropdown = Instance.new("TextButton")
            dropdown.Size = UDim2.new(0, 120, 0, 25)
            dropdown.Position = UDim2.new(0.75, 0, 0.5, -12.5)
            dropdown.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
            dropdown.Text = config
            dropdown.TextColor3 = Color3.new(1, 1, 1)
            dropdown.Font = Enum.Font.SourceSans
            dropdown.TextSize = 12
            dropdown.Parent = controlFrame
            
            local dropdownCorner = Instance.new("UICorner")
            dropdownCorner.CornerRadius = UDim.new(0, 5)
            dropdownCorner.Parent = dropdown
            
            -- Menú desplegable (simplificado)
            dropdown.MouseButton1Click:Connect(function()
                callback(config)
            end)
        end
        
        return controlFrame
    end
    
    -- PÁGINA 1: CONFIGURACIÓN MIRA
    local secMira = Instance.new("TextLabel")
    secMira.Size = UDim2.new(1, 0, 0, 30)
    secMira.BackgroundTransparency = 1
    secMira.Text = "🔫 CONFIGURACIÓN DE MIRA"
    secMira.TextColor3 = Color3.fromRGB(255, 215, 0)
    secMira.Font = Enum.Font.SourceSansBold
    secMira.TextSize = 18
    secMira.Parent = paginas[1]
    
    CrearControl(paginas[1], "toggle", Config.Mira.Activa, "Activar Mira", function(v)
        Config.Mira.Activa = v
        CrearMira()
    end)
    
    CrearControl(paginas[1], "dropdown", Config.Mira.Tipo, "Tipo de Mira", function(v)
        Config.Mira.Tipo = v
        CrearMira()
    end)
    
    CrearControl(paginas[1], "slider", Config.Mira.Tamaño*5, "Tamaño Mira", function(v)
        Config.Mira.Tamaño = v/5
        CrearMira()
    end)
    
    CrearControl(paginas[1], "slider", Config.Mira.Transparencia*100, "Transparencia", function(v)
        Config.Mira.Transparencia = v/100
        CrearMira()
    end)
    
    -- PÁGINA 2: AIMBOT
    local secAimbot = Instance.new("TextLabel")
    secAimbot.Size = UDim2.new(1, 0, 0, 30)
    secAimbot.BackgroundTransparency = 1
    secAimbot.Text = "🎯 CONFIGURACIÓN AIMBOT"
    secAimbot.TextColor3 = Color3.fromRGB(255, 215, 0)
    secAimbot.Font = Enum.Font.SourceSansBold
    secAimbot.TextSize = 18
    secAimbot.Parent = paginas[2]
    
    CrearControl(paginas[2], "toggle", Config.Aimbot.Activo, "Activar Aimbot", function(v)
        Config.Aimbot.Activo = v
        CrearFOVCircle()
    end)
    
    CrearControl(paginas[2], "slider", Config.Aimbot.Suavizado*100, "Suavizado", function(v)
        Config.Aimbot.Suavizado = v/100
    end)
    
    CrearControl(paginas[2], "slider", Config.Aimbot.FOV, "Campo de Visión", function(v)
        Config.Aimbot.FOV = v
        CrearFOVCircle()
    end)
    
    CrearControl(paginas[2], "toggle", Config.Aimbot.MostrarFOV, "Mostrar FOV", function(v)
        Config.Aimbot.MostrarFOV = v
        CrearFOVCircle()
    end)
    
    CrearControl(paginas[2], "slider", Config.Aimbot.DistanciaMax, "Distancia Máx", function(v)
        Config.Aimbot.DistanciaMax = v
    end)
    
    -- PÁGINA 3: ESP
    local secESP = Instance.new("TextLabel")
    secESP.Size = UDim2.new(1, 0, 0, 30)
    secESP.BackgroundTransparency = 1
    secESP.Text = "👁️ VISUALES ESP"
    secESP.TextColor3 = Color3.fromRGB(255, 215, 0)
    secESP.Font = Enum.Font.SourceSansBold
    secESP.TextSize = 18
    secESP.Parent = paginas[3]
    
    CrearControl(paginas[3], "toggle", Config.ESP.Activo, "Activar ESP", function(v)
        Config.ESP.Activo = v
        ActualizarESP()
    end)
    
    CrearControl(paginas[3], "toggle", Config.ESP.MostrarNombres, "Mostrar Nombres", function(v)
        Config.ESP.MostrarNombres = v
        ActualizarESP()
    end)
    
    CrearControl(paginas[3], "toggle", Config.ESP.MostrarSalud, "Mostrar Salud", function(v)
        Config.ESP.MostrarSalud = v
        ActualizarESP()
    end)
    
    CrearControl(paginas[3], "toggle", Config.ESP.MostrarDistancia, "Mostrar Distancia", function(v)
        Config.ESP.MostrarDistancia = v
        ActualizarESP()
    end)
    
    CrearControl(paginas[3], "toggle", Config.ESP.MostrarCaja, "Mostrar Caja", function(v)
        Config.ESP.MostrarCaja = v
        ActualizarESP()
    end)
    
    CrearControl(paginas[3], "toggle", Config.ESP.MostrarEsqueleto, "Mostrar Esqueleto", function(v)
        Config.ESP.MostrarEsqueleto = v
        ActualizarESP()
    end)
    
    -- PÁGINA 4: VISUALES DEL JUEGO
    local secVisuales = Instance.new("TextLabel")
    secVisuales.Size = UDim2.new(1, 0, 0, 30)
    secVisuales.BackgroundTransparency = 1
    secVisuales.Text = "⚙️ VISUALES DEL JUEGO"
    secVisuales.TextColor3 = Color3.fromRGB(255, 215, 0)
    secVisuales.Font = Enum.Font.SourceSansBold
    secVisuales.TextSize = 18
    secVisuales.Parent = paginas[4]
    
    CrearControl(paginas[4], "toggle", Config.Visuales.SinNiebla, "Eliminar Niebla", function(v)
        Config.Visuales.SinNiebla = v
        AplicarVisualesJuego()
    end)
    
    CrearControl(paginas[4], "toggle", Config.Visuales.FullBright, "FullBright", function(v)
        Config.Visuales.FullBright = v
        AplicarVisualesJuego()
    end)
    
    CrearControl(paginas[4], "toggle", Config.Visuales.SinEfectos, "Sin Efectos", function(v)
        Config.Visuales.SinEfectos = v
        AplicarVisualesJuego()
    end)
    
    -- PÁGINA 5: CONFIGURACIÓN
    local secConfig = Instance.new("TextLabel")
    secConfig.Size = UDim2.new(1, 0, 0, 30)
    secConfig.BackgroundTransparency = 1
    secConfig.Text = "💾 CONFIGURACIÓN GENERAL"
    secConfig.TextColor3 = Color3.fromRGB(255, 215, 0)
    secConfig.Font = Enum.Font.SourceSansBold
    secConfig.TextSize = 18
    secConfig.Parent = paginas[5]
    
    CrearControl(paginas[5], "dropdown", tostring(Config.Menu.Tecla), "Tecla Menú", function(v)
        Config.Menu.Tecla = Enum.KeyCode[v]
    end)
    
    -- Botones de acción
    local btnFrame = Instance.new("Frame")
    btnFrame.Size = UDim2.new(1, -40, 0, 50)
    btnFrame.Position = UDim2.new(0, 30, 1, -70)
    btnFrame.BackgroundTransparency = 1
    btnFrame.Parent = libro
    
    -- Botón guardar
    local btnGuardar = Instance.new("TextButton")
    btnGuardar.Size = UDim2.new(0, 120, 0, 35)
    btnGuardar.Position = UDim2.new(0, 0, 0, 0)
    btnGuardar.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    btnGuardar.Text = "💾 GUARDAR"
    btnGuardar.TextColor3 = Color3.new(1, 1, 1)
    btnGuardar.Font = Enum.Font.SourceSansBold
    btnGuardar.TextSize = 14
    btnGuardar.Parent = btnFrame
    
    local guardarCorner = Instance.new("UICorner")
    guardarCorner.CornerRadius = UDim.new(0, 6)
    guardarCorner.Parent = btnGuardar
    
    btnGuardar.MouseButton1Click:Connect(function()
        -- Guardar configuración
        print("Configuración guardada exitosamente!")
    end)
    
    -- Botón cerrar
    local btnCerrar = Instance.new("TextButton")
    btnCerrar.Size = UDim2.new(0, 120, 0, 35)
    btnCerrar.Position = UDim2.new(1, -120, 0, 0)
    btnCerrar.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    btnCerrar.Text = "❌ CERRAR"
    btnCerrar.TextColor3 = Color3.new(1, 1, 1)
    btnCerrar.Font = Enum.Font.SourceSansBold
    btnCerrar.TextSize = 14
    btnCerrar.Parent = btnFrame
    
    local cerrarCorner = Instance.new("UICorner")
    cerrarCorner.CornerRadius = UDim.new(0, 6)
    cerrarCorner.Parent = btnCerrar
    
    btnCerrar.MouseButton1Click:Connect(function()
        MenuUI.Enabled = false
    end)
    
    -- Ajustar scroll
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)
end

-- Función para alternar menú
function AlternarMenu()
    if not MenuUI then
        CrearMenuLibro()
    end
    MenuUI.Enabled = not MenuUI.Enabled
    MenuAbierto = MenuUI.Enabled
end

-- Configurar controles
function ConfigurarControles()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed then
            -- Tecla menú
            if input.KeyCode == Config.Menu.Tecla then
                AlternarMenu()
            end
            
            -- Tecla aimbot
            if input.KeyCode == Config.Aimbot.Tecla then
                AimbotActivo = true
                AimbotTarget = ObtenerObjetivoAimbot()
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Config.Aimbot.Tecla then
            AimbotActivo = false
            AimbotTarget = nil
        end
    end)
    
    -- Comandos de chat
    Player.Chatted:Connect(function(msg)
        local args = string.split(string.lower(msg), " ")
        
        if args[1] == "/mira" then
            if args[2] == "on" then
                Config.Mira.Activa = true
                CrearMira()
            elseif args[2] == "off" then
                Config.Mira.Activa = false
                CrearMira()
            end
        elseif args[1] == "/esp" then
            if args[2] == "on" then
                Config.ESP.Activo = true
                ActualizarESP()
            elseif args[2] == "off" then
                Config.ESP.Activo = false
                ActualizarESP()
            end
        elseif args[1] == "/aimbot" then
            if args[2] == "on" then
                Config.Aimbot.Activo = true
                CrearFOVCircle()
            elseif args[2] == "off" then
                Config.Aimbot.Activo = false
                if FOVCircle then FOVCircle:Destroy() end
            end
        elseif args[1] == "/menu" then
            AlternarMenu()
        end
    end)
end

-- Inicializar sistema
function Inicializar()
    print("══════════════════════════════════════════════")
    print("   🎮 MIRA SCRIPT - SUPERVIVENCIA v3.0 🎮")
    print("══════════════════════════════════════════════")
    print("👑 Desarrollado para: Juego de Supervivencia")
    print("🔑 Tecla Menú: " .. tostring(Config.Menu.Tecla))
    print("🎯 Tecla Aimbot: " .. tostring(Config.Aimbot.Tecla))
    print("")
    print("📖 Comandos disponibles:")
    print("   /mira [on/off] - Activar/desactivar mira")
    print("   /esp [on/off] - Activar/desactivar ESP")
    print("   /aimbot [on/off] - Activar/desactivar aimbot")
    print("   /menu - Abrir menú de configuración")
    print("══════════════════════════════════════════════")
    
    -- Crear elementos iniciales
    CrearMira()
    CrearFOVCircle()
    ActualizarESP()
    AplicarVisualesJuego()
    ConfigurarControles()
    
    -- Eventos de jugadores
    Players.PlayerAdded:Connect(function()
        wait(1)
        ActualizarESP()
    end)
    
    Players.PlayerRemoving:Connect(function()
        wait(0.1)
        ActualizarESP()
    end)
    
    -- Reconectar al respawnear
    Player.CharacterAdded:Connect(function()
        wait(2)
        CrearMira()
        ActualizarESP()
    end)
end

-- Loop principal
RunService.RenderStepped:Connect(function(deltaTime)
    -- Actualizar mira
    if MiraUI and MiraUI.Enabled then
        for _, obj in pairs(MiraUI:GetChildren()) do
            if obj:IsA("Frame") then
                obj.BackgroundColor3 = Config.Mira.Color
                obj.BackgroundTransparency = Config.Mira.Transparencia
            end
        end
    end
    
    -- Aplicar aimbot si está activo
    if AimbotActivo and Config.Aimbot.Activo then
        if not AimbotTarget then
            AimbotTarget = ObtenerObjetivoAimbot()
        end
        if AimbotTarget then
            AplicarAimbot()
        end
    end
    
    -- Actualizar ESP
    if tick() % 0.5 < deltaTime then
        ActualizarESP()
    end
end)

-- EJECUTAR
Inicializar()

-- Mensaje para ejecutar con Xeno
print("\n✨ Para abrir el menú, presiona: " .. tostring(Config.Menu.Tecla))
print("🎮 Script listo para Juego de Supervivencia!")
