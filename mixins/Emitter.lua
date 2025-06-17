---@type Object
local Object
local Emitter, private, Async

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Async = require("classes.Async")

Emitter = Object:extend()

private[Emitter] = {}

    --======PRIVATE FUNCTIONS======--

local EMPTY_TABLE, build, run

EMPTY_TABLE = {}

function build(self, event, func, once, sync, ...)
    local p = private[self]
    
    if not table.deepget(p, "events", event) then
        table.deepset(p, "events", event, {})
    end

    table.insert(p.events[event], {
        ready  = true,
        args   = { ... },
        buffer = {},
        func   = func,
        once   = once,
        sync   = sync,
        obj    = self
    })
end

function run(self, listener, ...)
    listener.func(table.unpack(table.imerge(self, listener.args, { ... })))
end

    --======CONSTRUCTOR======--

function Emitter:on(event, callback, ...)
    build(self, event, callback, false, false, ...)

    return self
end

function Emitter:once(event, callback, ...)
    build(self, event, callback, true, false, ...)

    return self
end

function Emitter:onSync(event, callback, ...)
    build(self, event, callback, false, true, ...)

    return self
end

function Emitter:onceSync(event, callback, ...)
    build(self, event, callback, true, true, ...)

    return self
end

    --======STATIC======--

    --======METHODS======--

function Emitter:dispatch(event, ...)
    local p, args
    
    p    = private[self]
    args = { ... }
    
    if #(p.events[event] or EMPTY_TABLE) == 0 then return self end

    p.events[event] = table.filter(p.events[event], function(_, listener)
        if listener.sync then return true end

        Async(run, self, listener, table.unpack(args))

        return not listener.once
    end)

    return self
end

function Emitter:dispatchSync(event, ...)
    local p, args
    
    p    = private[self]
    args = { ... }
    
    if #(p.events[event] or EMPTY_TABLE) == 0 then return self end
    
    p.events[event] = table.filter(p.events[event], function(_, listener)
        if not listener.sync then return true end

        listener.func(table.unpack(table.imerge(self, listener.args, args)))

        return not listener.once
    end)

    return self
end

function Emitter:discardEvent(event, func)
    local p = private[self]
    
    if #(p.events[event] or EMPTY_TABLE) == 0 then return self end

    p.events[event] = table.filter(p.events[event], function(_, listener)
        return listener.obj ~= self and listener.func ~= func
    end)

    return self
end

    --======GETTERS======--

    --======SETTERS======--

    --======METAMETHODS======--

Emitter.__type = "emitter"

return Emitter