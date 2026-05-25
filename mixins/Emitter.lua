local Object, private
local Emitter
local Async
local TypeError

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Async = require("classes.Async")

TypeError = require("classes.errors.TypeError")

---@type Emitter.Mixin
Emitter = Object:init()

private[Emitter] = {}

    --======PRIVATE FUNCTIONS======--

    --======CONSTRUCTOR======--

function Emitter:new()
    local p = private[self]

    p.emitter = {
        sync  = {},
        async = {}
    }
end

    --======STATIC======--

    --======METHODS======--

function Emitter:on(event, callback, ...)
    local p = private[self].emitter

    TypeError:assert(type(event) == "string", "event", type(event), "string")
    TypeError:assert(type(callback) == "function", "callback", type(callback), "function")

    p.async[event] = p.async[event] or {}

    p.async[event][callback] = {
        self = self,
        args = { ... },
        once = false
    }

    return self
end

function Emitter:once(event, callback, ...)
    local p = private[self].emitter

    TypeError:assert(type(event) == "string", "event", type(event), "string")
    TypeError:assert(type(callback) == "function", "callback", type(callback), "function")
    
    p.async[event] = p.async[event] or {}

    p.async[event][callback] = {
        self = self,
        args = { ... },
        once = true
    }

    return self
end

function Emitter:onSync(event, callback, ...)
    local p = private[self].emitter

    TypeError:assert(type(event) == "string", "event", type(event), "string")
    TypeError:assert(type(callback) == "function", "callback", type(callback), "function")
    
    p.sync[event] = p.sync[event] or {}
    
    p.sync[event][callback] = {
        self = self,
        args = { ... },
        once = false
    }

    return self
end

function Emitter:onceSync(event, callback, ...)
    local p = private[self].emitter

    TypeError:assert(type(event) == "string", "event", type(event), "string")
    TypeError:assert(type(callback) == "function", "callback", type(callback), "function")
    
    p.sync[event] = p.sync[event] or {}
    
    p.sync[event][callback] = {
        self = self,
        args = { ... },
        once = true
    }

    return self
end

function Emitter:dispatch(event, ...)
    local p, args, async, count
    
    p     = private[self].emitter
    args  = { ... }
    async = p.async[event]
    count = 0

    --If there are no async events, early exit.
    if not async then return self end

    --Call every async event that matches, and remove ones that only run once.
    for callback, data in pairs(async) do
        count = count + 1

        Async(callback, self, table.unpack(table.imerge(data.args, args)))

        if data.once then
            async[callback] = nil

            count = count - 1
        end
    end

    --If the table has no items, remove the table.
    if count == 0 then
        p.async[event] = nil
    end

    return self
end

function Emitter:dispatchSync(event, ...)
    local p, args, sync, count
    
    p     = private[self].emitter
    args  = { ... }
    sync  = p.sync[event]
    count = 0

    --If there are no sync events, early exit.
    if not sync then return self end

    --Call every sync event that matches, and remove ones that only run once.
    for callback, data in pairs(sync) do
        count = count + 1

        callback(self, table.unpack(table.imerge(data.args, args)))

        if data.once then
            sync[callback] = nil

            count = count - 1
        end
    end

    if count == 0 then
        p.sync[event] = nil
    end

    return self
end

function Emitter:discard(event, callback)
    local p = private[self]
    
    if p.sync[event] then
        p.sync[event][callback] = nil
    end

    if p.async[event] then
        p.async[event][callback] = nil
    end

    return self
end

    --======GETTERS======--

    --======SETTERS======--

    --======METAMETHODS======--

return Emitter