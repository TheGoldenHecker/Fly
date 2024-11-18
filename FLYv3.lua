-- Local Script (place in StarterPlayerScripts)

local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local speed = 50 -- Flying speed
local flying = false
local activeKeys = {}

local flyVelocity, flyGyro -- Persistent references for physics objects

-- Function to enable only allowed states
local function enableAllowedStates(humanoid)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false) -- Disable falling
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false) -- Disable climbing
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false) -- Disable running
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false) -- Disable swimming
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false) -- Disable seated
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false) -- Disable dead
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) -- Enable jumping
    humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true) -- Enable platform standing
end

-- Function to restore all default states
local function restoreDefaultStates(humanoid)
    for _, state in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
        humanoid:SetStateEnabled(state, true)
    end
end

-- Function to calculate current velocity based on active keys
local function calculateVelocity()
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
        return direction.Unit * speed -- Normalize for smooth diagonal movement
    else
        return Vector3.zero
    end
end

-- Function to start flying
local function startFlying(humanoid, humanoidRootPart)
    if flying then return end
    flying = true

    -- Enable only allowed states
    enableAllowedStates(humanoid)

    -- Force the humanoid into a custom state
    humanoid:ChangeState(Enum.HumanoidStateType.PlatformStanding)

    -- Create BodyVelocity and BodyGyro
    flyVelocity = Instance.new("BodyVelocity")
    flyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyVelocity.Velocity = calculateVelocity() -- Start flying in the current direction
    flyVelocity.P = 1250
    flyVelocity.Parent = humanoidRootPart

    flyGyro = Instance.new("BodyGyro")
    flyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyGyro.P = 10000 -- High power for instant response
    flyGyro.D = 100 -- Low damping for minimal delay
    flyGyro.CFrame = humanoidRootPart.CFrame
    flyGyro.Parent = humanoidRootPart

    -- Disable collision for smoother flying
    humanoidRootPart.CanCollide = false
end

-- Function to stop flying
local function stopFlying(humanoid, humanoidRootPart)
    if not flying then return end
    flying = false

    -- Re-enable collision
    humanoidRootPart.CanCollide = true

    -- Restore all default states
    restoreDefaultStates(humanoid)

    -- Cleanup BodyVelocity and BodyGyro
    if flyVelocity then
        flyVelocity:Destroy()
        flyVelocity = nil
    end
    if flyGyro then
        flyGyro:Destroy()
        flyGyro = nil
    end
end

-- Function to update movement direction
local function updateFlyVelocity(humanoidRootPart)
    if not flyVelocity or not flying then return end
    flyVelocity.Velocity = calculateVelocity() -- Continuously update velocity based on keys

    -- Lock orientation to the camera's direction
    if flyGyro then
        flyGyro.CFrame = CFrame.new(humanoidRootPart.Position, humanoidRootPart.Position + camera.CFrame.LookVector)
    end
end

-- Function to initialize flying for the character
local function initializeCharacter(character)
    local humanoid = character:WaitForChild("Humanoid")
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    -- Enable allowed states
    enableAllowedStates(humanoid)

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

    -- When a key is pressed
    userInputService.InputBegan:Connect(function(input, processed)
        if processed then return end

        local keyName = input.KeyCode.Name
        if keyName then
            activeKeys[keyName] = true
        end

        -- Toggle flight with "F"
        if input.KeyCode == Enum.KeyCode.F then
            local character = player.Character
            if character and character:FindFirstChild("Humanoid") and character:FindFirstChild("HumanoidRootPart") then
                local humanoid = character:FindFirstChild("Humanoid")
                local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                if flying then
                    stopFlying(humanoid, humanoidRootPart)
                else
                    startFlying(humanoid, humanoidRootPart)
                end
            end
        end
    end)

    -- When a key is released
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
