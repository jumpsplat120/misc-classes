local Object, private
local Vector
local Unpack, Ipairs, AsTable
local varargs, type
local TypeError, VectorSizeError, ConstructorError, SizeError, SetOutOfBoundsError

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Unpack  = require("classes.mixins.Unpack")
Ipairs  = require("classes.mixins.Ipairs")
AsTable = require("classes.mixins.AsTable")

type    = require("lib.extended_types")
varargs = require("lib.varargs")

SizeError           = require("classes.errors.SizeError")
TypeError           = require("classes.errors.TypeError")
VectorSizeError     = require("classes.errors.VectorSizeError")
ConstructorError    = require("classes.errors.ConstructorError")
SetOutOfBoundsError = require("classes.errors.SetOutOfBoundsError")

Vector = Object:init()

private[Vector] = {}

    --======PRIVATE FUNCTIONS======--

local operations, internal
local magnitude, vecmath

--Helper function that calculates the magnitude of a vector. Assumes flat
--table of numbers. 
function magnitude(tbl)
    local result = 0

    for _, v in ipairs(tbl) do
        result = result + v * v
    end

    return math.sqrt(result)
end

--Helper function that encapsulates all the error checking and value setting
--that needs to be done for most math operations.
function vecmath(a, b, op, modify)
    local pa, pb, result, vector, vectors
    
    pa = private[a]
    pb = private[b]

    --V needs to be either a Vector or a number.
    if type(b) == "vector" then
        SizeError:assert(pa.size == pb.size, a, pa, b, pb)

        result, vector = operations[op](pa, pb, true)
    else
        TypeError:assert(type(b) == "number", "value", type(b), "vector/number")

        result, vector = operations[op](pa, b)
    end
    
    --Some math operations can return a single number.
    if not vector then return result end

    --If we're modifying the vector, then we want to update all the values.
    if modify then
        for i, v in ipairs(result) do
            pa.values[i] = v
        end

        pa.magnitude = nil

        return a
    end

    --Otherwise, we return a new vector.
    return getmetatable(a):fromTable(result)
end

--All the various math equations. Each function assumes tons, so they shouldn't
--be called directly. Instead, call vecmath, which handles the appropriate logic
--needed for each one.
operations = {
    add = function(a, b, vectors)
        local result = {}
        
        if vectors then
            for i, v in ipairs(a.values) do
                result[i] = v + b.values[i]
            end
        else
            for i, v in ipairs(a.values) do
                result[i] = v + b
            end
        end
    
        return result, true
    end,
    dot = function(a, b)
        local result = 0
        
        for i, v in ipairs(a.values) do
            result = result + v * b.values[i]
        end
    
        return result, false
    end,
    ceil = function(a)
        local result = {}

        for i, v in ipairs(a.values) do
            result[i] = math.ceil(v)
        end

        return result, true
    end,
    power = function(a, b, vectors)
        local result = {}
        
        if vectors then
            for i, v in ipairs(a.values) do
                result[i] = v ^ b.values[i]
            end
        else
            for i, v in ipairs(a.values) do
                result[i] = v ^ b
            end
        end
    
        return result, true
    end,
    cross = function(a, b)
        local av, bv
    
        av = a.values
        bv = b.values
    
        return {
            av[2] * bv[3] - av[3] * bv[2],
            av[3] * bv[1] - av[1] * bv[3],
            av[1] * bv[2] - av[2] * bv[1]
        }, false
    end,
    round = function(a)
        local result = {}

        for i, v in ipairs(a.values) do
            result[i] = math.round(v)
        end

        return result, true
    end,
    floor = function(a)
        local result = {}

        for i, v in ipairs(a.values) do
            result[i] = math.floor(v)
        end

        return result, true
    end,
    modulo = function(a, b, vectors)
        local result = {}
        
        if vectors then
            for i, v in ipairs(a.values) do
                result[i] = v % b.values[i]
            end
        else
            for i, v in ipairs(a.values) do
                result[i] = v % b
            end
        end
    
        return result, true
    end,
    divide = function(a, b, vectors)
        local result = {}
        
        if vectors then
            for i, v in ipairs(a.values) do
                result[i] = v / b.values[i]
            end
        else
            for i, v in ipairs(a.values) do
                result[i] = v / b
            end
        end
    
        return result, true
    end,
    subtract = function(a, b, vectors)
        local result = {}
        
        if vectors then
            for i, v in ipairs(a.values) do
                result[i] = v - b.values[i]
            end
        else
            for i, v in ipairs(a.values) do
                result[i] = v - b
            end
        end
    
        return result, true
    end,
    distance = function(a, b)
        local result = 0
    
        for i, v in ipairs(a.values) do
            result = result + (v - b.values[i]) * (v - b.values[i])
        end
    
        return math.sqrt(result), false
    end,
    multiply = function(a, b, vectors)
        local result = {}
        
        if vectors then
            for i, v in ipairs(a.values) do
                result[i] = v * b.values[i]
            end
        else
            for i, v in ipairs(a.values) do
                result[i] = v * b
            end
        end
    
        return result, true
    end
}

    --======CONSTRUCTOR======--

function Vector:fromTable(tbl)
    TypeError:assert(type(tbl) == "table", "tbl", type(tbl), "table")

    for i, v in ipairs(tbl) do
        TypeError:assert(type(v) == "number", "tbl[" .. tostring(i) .. "]", type(v), "number")
    end

    internal = math.uuid()

    return self {
        values   = tbl,
        internal = internal
    }
end

function Vector:fromValues(...)
    local values = {}

    for i, v in varargs(...) do
        TypeError:assert(type(v), "<...>[" .. tostring(i) .. "]", type(v), "number")

        values[i] = v
    end

    internal = math.uuid()

    return self {
        values   = values,
        internal = internal
    }
end

function Vector:new(opts)
    local p = private[self]
    
    ConstructorError:assert(opts.internal == internal, "Vector")

    Ipairs.new(self)
    
    p.values = {}

    for i, v in ipairs(opts.values) do
        p.values[i] = v
    end

    p.size = #p.values
end

    --======METHODS======--

--Set all values of this vector to the corresponding values from another vector.
function Vector:setToVector(vector)
    local pa, pb

    pa = private[self]
    pb = private[vector]

    TypeError:assert(type(vector) == "vector", "vector", type(vector), "vector")
    SizeError:assert(pa.size == pb.size, self, pa.size, vector, pb.size)

    for i, v in ipairs(pb.values) do
        pa.values[i] = v
    end

    pa.magnitude = nil

    return self
end

--Set all values of this vector to the corresponding values in a table.
function Vector:setToTable(tbl)
    local p, values
    
    p      = private[self]
    values = {}
    
    TypeError:assert(type(tbl) == "table", "tbl", type(tbl), "table")
    SizeError:assert(p.size, self, p.size, tbl, #tbl)

    --Validate all the values first before setting them.
    for i, v in ipairs(tbl) do
        TypeError:assert(type(v) == "number", "tbl[" .. tostring(i) .. "]", type(v), "number")

        values[i] = v
    end

    p.values    = values
    p.magnitude = nil

    return self
end

--Set all values of this vector to a specific value.
function Vector:setToValue(value)
    local p = private[self]
    
    TypeError:assert(type(value) == "number", "value", type(value), "number")

    --Validate all the values first before setting them.
    for i, _ in ipairs(p.values) do
        p.values[i] = value
    end

    p.magnitude = nil

    return self
end

--Set all values of this vector to the corresponding values provided.
function Vector:setToValues(...)
    local p, args
    
    p    = private[self]
    args = { ... }
    
    for i, v in varargs(...) do
        TypeError:assert(type(v) == "number", "<...>[" .. tostring(i) .. "]", type(v), "number")
    end

    SizeError:assert(p.size == #args, self, p.size, "<...>", #args)

    p.values    = args
    p.magnitude = nil

    return self
end

--Shift this vector by the corresponding values in another vector. This should
--be done instead of `vec1 = vec1 + vec2`, since it avoids needing to create a
--new vector.
function Vector:translateVector(vector)
    local pa, pb

    pa = private[self]
    pb = private[vector]

    TypeError:assert(type(vector) == "vector", "vector", type(vector), "vector")
    SizeError:assert(pa.size == pb.size, self, pa.size, vector, pb.size)

    for i, v in ipairs(pb.values) do
        pa.values[i] = pa.values[i] + v
    end

    pa.magnitude = nil

    return self
end

--Shift this vector by the corresponding values in a table. This should
--be done instead of `vec = vec + tbl`, since it avoids needing to create a
--new vector.
function Vector:translateTable(tbl)
    local p, values
    
    p      = private[self]
    values = {}
    
    TypeError:assert(type(tbl) == "table", "tbl", type(tbl), "table")
    SizeError:assert(p.size, self, p.size, tbl, #tbl)

    --Validate all the values first before setting them.
    for i, v in ipairs(tbl) do
        TypeError:assert(type(v) == "number", "tbl[" .. tostring(i) .. "]", type(v), "number")

        values[i] = p.values[i] + v
    end

    p.values    = values
    p.magnitude = nil

    return self
end

--Shift this vector by the corresponding values provided.
function Vector:translateValues(...)
    local p, args
    
    p    = private[self]
    args = { ... }
    
    
    --Validate all the values first before setting them.
    for i, v in varargs(...) do
        TypeError:assert(type(v) == "number", "<...>[" .. tostring(i) .. "]", type(v), "number")

        args[i] = p.values[i] + v
    end
    
    SizeError:assert(p.size == #args, self, p.size, "<...>", #args)

    p.values    = args
    p.magnitude = nil

    return self
end

function Vector:add(value)
    return vecmath(self, value, "add", true)
end

function Vector:subtract(value)
    return vecmath(self, value, "subtract", true)
end

function Vector:multiply(value)
    return vecmath(self, value, "multiply", true)
end

function Vector:divide(value)
    return vecmath(self, value, "divide", true)
end

function Vector:modulo(value)
    return vecmath(self, value, "modulo", true)
end

function Vector:power(value)
    return vecmath(self, value, "power", true)
end

function Vector:cross(vector)
    local sa, sb

    sa = private[self].size
    sb = private[self].size

    --The cross product must be done with two 3-length vectors explicitly. We only
    --need to run one VectorSize check, since if a and b are the same length, and a
    --is 3 long, then so is b.
    TypeError:assert(type(vector) == "vector", "vector", type(vector), "vector")
    SizeError:assert(sa == sb, self, sa, vector, sb)
    VectorSizeError:assert(sa == 3, sa, 3)

    return vecmath(self, vector, "cross", true)
end

function Vector:invert()
    return vecmath(self, -1, "multiply", true)
end

function Vector:distance(vector)
    TypeError:assert(type(vector) == "vector", "vector", type(vector), "vector")

    return vecmath(self, vector, "distance", false)
end

function Vector:dot(value)
    TypeError:assert(type(value) == "vector", "value", type(value), "vector")

    return vecmath(self, value, "dot", false)
end

--Shift this vector `percentage` percent towards `value`. 0% will be equal to `self`, while 100%
--will be equal to `value`. You can lerp beyond 0/100%, and the new vector will continue on a
--path parallel to the previous one.
function Vector:lerp(vector, percentage)
    local pa, pb, invert
    
    TypeError:assert(type(vector) == "vector", "vector", type(vector), "vector")
    TypeError:assert(type(percentage) == "number", "percentage", type(percentage), "number")

    pa = private[self]
    pb = private[vector]
    
    SizeError:assert(pa.size == pb.size, self, pa.size, vector, pb.size)

    invert = 1 - percentage

    for i, v in ipairs(pa.values) do
        pa.values[i] = v * invert + pb.values[i] * percentage
    end

    pa.magnitude = nil

    return self
end

--Reflect across a vector, which is treated as an axis.
function Vector:reflect(axis)
    TypeError:assert(type(axis) == "vector", "axis", type(axis), "vector")

    return self:bounce(axis):invert()
end

--Bounce off of a vector, which is treated as a surface.
function Vector:bounce(surface)
    --https://www.3dkingdoms.com/weekly/weekly.php?a=2
    local pa, pb, normal

    TypeError:assert(type(surface) == "vector", "surface", type(surface), "vector")

    pa = private[self]
    pb = private[surface]

    SizeError:assert(pa.size == pb.size, self, pa.size, surface, pb.size)

    normal = surface:clone():normalize()
    normal = 2 * self:dot(normal) * normal - self
    
    for i, v in ipairs(private[normal].values) do
        pa.values[i] = v
    end
    
    pa.magnitude = nil

    return self
end

function Vector:rotate2D(degrees)
    --https://matthew-brett.github.io/teaching/rotation_2d.html
    local p, cos, sin, x, y

    p = private[self]

    TypeError:assert(type(degrees) == "number", "degrees", type(degrees), "number")
    VectorSizeError:assert(p.size == 2, p.size, 2)

    cos = math.cos(degrees)
    sin = math.sin(degrees)

    x = cos * p.values[1] - sin * p.values[2]
    y = sin * p.values[1] + cos * p.values[2]

    p.values[1] = x
    p.values[2] = y

    p.magnitude = nil

    return self

end

function Vector:normalize()
    --Explicitly use the getter, since magnitude might not be memoized.
    return vecmath(self, self.magnitude, "divide", true)
end

function Vector:floor()
    return vecmath(self, self, "floor", true)
end

function Vector:ceil()
    return vecmath(self, self, "round", true)
end

function Vector:round()
    return vecmath(self, self, "round", true)
end

function Vector:clone()
    internal = math.uuid()
    
    return getmetatable(self) {
        values  = private[self].values,
        internal = internal
    }
end

function Vector:matches(vector)
    local pa, pb

    TypeError:assert(type(vector) == "vector", "vector", type(vector), "vector")
    
    pa = private[self]
    pb = private[vector]

    if pa.size ~= pb.size then
        return false
    end
    
    for i, v in ipairs(pa.values) do
        if v ~= pb.values[i] then
            return false
        end
    end
    
    return true
end

    --======GETTERS======--

function Vector.__get:x()
    return private[self].values[1]
end

function Vector.__get:y()
    return private[self].values[2]
end

function Vector.__get:z()
    return private[self].values[3]
end

function Vector.__get:r()
    return private[self].values[1]
end

function Vector.__get:g()
    return private[self].values[2]
end

function Vector.__get:b()
    return private[self].values[3]
end

function Vector.__get:a()
    return private[self].values[4]
end

function Vector.__get:size()
    return private[self].size
end

function Vector.__get:length()
    return self.magnitude
end

function Vector.__get:magnitude()
    local p = private[self]

    return p.magnitude or magnitude(p.values)
end

    --======SETTERS======--

function Vector.__set:x(value)
    TypeError:assert(type(value) == "number", "x", type(value), "number")

    private[self].values[1] = value
end

function Vector.__set:y(value)
    local p = private[self]

    TypeError:assert(type(value) == "number", "y", type(value), "number")
    SetOutOfBoundsError:assert(2 <= p.size, value, 1, p.size, 2)

    private[self].values[2] = value
end

function Vector.__set:z(value)
    local p = private[self]

    TypeError:assert(type(value) == "number", "z", type(value), "number")
    SetOutOfBoundsError:assert(3 <= p.size, value, 1, p.size, 3)

    private[self].values[3] = value
end

function Vector.__set:r(value)
    TypeError:assert(type(value) == "number", "r", type(value), "number")

    private[self].values[1] = value
end

function Vector.__set:g(value)
    local p = private[self]

    TypeError:assert(type(value) == "number", "g", type(value), "number")
    SetOutOfBoundsError:assert(2 <= p.size, value, 1, p.size, 2)

    private[self].values[2] = value
end

function Vector.__set:b(value)
    local p = private[self]

    TypeError:assert(type(value) == "number", "b", type(value), "number")
    SetOutOfBoundsError:assert(3 <= p.size, value, 1, p.size, 3)

    private[self].values[3] = value
end

function Vector.__set:a(value)
    local p = private[self]

    TypeError:assert(type(value) == "number", "a", type(value), "number")
    SetOutOfBoundsError:assert(4 <= p.size, value, 1, p.size, 4)

    private[self].values[4] = value
end

function Vector.__set:length(value)
    TypeError:assert(type(value) == "number", "length", type(value), "number")

    self.magnitude = value
end

function Vector.__set:magnitude(value)
    local p = private[self]
    
    TypeError:assert(type(value) == "number", "magnitude", type(value), "number")

    --Special case for 0; we simply set everything to zero, rather than needing to
    --do any math.
    if value == 0 then
        for i, _ in ipairs(p.values) do
            p.values[i] = 0
        end

        p.magnitude = 0

        return
    end

    self:normalize():multiply(value)

    p.magnitude = math.abs(value)
end

    --======METAMETHODS======--

function Vector:__add(value)
    if type(self) == "vector" then
        return vecmath(self, value, "add", false)
    end

    return vecmath(value, self, "add", false)
end

function Vector:__sub(value)
    if type(self) == "vector" then
        return vecmath(self, value, "subtract", false)
    end

    return vecmath(value, self, "subtract", false)
end

function Vector:__mul(value)
    if type(self) == "vector" then
        return vecmath(self, value, "multiply", false)
    end

    return vecmath(value, self, "multiply", false)
end

function Vector:__div(value)
    if type(self) == "vector" then
        return vecmath(self, value, "divide", false)
    end

    return vecmath(value, self, "divide", false)
end

function Vector:__mod(value)
    if type(self) == "vector" then
        return vecmath(self, value, "modulo", false)
    end

    return vecmath(value, self, "modulo", false)
end

function Vector:__pow(value)
    if type(self) == "vector" then
        return vecmath(self, value, "power", false)
    end

    return vecmath(value, self, "power", false)
end

function Vector:__unm()
    return vecmath(self, -1, "multiply", false)
end

function Vector:__len()
    return private[self].size
end

function Vector:__index(key)
    if type(key) == "number" then
        return private[self].values[key]
    end
end

function Vector:__newindex(key, value)
    local p = private[self]

    if type(key) == "number" then
        TypeError:assert(type(value) == "number", "value", type(value), "number")
        SetOutOfBoundsError:assert(key <= p.size, value, 1, p.size, key)
        
        private[self].values[key] = value
    end
end

function Vector:__tostring()
    return self:tostring(table.unpack(private[self].values))
end

Vector.__type = "vector"

---@type Vector.Class
local Class = Object:create(Vector, Unpack, Ipairs, AsTable)

return Class