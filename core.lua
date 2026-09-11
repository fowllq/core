-- ============================================================================
-- PREFERRED ULTIMATE HVH FRAMEWORK CORE v14.1 BY @FOWLLQ (SYNTAX FIXED) - PART 1
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Core = {
    Active = true,
    Version = "14.1.0",
    WebhookURL = "ТВОЙ_ДИСКОРД_ВЕБХУК_СЮДА",
    Config = {
        Esp = false,
        Speed = false,
        SpeedValue = 45,
        InfJump = false,
        Noclip = false,
        Fly = false,
        EmoteFling = false,
        antiFallEnabled = true
    },
    Connections = {},
    Physics = { bVelocity = nil, bGyro = nil },
    Track = nil,
    EmoteData = {
        AnimId = "133566007754001",
        Flip = 1
    }
}

local function SecureEnvironment()
    pcall(function()
        if getgenv and getgenv().getgc then hookfunction(getgenv().getgc, function() return {} end) end
        if debug and debug.getregistry then hookfunction(debug.getregistry, function() return {} end) end
    end)
end

function Core:SendLog()
    if self.WebhookURL == "ТВОЙ_ДИСКОРД_ВЕБХУК_СЮДА" or not request then return end
    task.spawn(function()
        local executor = (identifyexecutor and identifyexecutor()) or "Unknown Executor"
        local data = {["embeds"] = {{["title"] = "🚀 Core v14.1 Запущен!", ["color"] = 16737280, ["fields"] = {
            {["name"] = "Игрок", ["value"] = LocalPlayer.Name, ["inline"] = true},
            {["name"] = "Игра ID", ["value"] = tostring(game.PlaceId), ["inline"] = true},
            {["name"] = "Инжектор", ["value"] = tostring(executor), ["inline"] = true}
        }}}}
        pcall(function() request({Url = self.WebhookURL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(data)}) end)
    end)
end

local function applyHighlight(player, char)
    if player == LocalPlayer then return end
    local highlight = char:FindFirstChild("HvH_Core_Highlight") or Instance.new("Highlight")
    highlight.Name = "HvH_Core_Highlight"
    highlight.FillColor = Color3.fromRGB(255, 0, 80)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = char

    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not char or not char:IsDescendantOf(Workspace) then highlight:Destroy() conn:Disconnect() return end
        highlight.Enabled = Core.Config.Esp
    end)
end

function Core:InitESP()
    local function monitorPlayer(player)
        if player == LocalPlayer then return end
        if player.Character then task.spawn(applyHighlight, player, player.Character) end
        player.CharacterAdded:Connect(function(char) task.spawn(applyHighlight, player, char) end)
    end
    for _, p in ipairs(Players:GetPlayers()) do monitorPlayer(p) end
    table.insert(Core.Connections, Players.PlayerAdded:Connect(monitorPlayer))
end
-- ============================================================================
-- PREFERRED ULTIMATE HVH FRAMEWORK CORE v14.1 BY @FOWLLQ (SYNTAX FIXED) - PART 2
-- ============================================================================

function Core:HookAntiFall(char)
    task.spawn(function()
        local r = char:WaitForChild("HumanoidRootPart", 10)
        if not r then return end
        
        local conn
        conn = RunService.Heartbeat:Connect(function()
            if not self.Active or not self.Config.antiFallEnabled or not r or not r.Parent then 
                if conn then conn:Disconnect() end 
                return 
            end
            
            local v = r.AssemblyLinearVelocity
            r.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            RunService.RenderStepped:Wait()
            
            if r and r.Parent then 
                r.AssemblyLinearVelocity = v 
            end
        end)
        table.insert(self.Connections, conn)
    end)
end

function Core:InitAntiFallService()
    if LocalPlayer.Character then self:HookAntiFall(LocalPlayer.Character) end
    local respawnConn
    respawnConn = LocalPlayer.CharacterAdded:Connect(function(char)
        if self.Active and self.Config.antiFallEnabled then self:HookAntiFall(char) end
    end)
    table.insert(self.Connections, respawnConn)
end

local function EmoteFlingCleanup()
    Core.Config.EmoteFling = false
    if Core.Track then pcall(function() Core.Track:Stop() end) Core.Track = nil end
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            hrp.Velocity = Vector3.new(0, 0, 0)
            hrp.RotVelocity = Vector3.new(0, 0, 0)
        end
    end
end

function Core:ToggleEmoteFling()
    if not self.Active then return end
    if self.Config.EmoteFling then self.Config.EmoteFling = false EmoteFlingCleanup() return end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if not (hrp and hum) then return end

    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. self.EmoteData.AnimId
    local trackOk, t = pcall(function() return hum:LoadAnimation(anim) end)
    if not trackOk or not t then return end

    self.Config.EmoteFling = true 
    self.Track = t
    t.Priority = Enum.AnimationPriority.Action
    t.Looped = false 
    t:Play()

    task.spawn(function()
        local flip = 1 
        local timeout = tick() + 300 
        local animStopped = false
        t.Stopped:Once(function() animStopped = true end)

        while self.Config.EmoteFling and self.Active and not animStopped do
            if tick() > timeout then break end
            RunService.Heartbeat:Wait()
            local c = LocalPlayer.Character 
            local r = c and c:FindFirstChild("HumanoidRootPart") 
            local h = c and c:FindFirstChildWhichIsA("Humanoid")

            if r and r.Parent and h then
                local dir = h.MoveDirection
                flip = flip * -1
                r.AssemblyLinearVelocity = Vector3.new(100000 * flip, 0, 100000 * flip)
                r.AssemblyAngularVelocity = Vector3.new(100000 * flip, 100000 * flip, 100000 * flip)

                RunService.RenderStepped:Wait()
                if not self.Config.EmoteFling or not self.Active then break end

                if dir.Magnitude > 0 then
                    local spd = self.Config.SpeedValue
                    r.AssemblyLinearVelocity = Vector3.new(dir.X * spd, -2, dir.Z * spd)
                    r.Velocity = Vector3.new(dir.X * spd, -2, dir.Z * spd)
                else
                    r.AssemblyLinearVelocity = Vector3.new(0, -2, 0)
                    r.Velocity = Vector3.new(0, -2, 0)
                end
                r.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                r.RotVelocity = Vector3.new(0, 0, 0)
            else 
                break 
            end
        end
        EmoteFlingCleanup()
    end)
end

function Core:StartMainLoop()
    SecureEnvironment()
    self:SendLog()
    self:InitAntiFallService()

    local loopConn
    loopConn = RunService.Stepped:Connect(function()
        if not Core.Active then loopConn:Disconnect() return end

        local char = LocalPlayer.Character
        if not char then return end
        
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end

        if Core.Config.Speed and not Core.Config.Fly and not Core.Config.EmoteFling then 
            hum.WalkSpeed = Core.Config.SpeedValue 
        else
            if not Core.Config.EmoteFling and hum.WalkSpeed == Core.Config.SpeedValue then hum.WalkSpeed = 16 end
        end

        if Core.Config.Fly and not Core.Config.EmoteFling then
            if not Core.Physics.bVelocity or Core.Physics.bVelocity.Parent ~= root then
                Core.Physics.bVelocity = Instance.new("BodyVelocity") 
                Core.Physics.bVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5) 
                Core.Physics.bVelocity.Velocity = Vector3.new(0, 0, 0) 
                Core.Physics.bVelocity.Parent = root
                
                Core.Physics.bGyro = Instance.new("BodyGyro") 
                Core.Physics.bGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5) 
                Core.Physics.bGyro.CFrame = root.CFrame 
                Core.Physics.bGyro.Parent = root
            end
            local moveVec = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec = moveVec + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec = moveVec - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec = moveVec - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec = moveVec + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVec = moveVec + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveVec = moveVec - Vector3.new(0, 1, 0) end
            
            Core.Physics.bVelocity.Velocity = moveVec.Magnitude > 0 and moveVec.Unit * Core.Config.SpeedValue or Vector3.new(0, 0, 0)
            Core.Physics.bGyro.CFrame = Camera.CFrame
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        else
            if not Core.Config.EmoteFling then
                if Core.Physics.bVelocity then Core.Physics.bVelocity:Destroy() Core.Physics.bVelocity = nil Core.Physics.bGyro:Destroy() Core.Physics.bGyro = nil end
            end
        end

        if Core.Config.Noclip or Core.Config.EmoteFling then
            for _, part in ipairs(char:GetDescendants()) do 
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then 
                    part.CanCollide = false 
                end 
            end
        end
    end)
    table.insert(Core.Connections, loopConn)
end

function Core:InitJump()
    local jumpConn
    jumpConn = UserInputService.JumpRequest:Connect(function()
        if not Core.Active then jumpConn:Disconnect() return end
        if Core.Config.InfJump then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)
    table.insert(Core.Connections, jumpConn)
end

function Core:Unload()
    Core.Active = false
    EmoteFlingCleanup()
    for _, conn in ipairs(Core.Connections) do if conn then conn:Disconnect() end end
    Core.Connections = {}
    if Core.Physics.bVelocity then Core.Physics.bVelocity:Destroy() end
    if Core.Physics.bGyro then Core.Physics.bGyro:Destroy() end
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then 
                root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                root.Velocity = Vector3.new(0, 0, 0)
                root.RotVelocity = Vector3.new(0, 0, 0)
            end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16 end
            for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = true end end
        end
    end)
end

return Core
