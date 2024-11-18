-- Local Script (place in StarterPlayerScripts)

local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local speed = 50 -- Flying speed
local flying = false
local activeKeys = {}

local flyVelocity, flyGyro -- Persistent references for physics objects

-- Function to start flying
local function startFlying(humanoidRootPart)
    if flying then return end
    flying = true

    -- Create BodyVelocity and BodyGyro
    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyVelocity.Velocity = Vector3.zero
    flyVelocity.P = 1250
    flyVelocity.Parent = humanoidRootPart

    flyGyro = Instance.new("BodyGyro")
    flyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyGyro.P = 10000 -- High power for instant response
    flyGyro.D = 100 -- Low damping for minimal delay
    flyGyro.CFrame = humanoidRootPart.CFrame
    flyGyro.Parent = humanoidRootPart
end

-- Function to stop flying
local function stopFlying()
    flying = false

    -- Cleanup BodyVelocity and BodyGyro
    if flyVelocity then
        flyVelocity:Destroy()
        flyVelocity = nil
    end
    if flyGyro then
        flyGyro:Destroy()
        flyGyro = nil
    end
    activeKeys = {} -- Reset active keys
end

-- Function to update movement direction
local function updateFlyVelocity(humanoidRootPart)
    if not flyVelocity or not flying then return end

    local direction = Vector3.zero
    if activeKeys["W"] then
        direction = direction + camera.CFrame.LookVector
    end
    if activeKeys["S"] then
        direction = direction - camera.CFrame.LookVector
    end
    if activeKeys["A"] then
        direction = direction - camera.CFrame.RightVector
    end
    if activeKeys["D"] then
        direction = direction + camera.CFrame.RightVector
    end
    if activeKeys["Space"] then
        direction = direction + Vector3.new(0, 1, 0)
    end
    if activeKeys["LeftShift"] then
        direction = direction - Vector3.new(0, 1, 0)
    end

    if direction.Magnitude > 0 then
        flyVelocity.Velocity = direction.Unit * speed
    else
        flyVelocity.Velocity = Vector3.zero
    end

    -- Lock orientation to the camera's direction
    if flyGyro then
        flyGyro.CFrame = CFrame.new(humanoidRootPart.Position, humanoidRootPart.Position + camera.CFrame.LookVector)
    end
end

-- Function to initialize flying for the character
local function initializeCharacter(character)
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    -- Continuously update velocity during flight
    task.spawn(function()
        while character and character.Parent do
            if flying then
                updateFlyVelocity(humanoidRootPart)
            end
            task.wait(0.03)
        end
    end)
end

-- Function to set up keybinds
local function setupKeybinds()
    local userInputService = game:GetService("UserInputService")

    userInputService.InputBegan:Connect(function(input, processed)
        if processed then return end

        local keyName = input.KeyCode.Name
        if keyName then
            activeKeys[keyName] = true
        end

        -- Toggle flight with "F"
        if input.KeyCode == Enum.KeyCode.F then
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                if flying then
                    stopFlying()
                else
                    startFlying(character.HumanoidRootPart)
                end
            end
        end
    end)

    userInputService.InputEnded:Connect(function(input, processed)
        if processed then return end

        local keyName = input.KeyCode.Name
        if keyName then
            activeKeys[keyName] = nil
        end
    end)
end

-- Reinitialize flying when character respawns
player.CharacterAdded:Connect(function(character)
    character:WaitForChild("HumanoidRootPart") -- Ensure the character is fully loaded
    initializeCharacter(character)
end)

-- Initialize flying for the current character if it exists
if player.Character then
    initializeCharacter(player.Character)
end

-- Set up persistent keybinds (independent of character resets)
setupKeybinds()
