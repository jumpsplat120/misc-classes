---@type Object
local Object
local Vector, Drawable
local Line, private, is, TL
local ParameterAmountError, VectorSizeError, RangeError, TypeError

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Vector = require("classes.Vector")

Drawable = require("classes.mixins.Drawable")

TL = require("lib.string_template")
is = require("lib.is")

ParameterAmountError = require("classes.errors.ParameterAmountError")
VectorSizeError      = require("classes.errors.VectorSizeError")
RangeError           = require("classes.errors.RangeError")
TypeError            = require("classes.errors.TypeError")

Line = Object:extend()

Line:implement(Drawable)

    --======PRIVATE FUNCTIONS======--

local internal, extract

function extract(tbl)
    local result = {}

    for i, v in ipairs(tbl) do
        result[#result + 1] = v.x
        result[#result + 1] = v.y
    end

    return result
end

    --======CONSTRUCTOR======--

function Line:fromVectors(...)
    local args = { ... }

    args = #args == 1 and args[1] or args
    
    ParameterAmountError:assert(#args >= 2, "2 or more", #args)

    for i, vector in ipairs(args) do
        TypeError:assert(is(vector, Vector), TL("args[%{i}]", { i = i }), type(vector), Vector)
        VectorSizeError:assert(vector.size == 2, vector.size, 2)
    end

    internal = math.uuid()

    return Line{
        verify  = internal,
        vectors = args
    }
end

function Line:fromValues(...)
    local args, vectors
    
    vectors = {}
    args    = { ... }
    args    = #args == 1 and args[1] or args
    
    ParameterAmountError:assert(#args >= 4,     "4 or more",      #args)
    ParameterAmountError:assert(#args % 2 == 0, "an even amount", #args)

    for i = 1, #args, 2 do
        local x, y = args[i], args[i + 1]

        TypeError:assert(is(x, "number"), TL("args[%{i}]", { i = i }),     type(x), "number")
        TypeError:assert(is(y, "number"), TL("args[%{i}]", { i = i + 1 }), type(y), "number")

        vectors[#vectors + 1] = Vector:fromValues(x, y) 
    end

    internal = math.uuid()

    return Line{
        verify  = internal,
        vectors = vectors
    }
end

function Line:fromTables(...)
    local args, vectors
    
    vectors = {}
    args    = { ... }
    args    = #args == 1 and args[1] or args
    
    ParameterAmountError:assert(#args >= 4,     "4 or more",      #args)
    ParameterAmountError:assert(#args % 2 == 0, "an even amount", #args)

    for i, tbl in ipairs(args) do
        TypeError:assert(is(tbl, "table"),      TL("args[%{i}]",        { i = i }),         type(tbl),    "table")
        TypeError:assert(is(tbl[1], "number"),  TL("args[%{i}][%{ii}]", { i = i, ii = 1 }), type(tbl[1]), "number")
        TypeError:assert(is(tbl[2], "number"),  TL("args[%{i}][%{ii}]", { i = i, ii = 2 }), type(tbl[2]), "number")

        --We are ignoring any extra values, rather than passing it in as a table.
        --That way we don't have to do extra error checking, nor accidentally create
        --vectors of higher dimension.
        vectors[#vectors + 1] = Vector:fromValues(tbl[1], tbl[2])
    end

    internal = math.uuid()

    return Line{
        verify  = internal,
        vectors = vectors
    }
end

function Line:new(tbl)
    local p = private[self]

    ConstructorError:assert(tbl.verify == internal, "Line")

    Drawable.new(self)

    p.points   = tbl.vectors
    p.depth    = 5
    p.curvy    = false
end

    --======METHODS======--

function Line:addPoint(point, i)
    local p, len
    
    p   = private[self]
    len = #p.points + 1

    TypeError:assert(is(i, "number") or i == nil, "i", type(i), "number/nil")
    TypeError:assert(is(point, Vector), "point", type(point), Vector)
    VectorSizeError:assert(point.size == 2, point.size, 2)

    if i == nil then i = len end
    
    i = i < 0 and (len + i) or i

    RangeError:assert(i:between(1, len), "i", "i", 1, len)

    table.insert(p.points, i, point)

    return self
end

function Line:getPoint(i)
    local p, len
    
    p   = private[self]
    len = #p.points + 1

    TypeError:assert(is(i, "number"),  "i",  type(i),  "number")

    i = i < 0 and (len + i) or i

    RangeError:assert(i:between(1, len), "i", "i", 1, len)

    return p.points[i]
end

function Line:lerp(percentage, love)
    local p, points, distances, px, py, length, ratio

    p = private[self]

    TypeError:assert(is(percentage, "number"), "percentage", type(percentage), "number")
    RangeError:assert(percentage:between(0, 1), "percentage", "percentage", 0, 1)

    if percentage == 0 then return p.points[1]:clone()         end
    if percentage == 1 then return p.points[#p.points]:clone() end

    if p.curvy and not p.curve then self:recurve() end
    
    if p.curvy and love then
        return Vector:fromValues(p.curve:evaluate(percentage))
    end

    length    = 0
    points    = p.curvy and p.render or extract(p.points)
    distances = {}

    for i = 1, #points, 2 do
        local x, y = points[i], points[i + 1]

        if px then
            length = length + math.sqrt(math.pow(x - px, 2) + math.pow(y - py, 2))
        end
        
        distances[#distances + 1] = {
            length = length,
            x      = x,
            y      = y
        } 

        px = x
        py = y
    end
    
    ratio = length * percentage

    for i, distance in ipairs(distances) do
        if distance.length >= ratio then
            local prev = distances[i - 1]
            
            return Vector:fromTable(Vector:staticLerp(
                { distance.x, distance.y },
                { prev.x, prev.y },
                percentage:map(prev.length / length, distance.length / length, 0, 1)
            ))
        end
    end
end

function Line:getEquidistantPoints(density)
    local p, points, distances, px, py, length, ratio, percentage, result
    
    p = private[self]

    TypeError:assert(is(density, "number"), "density", type(density), "number")
    ParameterAmountError:assert(density >= 2, "2 or more", density)

    if density == 2 then return { p.points[1]:clone(), p.points[#p.points]:clone() } end

    if p.curvy and not p.curve then self:recurve() end

    length     = 0
    points     = p.curvy and p.render or extract(p.points)
    distances  = {}
    result     = {}
    percentage = 1 / density

    for i = 1, #points, 2 do
        local x, y = points[i], points[i + 1]

        if px then
            length = length + math.sqrt(math.pow(x - px, 2) + math.pow(y - py, 2))
        end
        
        distances[#distances + 1] = {
            length = length,
            x      = x,
            y      = y
        } 

        px = x
        py = y
    end
    
    result[#result + 1] = p.points[1]:clone()

    ratio = length * percentage

    for i, distance in ipairs(distances) do
        local prev = distances[i - 1]

        while distance.length >= ratio do
            result[#result + 1] = Vector:fromTable(Vector:staticLerp(
                { distance.x, distance.y },
                { prev.x, prev.y },
                percentage:map(prev.length / length, distance.length / length, 0, 1)
            ))

            percentage = percentage + (1 / density)
            ratio      = length * percentage
        end
    end

    result[#result + 1] = p.points[#p.points]:clone()

    return result
end

function Line:getSegment(min, max)
    local p, points, distances, px, py, length, ratio, result, start
    
    p = private[self]

    TypeError:assert(is(min, "number"), "min", type(min), "number")
    TypeError:assert(is(max, "number"), "max", type(max), "number")
    RangeError:assert(min:between(0, 1), "min", "min", 0, 1)
    RangeError:assert(max:between(0, 1), "max", "max", 0, 1)

    if min > max then
        local tmp = min
        
        min = max
        max = tmp
    end

    if min == 0 and max == 1 then self:clone() end

    if p.curvy and not p.curve then self:recurve() end

    length    = 0
    points    = p.curvy and p.render or extract(p.points)
    distances = {}
    result    = {}

    for i = 1, #points, 2 do
        local x, y = points[i], points[i + 1]

        if px then
            length = length + math.sqrt(math.pow(x - px, 2) + math.pow(y - py, 2))
        end
        
        distances[#distances + 1] = {
            length = length,
            x      = x,
            y      = y
        } 

        px = x
        py = y
    end
    
    ratio = length * min

    for i, distance in ipairs(distances) do
        if start and distance.length >= ratio then
            local prev = distances[i - 1]
            
            result[#result + 1] = Vector:fromTable(Vector:staticLerp(
                { distance.x, distance.y },
                { prev.x, prev.y },
                max:map(prev.length / length, distance.length / length, 0, 1)
            ))

            break
        end

        if start then
            result[#result + 1] = Vector:fromValues(distance.x, distance.y)
        end

        if not start and distance.length >= ratio then
            local prev = distances[i - 1]
            
            result[1] = Vector:fromTable(Vector:staticLerp(
                { distance.x, distance.y },
                { prev.x, prev.y },
                min:map(prev.length / length, distance.length / length, 0, 1)
            ))

            ratio = length * max
            start = true
        end
    end
    
    return Line:fromVectors(result)
end

function Line:recurve()
    local p = private[self]

    p.curve  = love.math.newBezierCurve(extract(p.points))
    p.render = p.curve:render(p.depth)

    return self
end

function Line:draw()
    local p, points
    
    p      = private[self]
    points = p.curvy and p.render or extract(p.points)

    Drawable.apply(self)

    love.graphics.line(points)

    Drawable.remove(self)

    return self
end

function Line:clone()
    local p, pc, points, clone
    
    p      = private[self]
    points = {}

    for i, v in ipairs(p.points) do
        points[i] = v:clone()
    end

    internal = math.uuid()
    clone    = Line{
        internal = internal,
        vectors  = points
    }

    pc = private[clone]

    pc.curvy = p.curvy
    pc.depth = p.depth

    if p.curvy then clone:recurve() end

    return clone
end
    
    --======GETTERS======--

--TODO: slope getter?

function Line.__get:points()
    return private[self].points
end

function Line.__get:curvy()
    return private[self].curvy
end

function Line.__get:curve()
    local p = private[self]

    if not p.curve then self:recurve() end

    return p.curve
end

function Line.__get:depth()
    return private[self].depth
end

function Line.__get:length()
    local p, tbl, px, py, d
    
    p = private[self]
    d = 0

    if p.curvy and not p.curve then self:recurve() end

    tbl = p.curvy and p.render or extract(p.points)

    for i = 1, #tbl, 2 do
        local x, y = tbl[i], tbl[i + 1]

        if px then
            d = d + math.abs(math.sqrt(math.pow(x - px, 2) + math.pow(y - py, 2)))
        end

        px = x
        py = y
    end

    return d
end

    --======SETTERS======--

function Line.__set:curvy(value)
    private[self].curvy = not not value
end

function Line.__set:depth(value)
    TypeError:assert(is(value, "number"), "depth", type(value), "number")
    RangeError:assert(value:between(1, math.huge), "depth", "depth", 1, math.huge)

    private[self].depth = value:round()
end

    --======METAMETHODS======--

function Line:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper(
        p.start,
        p.finish,
        p.curvy and "bezier" or "polyline"
    ) end

    return self:tostringHelper("Class")
end

Line.__type = "Line"

return Line