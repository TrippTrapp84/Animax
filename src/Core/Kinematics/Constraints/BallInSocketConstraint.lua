local Types = script.Parent.Parent.Parent.Parent.Types
local Util = script.Parent.Parent.Parent.Parent.Util

local Base = require(script.Parent.Base)
local KinematicsTypes = require(Types.Kinematics)
local Gizmo = require(Util.Gizmo)

type KinematicBoneData = KinematicsTypes.KinematicBoneData

local Handler = setmetatable({}, Base)
Handler.__index = Handler

function Handler.new(Parent, Bone, Children)
    local self = setmetatable({}, Handler)

    return self
end

function Handler:SolveForward(Bone0: KinematicBoneData, Bone1: KinematicBoneData)
end

function Handler:SolveBackward(Bone0: KinematicBoneData, Targets: {KinematicBoneData})
    return
end

function Handler:GetControlType()
    return "Position"
end

return Handler