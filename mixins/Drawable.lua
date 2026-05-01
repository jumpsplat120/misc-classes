local Object, private, Symbol
local Drawable, is, Color, Vector
local TypeError, InvalidError, VectorSizeError

Object  = require("lib.Classy")
Symbol  = require("lib.Classy.Symbol")
private = require("lib.Classy.instances")

is = require("lib.is")

Color  = require("classes.Color")
Vector = require("classes.Vector")

VectorSizeError = require("classes.errors.VectorSizeError")
InvalidError    = require("classes.errors.InvalidError")
TypeError       = require("classes.errors.TypeError")

Drawable = Object:init()

    --======PRIVATE FUNCTIONS======--

local TRANSLATE, SHEAR, SCALE, ROTATE
local symbols, vec1, invert, oneOver

TRANSLATE = Symbol("translate")
ROTATE    = Symbol("rotate")
SHEAR     = Symbol("shear")
SCALE     = Symbol("scale")

private[Drawable] = {
    [TRANSLATE] = true,
    [ROTATE]    = true,
    [SHEAR]     = true,
    [SCALE]     = true
}

symbols = table.join(table.keys(private[Drawable]), ", ")

vec1 = Vector:fromValues(1, 1)

function invert(i, v)
    return i, v * -1
end

function oneOver(i, v)
    return i, 1 / v
end

    --======CONSTRUCTOR======--
--TODO: change Drawable to use a Transform internally, instead of each value being it's own
--thing.
function Drawable:new()
    local p = private[self]

    p.drawable = {
        rotation    = 0,
        color       = Color:fromRGB(1, 1, 1, 1),
        translation = Vector:fromValues(0, 0),
        origin    = Vector:fromValues(0, 0),
        shear     = Vector:fromValues(0, 0),
        scale     = Vector:fromValues(1, 1),
        order     = {
            "scale",
            "rotate",
            "translate",
            "shear"
        }
    }
end

    --======METHODS======--

function Drawable:order(a, b, c, d, e)
    local p = private[self]

    TypeError:assert(is(a, Symbol), "a", type(a), Symbol)
    TypeError:assert(is(b, Symbol), "b", type(b), Symbol)
    TypeError:assert(is(c, Symbol), "c", type(c), Symbol)
    TypeError:assert(is(d, Symbol), "d", type(d), Symbol)
    TypeError:assert(is(e, Symbol), "e", type(e), Symbol)

    InvalidError:assert(private[Drawable][a], a, "a", symbols)
    InvalidError:assert(private[Drawable][b], b, "b", symbols)
    InvalidError:assert(private[Drawable][c], c, "c", symbols)
    InvalidError:assert(private[Drawable][d], d, "d", symbols)
    InvalidError:assert(private[Drawable][e], e, "e", symbols)

    p.drawable.order = { a.id, b.id, c.id, d.id, e.id }

    return self
end

function Drawable:apply()
    local p = private[self].drawable

    p.color:apply()   
    
    love.graphics.translate(table.unpack(table.foreach(p.origin.table, invert)))
    
    for _, v in ipairs(p.order) do
        if v == "translate" then
            love.graphics.translate(p.translation:unpack())
        end

        if v == "rotate" then
            love.graphics.rotate(p.rotation)
        end

        if v == "scale" then
            love.graphics.scale(p.scale:unpack())
        end

        if v == "shear" then
            love.graphics.shear(p.shear:unpack())
        end
    end
end

function Drawable:remove()
    local p = private[self].drawable

    for i = #p.order, 1, -1 do
        local v = p.order[i]

        if v == "translate" then
            love.graphics.translate(table.unpack(table.foreach(p.translation.table, invert)))
        end

        if v == "rotate" then
            love.graphics.rotate(p.rotation * -1)
        end

        if v == "scale" then
            love.graphics.scale(table.unpack(table.foreach(p.scale.table, oneOver)))
        end

        if v == "shear" then
            love.graphics.shear(table.unpack(table.foreach(p.shear.table, invert)))
        end
    end

    love.graphics.translate(p.origin:unpack())
    
    p.color:remove()
end

    --======GETTERS======--

function Drawable.__get:color()
    return private[self].drawable.color
end

function Drawable.__get:origin()
    return private[self].drawable.origin
end

function Drawable.__get:rotation()
    return private[self].drawable.rotation
end

function Drawable.__get:translation()
    return private[self].drawable.translation
end

function Drawable.__get:shear()
    return private[self].drawable.shear
end

function Drawable.__get:scale()
    return private[self].drawable.scale
end

function Drawable.__get:TRANSLATE()
    if not self.instance then return TRANSLATE end

    return rawget(self, "TRANSLATE")
end

function Drawable.__get:ROTATE()
    if not self.instance then return ROTATE end

    return rawget(self, "ROTATE")
end

function Drawable.__get:SHEAR()
    if not self.instance then return SHEAR end

    return rawget(self, "SHEAR")
end

function Drawable.__get:SCALE()
    if not self.instance then return SCALE end

    return rawget(self, "SCALE")
end

    --======SETTERS======--

function Drawable.__set:color(value)
    TypeError:assert(is(value, Color), "color", type(value), Color)

    private[self].drawable.color = value
end

function Drawable.__set:origin(value)
    TypeError:assert(is(value, Vector), "origin", type(value), Vector)
    VectorSizeError:assert(value.size == 2, value.size, 2)

    private[self].drawable.origin = value
end

function Drawable.__set:rotation(value)
    TypeError:assert(is(value, "number"), "rotation", type(value), "number")

    private[self].drawable.rotation = value:cycle(0, math.tau)
end

function Drawable.__set:translation(value)
    TypeError:assert(is(value, Vector), "translation", type(value), Vector)
    VectorSizeError:assert(value.size == 2, value.size, 2)

    private[self].drawable.translation = value
end

function Drawable.__set:shear(value)
    TypeError:assert(is(value, Vector), "shear", type(value), Vector)
    VectorSizeError:assert(value.size == 2, value.size, 2)

    private[self].drawable.shear = value
end

function Drawable.__set:scale(value)
    TypeError:assert(is(value, Vector), "scale", type(value), Vector)
    VectorSizeError:assert(value.size == 2, value.size, 2)

    private[self].drawable.scale = value
end

    --======METAMETHODS======--

return Drawable