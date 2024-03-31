---!strict
local Connection = require(script.Connection)
local EventTypes = require(script.types)

local Handler = {}
Handler.__index = Handler

type ANMXScriptSignalCallback = EventTypes.ANMXScriptSignalCallback

export type ANMXScriptSignal = EventTypes.ANMXScriptSignal

export type ANMXScriptConnection = EventTypes.ANMXScriptConnection

function Handler.new() : ANMXScriptSignal
    local self : ANMXScriptSignal = setmetatable({},Handler) :: ANMXScriptSignal

    self.Callbacks = {}

    return self
end

function Handler.Wait(self : ANMXScriptSignal)
    local Finished = false
    local Con; Con = self:Connect(function()
        Finished = true
        Con:Disconnect()
    end)

    repeat
        task.wait()
    until Finished
end

function Handler._Disconnect(self : ANMXScriptSignal, Connection : ANMXScriptConnection)
    self.Callbacks[Connection.ConnectionId] = nil
end

function Handler.Connect(self : ANMXScriptSignal, Callback : ANMXScriptSignalCallback) : ANMXScriptConnection
    local Index = {}
    self.Callbacks[Index] = Callback
    
    return Connection.new(self,Index)
end

function Handler.Fire(self : ANMXScriptSignal, ... : any)
    for i,v in pairs(self.Callbacks) do
        v(...)
    end
end

return Handler