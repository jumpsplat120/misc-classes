---@type Object
local Object
local Polygon, private
local MouseInteractions, Drawable, Emitter
local Vector, Rectangle, Triangle
local TableAmountError, ParameterAmountError, ConstructorError
local VectorSizeError, InvalidError, TypeError
local varargs, is, TL

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

MouseInteractions = require("classes.mixins.MouseInteractions")
Drawable          = require("classes.mixins.Drawable")
Emitter           = require("classes.mixins.Emitter")

Rectangle = require("classes.Rectangle")
Triangle  = require("classes.Triangle")
Vector    = require("classes.Vector")

ParameterAmountError = require("classes.errors.ParameterAmountError")
TableAmountError     = require("classes.errors.TableAmountError")
ConstructorError     = require("classes.errors.ConstructorError")
VectorSizeError      = require("classes.errors.VectorSizeError")
InvalidError         = require("classes.errors.InvalidError")
TypeError            = require("classes.errors.TypeError")

varargs = require("lib.varargs")
is      = require("lib.is")
TL      = require("lib.string_template")

Polygon = Object:extend()

Polygon:implement(MouseInteractions, Drawable, Emitter)

    --======PRIVATE FUNCTIONS======--

local internal, classes

private[Polygon] = {
    Rectangle = function(shape)
        local t, x, y, w, h
        
        x, y, w, h = shape:unpack()

        t = { Vector:fromValues(x, y) }

        t[2] = t[1]:clone():shiftByValues(w, 0)
        t[3] = t[1]:clone():shiftByValues(w, h)
        t[4] = t[1]:clone():shiftByValues(0, h)

        return t
    end,
    Triangle = function(shape)
        local t, size
        
        t    = { shape.position:clone() }
        size = shape.size

        t[2] = t[1]:clone():shiftByValues(size, size * 0.5)
        t[3] = t[1]:clone():shiftByValues(0, size)

        return t
    end
}

classes = table.join(table.keys(private[Polygon]), ", ")

    --======CONSTRUCTOR======--

function Polygon:fromVectors(...)
    local t = {}

    for i, v in varargs(...) do
        TypeError:assert(is(v, Vector), TL("args[%{i}]", { i = i }), type(v), Vector)
        VectorSizeError:assert(v.size == 2, v.size, 2)

        t[i] = v
    end

    internal = math.uuid()

    return Polygon{
        vertices = t,
        verify   = internal
    }
end

function Polygon:fromValues(...)
    local t, tmp
    
    t = {}

    for i, v in varargs(...) do
        TypeError:assert(is(v, "number"), TL("args[%{i}]", { i = i }), type(v), "number")
        
        if not tmp then
            tmp = Vector:fromValues(v, 0)
        else
            tmp:setAt(v, 2)

            t[#t + 1] = tmp

            tmp = nil
        end
    end

    ParameterAmountError:assert(not tmp, "An even amount of", select("#", ...))

    internal = math.uuid()

    return Polygon{
        vertices = t,
        verify   = internal
    }
end

function Polygon:fromTable(tbl)
    local t, tmp
    
    TypeError:assert(is(tbl, "table"), "tbl", type(v), "table")

    t = {}

    for i, v in ipairs(tbl) do
        TypeError:assert(is(v, "number"), TL("args[%{i}]", { i = i }), type(v), "number")
        
        if not tmp then
            tmp = Vector:fromValues(v, 0)
        else
            tmp:setAt(v, 2)

            t[#t + 1] = tmp

            tmp = nil
        end
    end

    TableAmountError:assert(not tmp, "An even amount of", #tbl)

    internal = math.uuid()

    return Polygon{
        vertices = t,
        verify   = internal
    }
end

function Polygon:fromShape(shape)
    local t, mt, result, p, ps

    mt = getmetatable(shape)

    InvalidError:assert(private[Polygon][mt], mt, "shape", classes)

    t = private[Polygon][mt](shape)

    internal = math.uuid()

    result = Polygon{
        vertices = t,
        verify   = internal
    }
    
    p  = private[result]
    ps = private[shape]

    p.drawable.translation = ps.drawable.translation:clone()
    p.drawable.rotation    = ps.drawable.rotation
    p.drawable.origin = ps.drawable.origin:clone()
    p.drawable.color  = ps.drawable.color:clone()
    p.drawable.shear  = ps.drawable.shear:clone()
    p.drawable.scale  = ps.drawable.scale:clone()
    
    p.drawable.order = {}

    for i, v in ipairs(ps.drawable.order) do
        p[i] = v
    end

    return result
end

function Polygon:new(tbl)
    local p = private[self]

    ConstructorError:assert(tbl.verify == internal, "Polygon")

    Drawable.new(self)
    MouseInteractions.new(self)

    p.vertices = tbl.vertices
end

    --======METHODS======--


function Polygon:matches(polygon)
end

function Polygon:contains(vector)
end

function Polygon:touching(polygon)
end

function Polygon:vertex(index)
end

function Polygon:draw()
end

function Polygon:clone()
end

    --======GETTERS======--
    
    --======SETTERS======--
    
    --======METAMETHODS======--

function Polygon:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper() end

    return self:tostringHelper("Class")
end

Polygon.__type = "polygon"

return Polygon