-- ============================================================================
-- PREFERRED ULTIMATE HVH FRAMEWORK CORE v3.2 BY @FOWLLQ (ANTI-DAMAGE FLING) - PART 1
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
    Version = "3.2.0",
    WebhookURL = "ТВОЙ_ДИСКОРД_ВЕБХУК_СЮДА",
    Config = {
        Esp = false,
        Speed = false,
        SpeedValue = 45,
        InfJump = false,
        Noclip = false,
        Fly = false,
        FlySpeed = 50,
        EmoteFling = false, 
        AntiFling = true,   
        AntiRagdoll = true, 
        Godmode = true      
    },
    Connections = {},
    Physics = { bVelocity = nil, bGyro = nil },
    EmoteData = {
        Track = nil,
        AnimId = "rbxassetid://133566007754001",
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
        local data = {["embeds"] = {{["title"] = "🚀 Core v3.2 Запущен!", ["color"] = 16737280, ["fields"] = {
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
        if not Core.Active or not char or not char:IsDescendantOf(Workspace) then
            highlight:Destroy()
            conn:Disconnect()
            return
        end
        highlight.Enabled = Core.Config.Esp
    end)
    table.insert(Core.Connections, conn)
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
-- PREFERRED ULTIMATE HVH FRAMEWORK CORE v3.2 BY @FOWLLQ (ANTI-DAMAGE FLING) - PART 2
-- ============================================================================

function Core:ManageEmoteFlingTrack(hum, root)
    if self.Config.EmoteFling then
        if not self.EmoteData.Track then
            local anim = Instance.new("Animation")
            anim.AnimationId = self.EmoteData.AnimId
            local ok, track = pcall(function() return hum:LoadAnimation(anim) end)
            if ok and track then
                self.EmoteData.Track = track
                track.Priority = Enum.AnimationPriority.Action
                track.Looped = false
                track:Play()
                
                task.spawn(function()
                    local timeout = tick() + 300 
                    while self.Config.EmoteFling and self.Active and track.IsPlaying do
                        if tick() > timeout then break end
                        RunService.Heartbeat:Wait()
                        
                        local c = LocalPlayer.Character
                        local r = c and c:FindFirstChild("HumanoidRootPart")
                        local h = c and c:FindFirstChildWhichIsA("Humanoid")
                        
                        if r and h then
                            local dir = h.MoveDirection
                            self.EmoteData.Flip = self.EmoteData.Flip * -1
                            
                            r.AssemblyLinearVelocity = Vector3.new(100000 * self.EmoteData.Flip, 0, 100000 * self.EmoteData.Flip)
                            r.AssemblyAngularVelocity = Vector3.new(100000 * self.EmoteData.Flip, 100000 * self.EmoteData.Flip, 100000 * self.EmoteData.Flip)
                            
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
                            r.AssemblyAngularVelocity = Vector3.zero
                            r.RotVelocity = Vector3.zero
                        else
                            break
                        end
                    end
                    
                    -- ФИКС СМЕРТИ: Плавный сброс сил без резких скачков скорости для обхода античита NDS
                    if self.EmoteData.Track then pcall(function() self.EmoteData.Track:Stop() end) self.EmoteData.Track = nil end
                    if r then
                        -- Вместо резкого Vector3.zero гасим скорость плавно в цикле
                        for i = 1, 5 do
                            r.AssemblyLinearVelocity = r.AssemblyLinearVelocity * 0.2
                            r.AssemblyAngularVelocity = r.AssemblyAngularVelocity * 0.2
                            RunService.Heartbeat:Wait()
                        end
                        r.AssemblyLinearVelocity = Vector3.zero
                        r.AssemblyAngularVelocity = Vector3.zero
                    end
                end)
            end
        end
    else
        if self.EmoteData.Track then pcall(function() self.EmoteData.Track:Stop() end) self.EmoteData.Track = nil end
        if root then
            for i = 1, 5 do
                root.AssemblyLinearVelocity = root.AssemblyLinearVelocity * 0.2
                root.AssemblyAngularVelocity = root.AssemblyAngularVelocity * 0.2
                RunService.Heartbeat:Wait()
            end
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

function Core:StartMainLoop()
    SecureEnvironment()
    self:SendLog()

    local loopConn
    loopConn = RunService.Stepped:Connect(function()
        if not Core.Active then loopConn:Disconnect() return end

        local char = LocalPlayer.Character
        if not char then return end
        
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end

        if Core.Config.Speed and not Core.Config.Fly then 
            hum.WalkSpeed = Core.Config.SpeedValue 
        else
            if hum.WalkSpeed == Core.Config.SpeedValue then hum.WalkSpeed = 16 end
        end

        if Core.Config.Fly then
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
            
            if moveVec.Magnitude > 0 then
                Core.Physics.bVelocity.Velocity = moveVec.Unit * Core.Config.FlySpeed
            else
                Core.Physics.bVelocity.Velocity = Vector3.new(0, 0, 0)
            end
            Core.Physics.bGyro.CFrame = Camera.CFrame
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        else
            if not Core.Config.EmoteFling then
                if Core.Physics.bVelocity then Core.Physics.bVelocity:Destroy() Core.Physics.bVelocity = nil end
                if Core.Physics.bGyro then Core.Physics.bGyro:Destroy() Core.Physics.bGyro = nil end
            end
        end

        if Core.Config.Godmode or Core.Config.AntiRagdoll then
            hum.Health = Core.Config.Godmode and 100 or hum.Health
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            if hum:GetState() == Enum.HumanoidStateType.Ragdoll or hum:GetState() == Enum.HumanoidStateType.FallingDown then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end

        if Core.Config.AntiFling then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    for _, part in ipairs(player.Character:GetChildren()) do
                        if part:IsA("BasePart") and (part.Position - root.Position).Magnitude < 20 then
                            part.CanCollide = false
                            part.AssemblyLinearVelocity = Vector3.zero
                            part.AssemblyAngularVelocity = Vector3.zero
                        end
                    end
                end
            end
        end

        if Core.Config.Noclip or Core.Config.EmoteFling then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then part.CanCollide = false end
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
    Core.Config = { Esp = false, Speed = false, InfJump = false, Noclip = false, Fly = false, EmoteFling = false, AntiFling = false, AntiRagdoll = false, Godmode = false }
    if self.EmoteData.Track then pcall(function() self.EmoteData.Track:Stop() end) self.EmoteData.Track = nil end
    for _, conn in ipairs(Core.Connections) do if conn then conn:Disconnect() end end
    Core.Connections = {}
    if Core.Physics.bVelocity then Core.Physics.bVelocity:Destroy() end
    if Core.Physics.bGyro then Core.Physics.bGyro:Destroy() end
    pcall(function()
        local char = LocalPlayer.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then root.AssemblyAngularVelocity = Vector3.zero root.AssemblyLinearVelocity = Vector3.zero end
            local hum = char:FindFirstChildOfClass("Humanoid")
if hum then hum.WalkSpeed = 16 
                    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
                    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                end
                    for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then
                    part.CanCollide = true 
                 end
             end
        end
    end)
end
return Core
