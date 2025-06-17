local Object
local Circle, private, Vector, is, Symbol, Drawable, Emitter
local TypeError, InvalidError

Symbol  = require("lib.Classy.Symbol")
Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Vector = require("classes.Vector")

Drawable = require("classes.mixins.Drawable")
Emitter  = require("classes.mixins.Emitter")

is = require("lib.is")

InvalidError = require("classes.errors.InvalidError")
TypeError    = require("classes.errors.TypeError")

Circle = Object:extend()

Circle:implement(Drawable, Emitter)

    --======PRIVATE FUNCTIONS======--

local FILL, LINE
local symbols

FILL = Symbol("fill")
LINE = Symbol("line")

private[Circle] = {
    [FILL] = true,
    [LINE] = true
}

symbols = table.join(table.keys(private[Circle]), ", ")

    --======CONSTRUCTOR======--

function Circle:new(a, b, c)
    local p = private[self]
    
    Drawable.new(self)
    
    if is(a, Vector) and is(b, "number") then
        p.position = a:clone()
        p.radius   = math.abs(b)
    elseif is(a, "number") and is(b, "number") and is(c, "number")  then
        p.position = Vector:fromValues(a, b)
        p.radius   = math.abs(b)
    else
        local ta, tb, tc

        ta = type(a)
        tb = type(b)
        tc = type(c)

        if ta == "vector" then
            TypeError:throw("b", tb, "number")
        else
            TypeError:assert(ta == "number", "a", ta, "number")
            TypeError:assert(tb == "number", "b", tb, "number")
            TypeError:throw("c", tc, "number")
        end
    end

    p.mode = LINE
end

    --======METHODS======--

function Circle:matches(circle)
    local p = private[self]

    return p.pos:matches(circle.pos) and p.size:matches(circle.size)
end

function Circle:contains(vector)
    local p = private[self]

    return (p.position.x - vector.x) ^ 2 + (p.position.y - vector.y) ^ 2 >= p.radius ^ 2
end

--function Circle:touching(circle)
--    local x, y, w, h, p
--
--    p = private[self]
--    x, y, w, h = circle:unpack()
--
--    return p.pos.x + p.size.x >= x and
--           p.pos.x <= x + w and
--           p.pos.y + p.size.y >= y and
--           p.pos.y <= y + h
--end

function Circle:draw()
    local p = private[self]

    Drawable.apply(self)
    
    love.graphics.circle(p.mode.id, p.position.x, p.position.y, p.radius)

    Drawable.remove(self)
end

function Circle:clone()
    local p = private[self]
    
    return Circle(p.pos:clone(), p.radius)
end

function Circle:unpack()
    local p = private[self]

    return p.position.x, p.position.y, p.radius
end

    --======GETTERS======--

function Circle.__get:x()
    return private[self].position.x
end

function Circle.__get:y()
    return private[self].position.y
end

function Circle.__get:position()
    return private[self].position
end

function Circle.__get:mode()
    return private[self].mode
end

function Circle.__get:FILL()
    if not self.instance then return FILL end

    return rawget(self, "FILL")
end

function Circle.__get:LINE()
    if not self.instance then return LINE end

    return rawget(self, "LINE")
end

    --======SETTERS======--

function Circle.__set:mode(value)
    TypeError:assert(is(value, Symbol), "mode", type(value), Symbol)
    InvalidError:assert(private[Circle][value], value, "mode", symbols)

    private[self].mode = value
end

    --======METAMETHODS======--

function Circle:__tostring()
    local p = private[self]

    return self:tostringHelper(p.position.x, p.position.y, p.radius)
end

Circle.__type = "circle"

return Circle
