local Object, private
local Easings
local TypeError, RangeError, InvalidError, VectorSizeError

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

TypeError       = require("classes.errors.TypeError")
RangeError      = require("classes.errors.RangeError")
InvalidError    = require("classes.errors.InvalidError")
VectorSizeError = require("classes.errors.VectorSizeError")

Easings = Object:init()

private[Easings] = {}

    --======PRIVATE FUNCTIONS======--

local easings, directions_lut, directions, internal
local pow, cbrt, sqrt, sin, cos, pi, tau
local c1, c2, c3, c4, c5, n1, d1
local x2t, Y, bezier

internal = math.uuid()

directions_lut = {
    out    = true,
    inout  = true,
    ["in"] = true --Reserved keyword
}

directions = table.join(table.keys(directions_lut), ", ", " and ")

pi   = math.pi
tau  = math.tau
pow  = math.pow
sin  = math.sin
cos  = math.cos
sqrt = math.sqrt
cbrt = math.cbrt
c1   = 1.70158
c2   = c1 * 1.525
c3   = c1 + 1
c4   = 2 * pi / 3
c5   = 2 * pi / 4.5
n1   = 7.5625
d1   = 2.75

easings = {
    linear = function(x)
        return x
    end,
    quadraticin = function(x)
        return x * x
    end,
    quadraticout = function(x)
        local minus = 1 - x

        return 1 - minus * minus
    end,
    quadraticinout = function(x)
        if x < 0.5 then
            return 2 * x * x
        end

        return 1 - pow(-2 * x + 2, 2) / 2
    end,
    cubicin = function(x)
        return x * x * x
    end,
    cubicout = function(x)
        return 1 - pow(1 - x, 3)
    end,
    cubicinout = function(x)
        if x < 0.5 then
            return 4 * x * x * x
        end

        return 1 - pow(-2 * x + 2, 3) / 2
    end,
    quarticin = function(x)
        return x * x * x * x
    end,
    quarticout = function(x)
        return 1 - pow(1 - x, 4)
    end,
    quarticinout = function(x)
        if x < 0.5 then
            return 8 * x * x * x * x
        end

        return 1 - pow(-2 * x + 2, 4) / 2
    end,
    quinticin = function(x)
        return x * x * x * x * x
    end,
    quinticout = function(x)
        return 1 - pow(1 - x, 5)
    end,
    quinticinout = function(x)
        if x < 0.5 then
            return 16 * x * x * x * x * x
        end

        return 1 - pow(-2 * x + 2, 5) / 2
    end,
    sinusoidalin = function(x)
        return 1 - cos((x * pi) / 2)
    end,
    sinusoidalout = function(x)
        return sin((x * pi) / 2);
    end,
    sinusoidalinout = function(x)
        return -(cos(pi * x) - 1) / 2
    end,
    exponentialin = function(x)
        if x == 0 then return 0 end

        return pow(2, 10 * x - 10)
    end,
    exponentialout = function(x)
        if x == 1 then return 1 end

        return 1 - pow(2, -10 * x)
    end,
    exponentialinout = function(x)
        if x == 0 then return 0 end
        if x == 1 then return 1 end
        
        if x < 0.5 then
            return pow(2, 20 * x - 10) / 2
        end

        return (2 - pow(2, -20 * x + 10)) / 2
    end,
    circularin = function(x)
        return 1 - sqrt(1 - pow(x, 2))
    end,
    circularout = function(x)
        return sqrt(1 - pow(x - 1, 2))
    end,
    circularinout = function(x)
        if x < 0.5 then
            return (1 - sqrt(1 - pow(2 * x, 2))) / 2
        end

        return (sqrt(1 - pow(-2 * x + 2, 2)) + 1) / 2
    end,
    backin = function(x)
        return c3 * x * x * x - c1 * x * x
    end,
    backout = function(x)
        return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2)
    end,
    backinout = function(x)
        if x < 0.5 then
            return (pow(2 * x, 2) * ((c2 + 1) * 2 * x - c2)) / 2
        end

        return (pow(2 * x - 2, 2) * ((c2 + 1) * (x * 2 - 2) + c2) + 2) / 2
    end,
    elasticin = function(x)
        if x == 0 then return 0 end
        if x == 1 then return 1 end

        return -pow(2, 10 * x - 10) * sin((x * 10 - 10.75) * c4)
    end,
    elasticout = function(x)
        if x == 0 then return 0 end
        if x == 1 then return 1 end

        return pow(2, -10 * x) * sin((x * 10 - 0.75) * c4) + 1
    end,
    elasticinout = function(x)
        if x == 0 then return 0 end
        if x == 1 then return 1 end

        if x < 0.5 then
            return -(pow(2, 20 * x - 10) * sin((20 * x - 11.125) * c5)) / 2
        end

        return (pow(2, -20 * x + 10) * sin((20 * x - 11.125) * c5)) / 2 + 1
    end,
    bouncein = function(x)
        return 1 - easings.bounceout(1 - x)
    end,
    bounceout = function(x)
        if x < 1 / d1 then
            return n1 * x * x
        end

        if x < 2 / d1 then
            x = x - 1.5

            return n1 * (x / d1) * x + 0.75
        end

        if x < 2.5 / d1 then
            x = x - 2.25

            return n1 * (x / d1) * x + 0.9375
        end

        x = x - 2.625

        return n1 * (x / d1) * x + 0.984375
        
    end,
    bounceinout = function(x)
        if x < 0.5 then
            return (1 - easings.bounceout(1 - 2 * x)) / 2
        end

        return (1 + easings.bounceout(2 * x - 1)) / 2
    end
}

--Pulled from https://github.com/gre/bezier-easing/blob/master/src/index.js
function x2t(x, a, b, c, d)
    local q, s, l, angle, theta

    q = a + b * x
    s = q ^ 2 + c

    if s > 0 then
        local root = sqrt(s)

        return cbrt(q + root) + cbrt(q - root) - d
    end

    l = cbrt(sqrt(q * q - s))

    angle = q == 0 and -pi / 2 or math.atan(sqrt(-s) / q)

    if b < 0 then
        theta = (q > 0 and tau or pi) - angle
    elseif d < 0 then
        theta = (q > 0 and tau or (-3 * pi)) + angle
    else
        theta = (q > 0 and 0 or pi) + angle
    end

    return 2 * l * cos(theta / 3) - d
end

function Y(t, ay, by, cy)
    return ((ay * t + 3 * by) * t + cy) * t
end

function bezier(mX1, mY1, mX2, mY2)
    if mX1 == mY1 and mX2 == mY2 then
        return easings.linear
    end

    local a, b, c, a2, b2
    local d, e, w1, w, o
    local ay, by, cy, X2T

    a = 6 * (3 * mX1 - 3 * mX2 + 1)
    b = 6 * (mX2 - 2 * mX1)
    c = 3 * mX1

    a2 = a * a
    b2 = b * b

    d = b / a
    e = (3 * b * c) / a2 - (b2 * b) / (a2 * a)
    w1 = (2 * c) / a - b2 / a2
    w = w1 * w1 * w1
    o = 3 / a

    ay = 3 * mY1 - 3 * mY2 + 1
    by = mY2 - 2 * mY1
    cy = 3 * mY1

    X2T = a == 0 and easings.linear or x2t

    return function(x)
        return Y(X2T(x, e, o, w, d), ay, by, cy)
    end
end

    --======CONSTRUCTOR======--

function Easings:back(direction)
    TypeError:assert(type(direction) == "string", "direction", type(direction), "string")

    direction = direction:lower()

    InvalidError:assert(directions_lut[direction], direction, "direction", directions)

    internal = math.uuid()

    return self {
        type      = "back",
        internal  = internal,
        direction = direction
    }
end

function Easings:cubic(direction)
    TypeError:assert(type(direction) == "string", "direction", type(direction), "string")

    direction = direction:lower()

    InvalidError:assert(directions_lut[direction], direction, "direction", directions)

    internal = math.uuid()

    return self {
        type      = "cubic",
        internal  = internal,
        direction = direction
    }
end

function Easings:bezier(start, finish)
    TypeError:assert(type(start) == "vector", "start", type(start), "vector")
    TypeError:assert(type(finish) == "vector", "finish", type(finish), "vector")
    VectorSizeError:assert(start.size == 2, start.size, 2)
    VectorSizeError:assert(finish.size == 2, finish.size, 2)
    RangeError:assert(0 <= start.x and start.x <= 1, start.x, "start.x", 0, 1)
    RangeError:assert(0 <= finish.x and finish.x <= 1, finish.x, "finish.x", 0, 1)

    internal = math.uuid()

    return self {
        type      = "bezier",
        start     = start,
        finish    = finish,
        internal  = internal,
        direction = table.concat({ start.x, start.y, finish.x, finish.y }, ", ")
    }
end

function Easings:linear()
    internal = math.uuid()

    return self {
        type      = "linear",
        internal  = internal,
        direction = ""
    }
end

function Easings:bounce(direction)
    TypeError:assert(type(direction) == "string", "direction", type(direction), "string")

    direction = direction:lower()

    InvalidError:assert(directions_lut[direction], direction, "direction", directions)

    internal = math.uuid()

    return self {
        type      = "bounce",
        internal  = internal,
        direction = direction
    }
end

function Easings:quintic(direction)
    TypeError:assert(type(direction) == "string", "direction", type(direction), "string")

    direction = direction:lower()

    InvalidError:assert(directions_lut[direction], direction, "direction", directions)

    internal = math.uuid()

    return self {
        type      = "quintic",
        internal  = internal,
        direction = direction
    }
end

function Easings:elastic(direction)
    TypeError:assert(type(direction) == "string", "direction", type(direction), "string")

    direction = direction:lower()

    InvalidError:assert(directions_lut[direction], direction, "direction", directions)

    internal = math.uuid()

    return self {
        type      = "elastic",
        internal  = internal,
        direction = direction
    }
end

function Easings:quartic(direction)
    TypeError:assert(type(direction) == "string", "direction", type(direction), "string")

    direction = direction:lower()

    InvalidError:assert(directions_lut[direction], direction, "direction", directions)

    internal = math.uuid()

    return self {
        type      = "quartic",
        internal  = internal,
        direction = direction
    }
end

function Easings:circular(direction)
    TypeError:assert(type(direction) == "string", "direction", type(direction), "string")

    direction = direction:lower()

    InvalidError:assert(directions_lut[direction], direction, "direction", directions)

    internal = math.uuid()

    return self {
        type      = "circular",
        internal  = internal,
        direction = direction
    }
end

function Easings:quadratic(direction)
    TypeError:assert(type(direction) == "string", "direction", type(direction), "string")

    direction = direction:lower()

    InvalidError:assert(directions_lut[direction], direction, "direction", directions)

    internal = math.uuid()

    return self {
        type      = "quadratic",
        internal  = internal,
        direction = direction
    }
end

function Easings:sinusoidal(direction)
    TypeError:assert(type(direction) == "string", "direction", type(direction), "string")

    direction = direction:lower()

    InvalidError:assert(directions_lut[direction], direction, "direction", directions)

    internal = math.uuid()

    return self {
        type      = "sinusoidal",
        internal  = internal,
        direction = direction
    }
end

function Easings:exponential(direction)
    TypeError:assert(type(direction) == "string", "direction", type(direction), "string")

    direction = direction:lower()

    InvalidError:assert(directions_lut[direction], direction, "direction", directions)

    internal = math.uuid()

    return self {
        type      = "exponential",
        internal  = internal,
        direction = direction
    }
end

function Easings:new(opts)
    local p, ease 
    
    p = private[self]

    p.type      = opts.type
    p.direction = opts.direction
    
    p.ease = easings[p.type .. p.direction]

    --Memoize bezier functions. Use "direction" as the hash map, rather than
    --storing each value individually and looking it up that way, since the
    --values are locked into the closure.
    if not p.ease then
        private[Easings][p.direction] = private[Easings][p.direction] or bezier(
            opts.start.x, opts.start.y,
            opts.finish.x, opts.finish.y
        )

        p.ease = private[Easings][p.direction]
    end
end

    --======METHODS======--

    --======GETTERS======--
    
    --======SETTERS======--
    
    --======METAMETHODS======--

function Easings:__call(value)
    TypeError:assert(type(value) == "number", "value", type(value), "number")

    --Short circit if value is at the start or end; all easing functions
    --have the start and endpoints equal to a linear function. Otherwise,
    --it wouldn't really be an ease.
    if value <= 0 then return value end
    if value >= 1 then return value end

    return private[self].ease(value)
end

function Easings:__tostring()
    local p = private[self]

    return self:tostring(p.type, p.direction)
end

Easings.__type = "easing"

---@type Easings.Class
local Class = Object:create(Easings)

return Class