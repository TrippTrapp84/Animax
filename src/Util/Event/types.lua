export type ANMXScriptConnection = {
    Signal : ANMXScriptSignal,
    ConnectionId : {},
    Disconnect : (self: ANMXScriptConnection) -> ()
}

export type ANMXScriptSignalCallback = (...any) -> ()

export type ANMXScriptSignal = {
    Callbacks : {[{}] : ANMXScriptSignalCallback},
    new : () -> ANMXScriptSignal,
    Connect : (self : ANMXScriptSignal,Callback : ANMXScriptSignalCallback) -> (ANMXScriptConnection),
    Wait : (self : ANMXScriptSignal) -> (...any),
    Fire : (self : ANMXScriptSignal, ...any) -> (),

    _Disconnect : (self : ANMXScriptSignal, Connection : ANMXScriptConnection) -> ()
}

return {}