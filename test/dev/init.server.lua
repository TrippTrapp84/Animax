local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Animax = require(ReplicatedStorage.Animax)

-- do --// Normal animation track test
--     local RigRoot = workspace.Run.HumanoidRootPart
--     local Animator = Animax.MakeDefaultAnimator(RigRoot,"ShortestDirection")
    
--     local Animation = Animator:LoadAnimation("rbxassetid://12638608080")
--     Animation:AdjustSpeed(0.1)
--     Animation:SetLooped(true)
--     Animation:Play()
-- end

do --// Kinematic Track Test
    local RigRoot = workspace.IK.HumanoidRootPart
    local Animator = Animax.MakeDefaultAnimator(RigRoot, "ShortestDirection")

    local KinematicAnim = Animator:LoadKinematicAnimation("rbxassetid://111809770929663")
    KinematicAnim:SetLooped(true)
    KinematicAnim:Play()

    local WaveAnim = Animator:LoadAnimation("rbxassetid://85302302848438")
    WaveAnim:SetLooped(true)
    WaveAnim:Play()
end
