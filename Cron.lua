local Object, private
local Cron
local Emitter
local ConstructorError, TypeError

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Emitter = require("classes.mixins.Emitter")

TypeError        = require("classes.errors.TypeError")
ConstructorError = require("classes.errors.ConstructorError")

Cron = Object:init()

private[Cron] = {}

    --======PRIVATE FUNCTIONS======--

local internal

internal = math.random()

    --======CONSTRUCTOR======--

function Cron:after(delay, ...)
    local p = private[self]

    TypeError:assert(type(delay) == "number", "delay", type(delay), "number")

    internal = math.random()

    return self {
        args     = { ... },
        once     = true,
        delay    = delay,
        internal = internal
    }
end

function Cron:every(delay, ...)
    local p = private[self]

    TypeError:assert(type(delay) == "number", "delay", type(delay), "number")

    internal = math.random()

    return self {
        args     = { ... },
        once     = false,
        delay    = delay,
        internal = internal
    }
end

function Cron:new(opts)
    local p = private[self]
    
    ConstructorError:assert(opts.internal == internal, "Cron")

    Emitter.new(self)

    p.time  = 0
    p.args  = opts.args
    p.once  = opts.once
    p.delay = opts.delay

    private[Cron][self] = true
end

    --======METHODS======--

function Cron:update(dt)
    if getmetatable(self) ~= Object then return end

    for cron, _ in pairs(private[Cron]) do
        local p = private[cron]

        p.time = p.time + dt

        if p.time >= p.delay then
            p.time = 0

            cron:dispatch("cron.tick", table.unpack(p.args))
            cron:dispatchSync("cron.tick", table.unpack(p.args))

            if p.once then
                private[Cron][self] = nil
            end
        end
    end
end

function Cron:destroy()
    private[Cron][self] = nil
end

    --======GETTERS======--

function Cron.__get:delay()
    return private[self].delay
end

function Cron.__get:time_until()
    local p = private[self]

    return p.delay - p.time
end

    --======SETTERS======--

    --======METAMETHODS======--

function Cron:__tostring()
    local p = private[self]

    return self:tostring(self.time_until)
end

Cron.__type = "cron"

---@type Cron.Class
local Class = Object:create(Cron, Emitter)

return Class