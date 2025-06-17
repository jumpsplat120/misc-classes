---@type Object
local Object
local Cron, Async, private, timers
local ConstructorError

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Async = require("classes.Async")

Cron = Object:extend()

ConstructorError = require("classes.errors.ConstructorError")

timers = {}

    --======PRIVATE FUNCTIONS======--

local states, internal

local function create(self, delay, callback, ...)
    local clock = self(delay, callback, ...)

    timers[#timers + 1] = clock

    return clock
end

states = {
    dead = true,
    paused = true,
    running = true
}

    --======CONSTRUCTOR======--

function Cron:new(delay, callback, verify, ...)
    local p = private[self]
    
    ConstructorError:assert(verify and verify == internal, Cron)

    p.args       = { ... }
    p.delay      = delay
    p.state      = "paused"
    p.callback   = callback
    p.countdown  = delay
    p.thennables = {}
end

function Cron:after(delay, callback, ...)
    internal = math.uuid()

    return create(self, delay, callback, internal, ...):play():stop()
end

function Cron:every(delay, callback, ...)
    internal = math.uuid()

    return create(self, delay, callback, internal, ...):play()
end

    --======METHODS======--

function Cron:update(dt)
    if self.is_instance then return end

    table.map(timers, function(i, clock)
        local p = private[clock]

        if not p.state == "running" then return i, clock end

        p.countdown = p.countdown - dt

        if p.countdown > 0 then return i, clock end

        clock:execute()

        p.countdown = p.delay

        if not p.last_run    then return i, clock end
        if #p.thennables > 0 then return i, clock end

        clock:stop(true)
    end)
end

function Cron:stop(immediately)
    local p = private[self]

    if p.state == "dead" then return self end
    
    if immediately then p.state = "dead" else p.last_run = true end
    
    return self
end

function Cron:start()
    local p = private[self]

    if p.last_run then p.last_run = false end
    
    if p.state == "running" then return self end
    if p.state == "dead"    then return self end
    
    p.state = "running"

    return self
end

function Cron:pause()
    local p = private[self]

    if p.state == "paused" then return self end
    if p.state == "dead"   then return self end

    p.state = "paused"

    return self
end

function Cron:play()
    local p = private[self]

    if p.state == "running" then return self end
    if p.state == "dead"    then return self end
    
    p.state = "running"

    return self
end

function Cron:execute()
    local p = private[self]

    if p.state == "dead" then return self end

    Async(function(...)
        p.callback(...)

        if #p.thennables > 0 then
            local new = table.remove(p.thennables)

            if not p.last_run then
                table.insert(p.thennables, 1, {
                    callback = p.callback,
                    delay    = p.delay,
                    args     = p.args
                })
            end

            p.args       = new.args
            p.delay      = new.delay
            p.callback   = new.callback
            p.countdown  = new.delay
        end
    end, table.unpack(p.args))
end

function Cron:andThen(delay, callback, ...)
    local p = private[self]

    table.insert(p.thennables, 1, {
        delay    = delay,
        callback = callback,
        args     = { ... }
    })

    return self
end

    --======GETTERS======--

function Cron.__get:state()
    return private[self].state
end

function Cron.__get:delay()
    return private[self].delay
end

function Cron.__get:time_until()
    return math.max(private[self].countdown, 0)
end

    --======SETTERS======--

function Cron.__set:state(value)
    local p = private[self]

    if p.state == "dead" then return end

    value = tostring(value)
    
    if type(value) ~= "string"   then return end
    if not states[value:lower()] then return end

    p.state = value
end

function Cron.__set:delay(value)
    local p = private[self]

    if p.state == "dead" then return end
    
    value = tonumber(value)

    if type(value) ~= "number" then return end

    p.delay = value:clamp(0, math.huge)
end

function Cron.__set:time_until(value)
    local p = private[self]

    if p.state == "dead" then return end
    
    value = tonumber(value)

    if type(value) ~= "number" then return end

    p.countdown = math.max(value, 0)
end

    --======METAMETHODS======--

function Cron:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper(p.state, self.time_until) end

    return self:tostringHelper("Class")
end

Cron.__type = "cron"

return Cron