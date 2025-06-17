---@type Object
local Object
local Tween, private, is
local Emitter, TypeError, RangeError

Object = require("lib.Classy")
private = require("lib.Classy.instances")

TypeError  = require("classes.errors.TypeError")
RangeError = require("classes.errors.RangeError")

Emitter = require("classes.mixins.Emitter")

is = require("lib.is")

Tween = Object:extend()

Tween:implement(Emitter)

    --======PRIVATE FUNCTIONS======--

local function linear(v) return v end

    --======CONSTRUCTOR======--

function Tween:new(owner, targets, duration, easing)
    local p = private[self]

    p.values = {}

    TypeError:assert(easing == nil or is(easing, "function"), "easing", type(easing), "nil/function")
    TypeError:assert(is(targets, "table"), "targets", type(targets), "table")
    TypeError:assert(is(duration, "number"), "duration", type(duration), "number")
    
    for k, finish in pairs(targets) do
        local start = owner[k]

        TypeError:assert(is(finish, "number"), "target." .. k, type(finish), "number")
        TypeError:assert(is(start, "number"), owner .. k, type(start), "number")

        p.values[#p.values + 1] = { k, start, finish - start }
    end

    p.elapsed   = 0
    p.running   = true
    p.state     = "running"
    p.direction = "forward"
    p.owner     = owner
    p.duration  = duration
    p.easing    = easing or linear
end

    --======METHODS======--

function Tween:update(dt)
    local p, progress
    
    p = private[self]

    if not p.running then return self end

    TypeError:assert(is(dt, "number"), "dt", type(dt), "number")
    
    if p.elapsed == 0 then
        p.state = "starting"

        self:dispatch("tween.start")
        self:dispatchSync("tween.start")

        p.state = "running"
    end

    p.elapsed = math.min(p.elapsed + dt, p.duration)
    
    --No dividing by zero!
    progress = p.elapsed == 0 and 0 or p.easing(p.elapsed / p.duration)

    for _, tbl in ipairs(p.values) do
        p.owner[tbl[1]] = progress * tbl[3] + tbl[2]
    end

    self:dispatch("tween.progress")
    self:dispatchSync("tween.progress")
    
    if p.elapsed >= p.duration then
        p.running = false
        p.state   = "finished"

        self:dispatch("tween.end")
        self:dispatchSync("tween.end")
    end

    return self
end

function Tween:reverse()
    local p, values
    
    p      = private[self]
    values = {}

    p.elapsed = 1 - p.elapsed

    for i, tbl in ipairs(p.values) do
        values[i] = { tbl[1], tbl[3] + tbl[2], -tbl[3] }
    end

    p.values = values

    p.direction = p.direction == "forward" and "backward" or "forward"

    return self
end

function Tween:reset()
    local p = private[self]

    for _, tbl in ipairs(p.values) do
        p.owner[tbl[1]] = tbl[2]
    end

    p.elapsed = 0

    return self
end

function Tween:pause()
    local p = private[self]

    if p.running then
        p.running = false
        p.state   = "paused"
    end

    return self
end

function Tween:play()
    local p = private[self]

    if not p.running then
        if p.elapsed == p.duration then
            self:reset()
        end
    
        p.running = true
        p.state   = "running"
    end

    return self
end
    
    --======GETTERS======--

function Tween.__get:elapsed()
    return private[self].elapsed
end

function Tween.__get:duration()
    return private[self].duration
end

function Tween.__get:direction()
    return private[self].direction
end

function Tween.__get:owner()
    return private[self].owner
end

function Tween.__get:state()
    return private[self].state
end

function Tween.__get:targets()
    local p, res
    
    p   = private[self]
    res = {}

    for _, tbl in ipairs(p.values) do
        res[tbl[1]] = tbl[2] + tbl[3]
    end

    return res
end

    --======SETTERS======--

function Tween.__set:elapsed(value)
    local p = private[self]

    TypeError:assert(is(value, "number"), "elapsed", type(value), "number")
    RangeError:assert(value >= 0 and value <= p.duration, "elapsed", value, 0, p.duration)

    p.elapsed = value
end

function Tween.__set:duration(value)
    local p = private[self]

    TypeError:assert(is(value, "number"), "duration", type(value), "number")
    RangeError:assert(value > 0, "duration", value, ">0", math.huge)

    p.duration = value
end

function Tween.__set:easing(value)
    TypeError:assert(is(value, "function"), "easing", type(value), "function")
    
    private[self].easing = value
end

    --======METAMETHODS======--

function Tween:__tostring()
    local p, keys
    
    p    = private[self]
    keys = {}

    if self.is_instance then
        for _, tbl in ipairs(p.values) do
            keys[#keys + 1] = tbl[1]
        end

        return self:tostringHelper(table.unpack(keys))
    end

    return self:tostringHelper("Class")
end

Tween.__type = "tween"

return Tween