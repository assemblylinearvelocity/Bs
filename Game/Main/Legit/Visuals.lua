-- Game/Main/Legit/Visuals.lua
-- ESP drawing logic. Reads from Library.Toggles / Library.Options.

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local Toggles = Library.Toggles
local Options  = Library.Options

-- ───────────────────────────────────────────────
--  Character folders
-- ───────────────────────────────────────────────

local Characters = workspace:WaitForChild("Characters")
local CTFolder   = Characters:WaitForChild("Counter-Terrorists")
local TFolder    = Characters:WaitForChild("Terrorists")

-- ───────────────────────────────────────────────
--  Team detection
-- ───────────────────────────────────────────────

local function GetLocalTeam()
    local char = LocalPlayer.Character
    if not char then return nil end
    if char:IsDescendantOf(CTFolder) then return "CT" end
    if char:IsDescendantOf(TFolder)  then return "T"  end
    return nil
end

local function GetEnemyFolder()
    local team = GetLocalTeam()
    if team == "CT" then return TFolder  end
    if team == "T"  then return CTFolder end
    return nil
end

-- ───────────────────────────────────────────────
--  ESP drawings
-- ───────────────────────────────────────────────

local ESP    = {}
local Camera = workspace.CurrentCamera

local function RemoveESP(char)
    if not ESP[char] then return end
    for _, d in pairs(ESP[char]) do
        pcall(function() d:Remove() end)
    end
    ESP[char] = nil
end

local function CreateESP(char)
    RemoveESP(char)
    local d = {}

    -- Box
    local box        = Drawing.new("Square")
    box.Visible      = false
    box.Thickness    = 1
    box.Filled       = false
    box.Color        = Options.ESPColor.Value
    d.Box            = box

    -- Name
    local name       = Drawing.new("Text")
    name.Visible     = false
    name.Size        = 13
    name.Center      = true
    name.Outline     = true
    name.Color       = Options.ESPColor.Value
    d.Name           = name

    -- Health bar background
    local hpBg       = Drawing.new("Square")
    hpBg.Visible     = false
    hpBg.Thickness   = 1
    hpBg.Filled      = true
    hpBg.Color       = Color3.fromRGB(0, 0, 0)
    d.HPBg           = hpBg

    -- Health bar fill
    local hpBar      = Drawing.new("Square")
    hpBar.Visible    = false
    hpBar.Thickness  = 1
    hpBar.Filled     = true
    hpBar.Color      = Color3.fromRGB(0, 255, 0)
    d.HPBar          = hpBar

    -- Distance
    local dist       = Drawing.new("Text")
    dist.Visible     = false
    dist.Size        = 11
    dist.Center      = true
    dist.Outline     = true
    dist.Color       = Color3.fromRGB(255, 255, 255)
    d.Dist           = dist

    ESP[char] = d
end

-- ───────────────────────────────────────────────
--  Helpers
-- ───────────────────────────────────────────────

local function GetHealth(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return 0, 100 end
    return hum.Health, hum.MaxHealth
end

local function W2V(pos)
    local sp, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), onScreen
end

local function GetBoundingBox(char)
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not root then return nil end

    local pos         = root.Position
    local top2D, topOn = W2V(pos + Vector3.new(0,  3.2, 0))
    local bot2D, botOn = W2V(pos + Vector3.new(0, -3.2, 0))
    if not topOn and not botOn then return nil end

    local height  = math.abs(bot2D.Y - top2D.Y)
    local width   = height * 0.5
    local topLeft = Vector2.new(top2D.X - width / 2, top2D.Y)

    return topLeft, width, height, top2D, bot2D
end

-- ───────────────────────────────────────────────
--  Render loop
-- ───────────────────────────────────────────────

RunService.RenderStepped:Connect(function()
    local espOn     = Toggles.ESPEnabled.Value
    local boxOn     = Toggles.ESPBoxes.Value
    local namesOn   = Toggles.ESPNames.Value
    local healthOn  = Toggles.ESPHealth.Value
    local distOn    = Toggles.ESPDistance.Value
    local teamCheck = Toggles.ESPTeamCheck.Value
    local maxDist   = Options.ESPMaxDistance.Value
    local espColor  = Options.ESPColor.Value

    local targets = {}

    if espOn then
        local foldersToScan = {}

        if teamCheck then
            local ef = GetEnemyFolder()
            if ef then table.insert(foldersToScan, ef) end
        else
            table.insert(foldersToScan, CTFolder)
            table.insert(foldersToScan, TFolder)
        end

        for _, folder in ipairs(foldersToScan) do
            for _, char in ipairs(folder:GetChildren()) do
                if char ~= LocalPlayer.Character then
                    table.insert(targets, char)
                end
            end
        end
    end

    -- Clean up stale drawings
    for char in pairs(ESP) do
        if not table.find(targets, char) then
            RemoveESP(char)
        end
    end

    for _, char in ipairs(targets) do
        local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
        if not root then RemoveESP(char); continue end

        local dist = (Camera.CFrame.Position - root.Position).Magnitude
        if dist > maxDist then RemoveESP(char); continue end

        if not ESP[char] then CreateESP(char) end
        local d = ESP[char]

        local topLeft, width, height, top2D, bot2D = GetBoundingBox(char)
        local visible = topLeft ~= nil

        d.Box.Color  = espColor
        d.Name.Color = espColor

        -- Box
        if boxOn and visible then
            d.Box.Position = topLeft
            d.Box.Size     = Vector2.new(width, height)
            d.Box.Visible  = true
        else
            d.Box.Visible = false
        end

        -- Name
        if namesOn and visible then
            d.Name.Text     = char.Name
            d.Name.Position = Vector2.new(top2D.X, top2D.Y - 16)
            d.Name.Visible  = true
        else
            d.Name.Visible = false
        end

        -- Health bar
        if healthOn and visible then
            local hp, maxHp = GetHealth(char)
            local ratio     = math.clamp(hp / maxHp, 0, 1)
            local barX      = topLeft.X - 6

            d.HPBg.Position  = Vector2.new(barX - 1, top2D.Y - 1)
            d.HPBg.Size      = Vector2.new(4, height + 2)
            d.HPBg.Visible   = true

            d.HPBar.Position = Vector2.new(barX, top2D.Y + height * (1 - ratio))
            d.HPBar.Size     = Vector2.new(2, height * ratio)
            d.HPBar.Color    = Color3.fromRGB(
                math.floor(255 * (1 - ratio)),
                math.floor(255 * ratio),
                0
            )
            d.HPBar.Visible  = true
        else
            d.HPBg.Visible  = false
            d.HPBar.Visible = false
        end

        -- Distance
        if distOn and visible then
            d.Dist.Text     = string.format("%d st", math.floor(dist))
            d.Dist.Position = Vector2.new(bot2D.X, bot2D.Y + 4)
            d.Dist.Visible  = true
        else
            d.Dist.Visible = false
        end
    end
end)

-- ───────────────────────────────────────────────
--  Cleanup
-- ───────────────────────────────────────────────

Library:GiveSignal(Library.ScreenGui.AncestryChanged:Connect(function()
    for char in pairs(ESP) do RemoveESP(char) end
end))
