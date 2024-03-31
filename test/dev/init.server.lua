local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ANMXAnimator = require(ReplicatedStorage.Animax)

local RigRoot = workspace.Run.HumanoidRootPart
local Animator = ANMXAnimator.MakeDefaultAnimator(RigRoot,"ShortestDirection")

local Animation = Animator:LoadAnimation("rbxassetid://12638608080")

-- local function CompareBone(Bone : Bone, Pose : Pose, Timeline : any)
--     if Timeline[Bone].Poses[1].Pose.CFrame ~= Pose.CFrame then
--         error("Failed")
--     end

--     for i,v in pairs(Pose:GetSubPoses()) do
--         CompareBone(Bone:FindFirstChild(v.Name),v,Timeline)
--     end
-- end

-- for i,v in (Animation.Keyframes[1]:GetPoses()[1]:GetSubPoses()) do
--     CompareBone(RigRoot:FindFirstChild(v.Name),v,Animation:GetRigTimeline())
-- end

Animation:AdjustSpeed(0.1)
Animation:SetLooped(true)

Animation:Play()

-- Animation.OnStop:Connect(function()
--    Animation:Play()
-- end)

-- task.defer(function()
--     while wait() do
--         Animation:AdjustWeight(math.sin(time()))
--     end
-- end)

local SecondAnim = Animator:LoadAnimation("rbxassetid://12663616469")

SecondAnim:AdjustSpeed(0.5)
SecondAnim:AdjustWeight(1000)
SecondAnim:SetLooped(true)

SecondAnim:Play()

-- SecondAnim.OnStop:Connect(function()
--     SecondAnim:Play()
-- end)
