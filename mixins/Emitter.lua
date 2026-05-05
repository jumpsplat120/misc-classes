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
    local p, args, exists
    
    p    = private[self].emitter
    args = { ... }

    --If there are no async events, early exit.
    if not p.async[event] then return self end

    --Call every async event that matches, and remove ones that only run once.
    for callback, data in pairs(p.async[event]) do
        Async(callback, self, table.unpack(table.imerge(data.args, args)))

        if data.once then
            p.async[event][callback] = nil
        end
    end

    --Check to see if the table has at least one item in it.
    for _ in pairs(p.async[event]) do
        exists = true

        break
    end

    --If the table has no items, remove the table.
    if not exists then
        p.async[event] = nil
    end

    return self
end

function Emitter:dispatchSync(event, ...)
    local p, args, exists
    
    p    = private[self].emitter
    args = { ... }

    --If there are no sync events, early exit.
    if not p.sync[event] then return self end

    --Call every sync event that matches, and remove ones that only run once.
    for callback, data in pairs(p.sync[event]) do
        callback(self, table.unpack(table.imerge(data.args, args)))

        if data.once then
            p.sync[event][callback] = nil
        end
    end

    --Check to see if the table has at least one item in it.
    for _ in pairs(p.sync[event]) do
        exists = true

        break
    end

    --If the table has no items, remove the table.
    if not exists then
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