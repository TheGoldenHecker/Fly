-- Local Script (place in StarterPlayerScripts)

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera
local flying = false
local speed = 50 -- Adjust flying speed
local flyVelocity, flyGyro

-- Store currently pressed keys
local activeKeys = {}

-- Function to start flying
local function startFlying()
    if flying then return end
    flying = true

    -- Create BodyVelocity and BodyGyro for movement
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
    activeKeys = {} -- Clear active keys
end

-- Function to calculate movement direction based on active keys
local function updateFlyVelocity()
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
        direction = direction + Vector3.new(0, -1, 0)
    end

    if direction.Magnitude > 0 then
        flyVelocity.Velocity = direction.Unit * speed
    else
        flyVelocity.Velocity = Vector3.zero
    end

    -- Instantly lock the character's orientation to the camera's direction
    if flyGyro then
        flyGyro.CFrame = CFrame.new(humanoidRootPart.Position, humanoidRootPart.Position + camera.CFrame.LookVector)
    end
end

-- Toggle flying when "F" is pressed
local function toggleFlight(input)
    if input.KeyCode == Enum.KeyCode.F then
        if flying then
            stopFlying()
        else
            startFlying()
        end
    end
end

-- Handle key press events
local function onInputBegan(input, processed)
    if processed then return end

    local keyName = input.KeyCode.Name
    if keyName then
        activeKeys[keyName] = true
        updateFlyVelocity()
    end

    toggleFlight(input)
end

-- Handle key release events
local function onInputEnded(input, processed)
    if processed then return end

    local keyName = input.KeyCode.Name
    if keyName then
        activeKeys[keyName] = nil
        updateFlyVelocity()
    end
end

-- Update fly direction periodically
local function updateFlyLoop()
    while true do
        if flying then
            updateFlyVelocity()
        end
        task.wait(0.03)
    end
end

-- Start update loop
task.spawn(updateFlyLoop)

-- Connect input events
local userInputService = game:GetService("UserInputService")

userInputService.InputBegan:Connect(onInputBegan)
userInputService.InputEnded:Connect(onInputEnded)
