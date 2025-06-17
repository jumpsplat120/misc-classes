local Object
local Ellipse, private, Vector, is, Symbol, Drawable, Emitter
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

Ellipse = Object:extend()

Ellipse:implement(Drawable, Emitter)

    --======PRIVATE FUNCTIONS======--

local FILL, LINE
local symbols

FILL = Symbol("fill")
LINE = Symbol("line")

private[Ellipse] = {
    [FILL] = true,
    [LINE] = true
}

symbols = table.join(table.keys(private[Ellipse]), ", ")

    --======CONSTRUCTOR======--

function Ellipse:new(a, b, c, d)
    local p = private[self]
    
    Drawable.new(self)

    if is(a, Vector) and is(b, Vector) then
        p.position = a:clone()
        p.size     = b:clone()
    elseif is(a, "number") and is(b, "number") and is(c, Vector) then
        p.position = Vector:fromValues(a, b)
        p.size     = c:clone()
    elseif is(a, Vector) and is(b, "number") and is(c, "number") then
        p.position = a:clone()
        p.size     = Vector:fromValues(b, c)
    elseif is(a, "number") and is(b, "number") and is(c, "number") and is(d, "number") then
        p.position = Vector:fromValues(a, b)
        p.size     = Vector:fromValues(c, d)
    else
        local ta, tb, tc, td

        ta = type(a)
        tb = type(b)
        tc = type(c)
        td = type(d)

        if ta == "vector" then
            TypeError:assert(tb == "number" or tb == "vector", "b", tb, "number/Vector")
            TypeError:throw("c", tc, "Vector")
        elseif ta == "number" then
            TypeError:assert(tb == "number", "b", tb, "number")
            TypeError:assert(tc == "number" or tc == "vector", "c", tc, "number/Vector")
            TypeError:throw("d", td, "number")
        else
            TypeError:throw("a", ta, "number/Vector")
        end
    end

    p.mode = LINE
end

    --======METHODS======--

function Ellipse:set(position, size)
    local p = private[self]
    
    if position then p.position:setToVector(position) end
    if size     then p.size:setToVector(size)         end

    return self
end

function Ellipse:matches(ellipse)
    local p = private[self]

    return p.position:matches(ellipse.position) and p.size:matches(ellipse.size)
end

--function Ellipse:contains(vector)
--    local x, y, p
--
--    p    = private[self]
--    x, y = vector:unpack()
--
--    return x >= p.position.x and y >= p.position.y and x < p.position.x + p.size.x and y < p.position.y + p.size.y
--end

--function Ellipse:touching(ellipse)
--    local x, y, w, h, p
--
--    p = private[self]
--    x, y, w, h = ellipse:unpack()
--
--    return p.position.x + p.size.x >= x and
--           p.position.x <= x + w and
--           p.position.y + p.size.y >= y and
--           p.position.y <= y + h
--end

function Ellipse:draw()
    local p = private[self]

    Drawable.apply(self)
    
    love.graphics.ellipse(p.mode.id, p.position.x, p.position.y, p.size.x, p.size.y)

    Drawable.remove(self)
end

function Ellipse:clone()
    local p = private[self]
    
    return Ellipse(p.position:clone(), p.size:clone())
end

function Ellipse:unpack()
    local p = private[self]

    return p.position.x, p.position.y, p.size.x, p.size.y
end

    --======GETTERS======--

function Ellipse.__get:x()
    return private[self].position.x
end

function Ellipse.__get:y()
    return private[self].position.y
end

function Ellipse.__get:width()
    return private[self].size.x
end

function Ellipse.__get:height()
    return private[self].size.y
end

function Ellipse.__get:size()
    return private[self].size
end

function Ellipse.__get:position()
    return private[self].position
end

function Ellipse.__get:mode()
    return private[self].mode
end

function Ellipse.__get:FILL()
    if not self.instance then return FILL end

    return rawget(self, "FILL")
end

function Ellipse.__get:LINE()
    if not self.instance then return LINE end

    return rawget(self, "LINE")
end

--======SETTERS======--

function Ellipse.__set:mode(value)
    TypeError:assert(is(value, Symbol), "mode", type(value), Symbol)
    InvalidError:assert(private[Ellipse][value], value, "mode", symbols)

    private[self].mode = value
end

    --======METAMETHODS======--

function Ellipse:__tostring()
    local p = private[self]

    if self.is_instance then
        return self:tostringHelper(p.position.x, p.position.y, p.size.x, p.size.y)
    else
        return self:tostringHelper("Class")
    end
end

Ellipse.__type = "ellipse"

return Ellipse
