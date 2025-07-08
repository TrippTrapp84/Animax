local Utils = script.Parent.Parent.Util

local Event = require(Utils.Event.types)

export type ANMXScriptSignal = Event.ANMXScriptSignal

export type BlendOrientationType = "ShortestDirection" | "RememberOrientation"

export type ANMXAnimator = {
    LoadAnimation: (self: ANMXAnimator, AnimationId: string) -> ANMXAnimationTrack
}

export type ANMXAnimationTrack = {
    OnPlay: ANMXScriptSignal,
    OnStop: ANMXScriptSignal,
    Play: (self: ANMXAnimationTrack, Time: number?) -> nil,
    Stop: (self: ANMXAnimationTrack) -> nil,
    AdjustSpeed: (self: ANMXAnimationTrack, Speed: number) -> nil,
    AdjustWeight: (self: ANMXAnimationTrack, Weight: number) -> nil,
    SetTimePosition: (self: ANMXAnimationTrack, Time: number) -> nil,
    SetLooped: (self: ANMXAnimationTrack, Looped: boolean) -> nil,
    GetWeight: (self: ANMXAnimationTrack) -> number,
    GetBoneWeight: (self: ANMXAnimationTrack, Bone: Bone) -> number,
    GetSpeed: (self: ANMXAnimationTrack) -> number,
    GetIsPlaying: (self: ANMXAnimationTrack) -> boolean,
    GetTimePosition: (self: ANMXAnimationTrack) -> number,

    GetRigTimeline: (self: ANMXAnimationTrack) -> {},
    GetAnimationPosesAtTime: (self: ANMXAnimationTrack, Time: number) -> {[Bone]: CFrame},
    GetAnimationPoses: (self: ANMXAnimationTrack) -> {[Bone]: CFrame}
}

export type ANMXAnimationBlender = {
    AddAnimation: (self: ANMXAnimationBlender, Animation: ANMXAnimationTrack, BlendOrientationType: BlendOrientationType) -> nil,
    RemoveAnimation: (self: ANMXAnimationBlender, Animation: ANMXAnimationTrack) -> nil,
    RenderAnimations: (DeltaTime: number) -> {[Bone]: CFrame},
}

return {}