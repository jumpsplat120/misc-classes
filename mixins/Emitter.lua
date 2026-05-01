local Object, private
local Emitter, Async

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Async = require("classes.Async")

Emitter = Object:init()

private[Emitter] = {}

    --======PRIVATE FUNCTIONS======--

local exists, build, run

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

--If p.events is nil, then that means no listeners have been created.
--If p.events[event] is nil, then that means that specific lister hasn't been created.
--However, if it's empty, then it was created at one point, then removed.
function exists(p, event)
    if p.events         == nil then return false end
    if p.events[event]  == nil then return false end
    if #p.events[event] == 0   then return false end

    return true
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
    
    if not exists(p, event) then return self end

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
    
    if not exists(p, event) then return self end

    p.events[event] = table.filter(p.events[event], function(_, listener)
        if not listener.sync then return true end

        listener.func(table.unpack(table.imerge(self, listener.args, args)))

        return not listener.once
    end)

    return self
end

function Emitter:discardEvent(event, func)
    local p = private[self]
    
    if not exists(p, event) then return self end
    
    p.events[event] = table.filter(p.events[event], function(_, listener)
        return listener.obj ~= self and listener.func ~= func
    end)

    return self
end

    --======GETTERS======--

    --======SETTERS======--

    --======METAMETHODS======--

return Emitter