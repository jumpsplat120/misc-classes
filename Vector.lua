---@type Object
local Object
local Vector, private, Swizzle, Unpack, Ipairs, AsTable
local is, varargs
local TypeError, RangeError, VectorSizeError, ConditionalTypeError

Object   = require("lib.Classy")
private  = require("lib.Classy.instances")

Swizzle = require("classes.mixins.Swizzle")
AsTable = require("classes.mixins.AsTable")
Unpack  = require("classes.mixins.Unpack")
Ipairs  = require("classes.mixins.Ipairs")

is    = require("lib.is")
varargs = require("lib.varargs")

ConditionalTypeError = require("classes.errors.ConditionalTypeError")
ConstructorError = require("classes.errors.ConstructorError")
VectorSizeError  = require("classes.errors.VectorSizeError")
RangeError       = require("classes.errors.RangeError")
SizeError        = require("classes.errors.SizeError")
TypeError        = require("classes.errors.TypeError")

Vector = Object:extend()

Vector:implement(Swizzle, Unpack, Ipairs, AsTable)

private[Vector] = {}

    --======PRIVATE FUNCTIONS======--

local operations, internal, vec_or_num_error
local magnitude, vecmath, vectorlike, iterate

function magnitude(tbl)
    local result = 0

    for _, v in ipairs(tbl) do result = result + v * v end

    return math.sqrt(result)
end

function vecmath(a, b, op, modify)
    local p, result, isvec

    p = private[a]

    if is(b, Vector) then
        local pa, pb
        
        pa = p.size
        pb = private[b].size

        SizeError:assert(pa == pb, "vector", pa, "vector", pb)
    else
        TypeError:assert(is(b, "number"), "value", type(b), "number/" .. Vector)
    end
    
    result, isvec = operations[op](a, b)
    
    if not isvec then return result end

    if modify then
        for i, v in ipairs(result) do
            p.values[i] = v
        end

        return a
    end

    return Vector:fromTable(result)
end

function staticmath(a, b, avec, bvec, op)
    TypeError:assert(avec or is(a, "number"), "a", type(a), vec_or_num_error)
    TypeError:assert(bvec or is(b, "number"), "b", type(b), vec_or_num_error)
    ConditionalTypeError:assert(avec or bvec, "a", "number", "b is also of type 'number'.")

    if bvec then
        SizeError:assert(#a == #b, "vector", #a, "vector", #b)
    end
    
    return operations["static_" .. op](a, b, bvec)
end

function iterate(value)
    for i, v in ipairs(value) do
        if not is(v, "number") then return false, i, v end
    end

    return true
end

function vectorlike(value, name)
    if is(value, Vector) then return private[value].values, true end

    local tablelike, all_numbers, i, v = pcall(iterate, value)

    TypeError:assert(all_numbers, TL("%{name}[%{i}]", { name = name, i = i }), type(v), "number")

    return value, tablelike
end

operations = {
    add = function(a, b)
        local pa, pb, result
    
        pa     = private[a].values
        result = {}
        
        if is(b, Vector) then
            pb = private[b].values

            for i, v in ipairs(pa) do
                result[i] = v + pb[i]
            end
        else
            for i, v in ipairs(pa) do
                result[i] = v + b
            end
        end
    
        return result, true
    end,
    subtract = function(a, b)
        local pa, pb, result
    
        pa     = private[a].values
        result = {}
    
        if is(b, Vector) then
            pb = private[b].values

            for i, v in ipairs(pa) do
                result[i] = v - pb[i]
            end
        else
            for i, v in ipairs(pa) do
                result[i] = v - b
            end
        end
    
        return result, true
    end,
    divide = function(a, b)
        local pa, pb, result
    
        pa     = private[a].values
        result = {}
    
        if is(b, Vector) then
            pb = private[b].values

            for i, v in ipairs(pa) do
                result[i] = v / pb[i]
            end
        else
            for i, v in ipairs(pa) do
                result[i] = v / b
            end
        end
    
        return result, true
    end,
    multiply = function(a, b)
        local pa, pb, result
    
        pa     = private[a].values
        result = {}
    
        if is(b, Vector) then
            pb = private[b].values

            for i, v in ipairs(pa) do
                result[i] = v * pb[i]
            end
        else
            for i, v in ipairs(pa) do
                result[i] = v * b
            end
        end
    
        return result, true
    end,
    modulo = function(a, b)
        local pa, pb, result
    
        pa     = private[a].values
        result = {}
    
        if is(b, Vector) then
            pb = private[b].values

            for i, v in ipairs(pa) do
                result[i] = v % pb[i]
            end
        else
            for i, v in ipairs(pa) do
                result[i] = v % b
            end
        end
    
        return result, true
    end,
    power = function(a, b)
        local pa, pb, result
    
        pa     = private[a].values
        result = {}
    
        if is(b, Vector) then
            pb = private[b].values

            for i, v in ipairs(pa) do
                result[i] = v ^ pb[i]
            end
        else
            for i, v in ipairs(pa) do
                result[i] = v ^ b
            end
        end
    
        return result, true
    end,
    dot = function(a, b)
        local pa, pb, result
    
        pa     = private[a].values
        pb     = private[b].values
        result = 0
    
        for i, v in ipairs(pa) do
            result = result + v * pb[i]
        end
    
        return result, false
    end,
    cross = function(a, b)
        local pa, pb
    
        pa = private[a].values
        pb = private[b].values
    
        return {
            pa[2] * pb[3] - pa[3] * pb[2],
            pa[3] * pb[1] - pa[1] * pb[3],
            pa[1] * pb[2] - pa[2] * pb[1]
        }, false
    end,
    distance = function(a, b)
        local pa, pb, result
    
        pa     = private[a].values
        pb     = private[b].values
        result = 0
    
        for i, v in ipairs(pa) do
            result = result + (v - pb[i]) * (v - pb[i])
        end
    
        return math.sqrt(result), false
    end,
    round = function(a, b)
        local p, op, result
    
        p = private[a]

        result = {}

        op = b == 1 and "floor" or b == 2 and "ceil" or "round"

        for i, v in ipairs(p.values) do
            result[i] = math[op](v)
        end

        return result, true
    end,
    static_add = function(a, b, bvec)
        local result = {}
    
        if bvec then
            for i, v in ipairs(a) do
                result[i] = v + b[i]
            end
        else
            for i, v in ipairs(a) do
                result[i] = v + b
            end
        end
    
        return result
    end,
    static_subtract = function(a, b, bvec)
        local result = {}
    
        if bvec then
            for i, v in ipairs(a) do
                result[i] = v - b[i]
            end
        else
            for i, v in ipairs(a) do
                result[i] = v - b
            end
        end
    
        return result
    end,
    static_divide = function(a, b, bvec)
        local result = {}
    
        if bvec then
            for i, v in ipairs(a) do
                result[i] = v / b[i]
            end
        else
            for i, v in ipairs(a) do
                result[i] = v / b
            end
        end
    
        return result
    end,
    static_multiply = function(a, b, bvec)
        local result = {}
    
        if bvec then
            for i, v in ipairs(a) do
                result[i] = v * b[i]
            end
        else
            for i, v in ipairs(a) do
                result[i] = v * b
            end
        end
    
        return result
    end,
    static_modulo = function(a, b, bvec)
        local result = {}
    
        if bvec then
            for i, v in ipairs(a) do
                result[i] = v % b[i]
            end
        else
            for i, v in ipairs(a) do
                result[i] = v % b
            end
        end
    
        return result
    end,
    static_power = function(a, b, bvec)
        local result = {}
    
        if bvec then
            for i, v in ipairs(a) do
                result[i] = v ^ b[i]
            end
        else
            for i, v in ipairs(a) do
                result[i] = v ^ b
            end
        end
    
        return result
    end
}

NO_MODIFY = { modify = false }
MODIFY    = { modify = true  }
STATIC    = { static = true  }

    --======CONSTRUCTOR======--

function Vector:fromTable(tbl)
    TypeError:assert(is(tbl, "table"), "tbl", type(tbl), "table")

    for i, v in ipairs(tbl) do
        TypeError:assert(is(v, "number"), TL("tbl[%{i}]", { i = i }), type(v), "number")
    end

    internal = math.uuid()

    return Vector{
        internal = internal,
        values = tbl
    }
end

function Vector:fromValues(...)
    local tbl = {}

    for i, v in varargs(...) do
        TypeError:assert(is(v, "number"), TL("args[%{i}]", { i = i }), type(v), "number")

        tbl[i] = v
    end

    internal = math.uuid()

    return Vector{
        internal = internal,
        values = tbl
    }
end

function Vector:new(opts)
    local p = private[self]
    
    ConstructorError:assert(is(opts, "table") and opts.internal == internal, Vector)

    p.values = {}

    for i, v in ipairs(opts.values) do
        p.values[i] = v
    end

    p.size      = #p.values
    p.magnitude = magnitude(p.values)
end

    --======STATIC======--

function Vector:staticAdd(a, b)
    local avec, bvec

    a, avec = vectorlike(a, "a")
    b, bvec = vectorlike(b, "b")
    
    if (avec and bvec) or (avec and not bvec) then
        return staticmath(a, b, avec, bvec, "add")
    end

    return staticmath(b, a, bvec, avec, "add")
end

function Vector:staticSubtract(a, b)
    local avec, bvec

    a, avec = vectorlike(a, "a")
    b, bvec = vectorlike(b, "b")
    
    if (avec and bvec) or (avec and not bvec) then
        return staticmath(a, b, avec, bvec, "subtract")
    end

    return staticmath(b, a, bvec, avec, "subtract")
end

function Vector:staticMultiply(a, b)
    local avec, bvec

    a, avec = vectorlike(a, "a")
    b, bvec = vectorlike(b, "b")
    
    if (avec and bvec) or (avec and not bvec) then
        return staticmath(a, b, avec, bvec, "multiply")
    end

    return staticmath(b, a, bvec, avec, "multiply")
end

function Vector:staticDivide(a, b)
    local avec, bvec
    
    a, avec = vectorlike(a, "a")
    b, bvec = vectorlike(b, "b")
    
    if (avec and bvec) or (avec and not bvec) then
        return staticmath(a, b, avec, bvec, "divide")
    end

    return staticmath(b, a, bvec, avec, "divide")
end

function Vector:staticModulo(a, b)
    local avec, bvec

    a, avec = vectorlike(a, "a")
    b, bvec = vectorlike(b, "b")
    
    if (avec and bvec) or (avec and not bvec) then
        return staticmath(a, b, avec, bvec, "modulo")
    end

    return staticmath(b, a, bvec, avec, "modulo")
end

function Vector:staticPower(a, b)
    local avec, bvec

    a, avec = vectorlike(a, "a")
    b, bvec = vectorlike(b, "b")
    
    if (avec and bvec) or (avec and not bvec) then
        return staticmath(a, b, avec, bvec, "power")
    end

    return staticmath(b, a, bvec, avec, "power")
end

function Vector:staticLerp(a, b, percentage)
    local avec, bvec, result, invert

    a, avec = vectorlike(a, "a")
    b, bvec = vectorlike(b, "b")

    TypeError:assert(avec or is(a, "number"), "a", type(a), vec_or_num_error)
    TypeError:assert(bvec or is(b, "number"), "b", type(b), vec_or_num_error)
    ConditionalTypeError:assert(avec or bvec, "a", "number", "b is also of type 'number'.")
    TypeError:assert(is(percentage, "number"), "percentage", type(percentage), "number")
    SizeError:assert(#a == #b, "vector", #a, "vector", #b)

    invert = 1 - percentage
    result = {}
    
    for i, v in ipairs(a) do
        result[i] = v * percentage + b[i] * invert
    end

    return result
end

function Vector:staticReflect(a, b)
    local avec, bvec, normal, dot

    a, avec = vectorlike(a, "a")
    b, bvec = vectorlike(b, "b")

    TypeError:assert(avec or is(a, "number"), "a", type(a), vec_or_num_error)
    TypeError:assert(bvec or is(b, "number"), "b", type(b), vec_or_num_error)
    ConditionalTypeError:assert(avec or bvec, "a", "number", "b is also of type 'number'.")
    SizeError:assert(#a == #b, "vector", #a, "vector", #b)

    normal = Vector:staticDivide(b, magnitude(b))
    dot    = 0
    
    for i, v in ipairs(a) do dot = dot + v * normal[i] end

    return Vector:staticSubtract(Vector:staticMultiply(normal, 2 * dot), a)
end

    --======METHODS======--

function Vector:zero()
    local v = private[self].values

    for i, _ in ipairs(v) do v[i] = 0 end

    return self
end

function Vector:setToVector(vector)
    local pa, pb

    pa = private[self]
    pb = private[vector]

    TypeError:assert(is(vector, Vector), "vector", type(vector), Vector)
    SizeError:assert(pa.size == pb.size, "vector", pa.size, "vector", pb.size)

    for i, v in ipairs(pb.values) do
        pa.values[i] = v
    end

    pa.magnitude = magnitude(pa.values)

    return self
end

function Vector:setToTable(tbl)
    local p = private[self]
    
    TypeError:assert(is(tbl, "table"), "tbl", type(tbl), "table")
    SizeError:assert(p.size, "vector", p.size, "table", #tbl)

    for i, v in ipairs(tbl) do
        p.values[i] = v
    end

    p.magnitude = magnitude(p.values)

    return self
end

function Vector:setToValues(...)
    local p, amount, i, v, args
    
    amount = 0
    args   = { ... }
    p      = private[self]
    
    for ii, vv in varargs(...) do
        if not is(vv, "number") then
            i = ii
            v = vv

            break
        end

        amount = amount + 1
    end
    
    TypeError:assert(not i and not v, TL("args[%{i}]", { i = i }), type(v), "number")

    if amount == 1 then
        local value = args[1]

        for i, _ in ipairs(p.values) do
            p.values[i] = value
        end

        return self
    end

    SizeError:assert(p.size == amount, "vector", p.size, "args", amount)

    for i, v in ipairs(args) do
        p.values[i] = v
    end

    p.magnitude = magnitude(p.values)

    return self
end

function Vector:shiftByVector(vector)
    local pa, pb

    pa = private[self]
    pb = private[vector]

    TypeError:assert(is(vector, Vector), "vector", type(vector), Vector)
    SizeError:assert(pa.size == pb.size, "vector", pa.size, "vector", pb.size)

    for i, v in ipairs(pb.values) do
        pa.values[i] = pa.values[i] + v
    end

    pa.magnitude = magnitude(pa.values)

    return self
end

function Vector:shiftByTable(tbl)
    local p = private[self]
    
    TypeError:assert(is(tbl, "table"), "tbl", type(tbl), "table")
    SizeError:assert(p.size, "vector", p.size, "table", #tbl)

    for i, v in ipairs(tbl) do
        p.values[i] = p.values[i] + v
    end

    p.magnitude = magnitude(p.values)

    return self
end

function Vector:shiftByValues(...)
    local p, amount, i, v, args
    
    args = { ... }
    p    = private[self]
    
    amount = 0
    
    for ii, vv in varargs(...) do
        if not is(vv, "number") then
            i = ii
            v = vv

            break
        end

        amount = amount + 1
    end
    
    TypeError:assert(not i and not v, TL("args[%{i}]", { i = i }), type(v), "number")

    if amount == 1 then
        local value = args[1]

        for i, _ in ipairs(p.values) do
            p.values[i] = p.values[i] + value
        end

        return self
    end

    SizeError:assert(p.size == amount, "vector", p.size, "args", amount)

    for i, v in ipairs(args) do
        p.values[i] = p.values[i] + v
    end

    p.magnitude = magnitude(p.values)

    return self
end

function Vector:add(value, modify)
    return vecmath(self, value, "add", modify)
end

function Vector:subtract(value, modify)
    return vecmath(self, value, "subtract", modify)
end

function Vector:multiply(value, modify)
    return vecmath(self, value, "multiply", modify)
end

function Vector:divide(value, modify)
    return vecmath(self, value, "divide", modify)
end

function Vector:modulo(value, modify)
    return vecmath(self, value, "modulo", modify)
end

function Vector:power(value, modify)
    return vecmath(self, value, "power", modify)
end

function Vector:cross(value, modify)
    local pa, pb

    pa = private[self].size
    pb = private[self].size

    TypeError:assert(is(value, Vector), "vector", type(value), Vector)
    SizeError:assert(pa == pb, "vector", pa, "vector", pb)
    VectorSizeError:assert(pa == 3, pa, 3)

    return vecmath(self, value, "cross", modify)
end

function Vector:invert(modify)
    return vecmath(self, -1, "multiply", modify)
end

function Vector:distance(value)
    TypeError:assert(is(value, Vector), "vector", type(value), Vector)

    return vecmath(self, value, "distance", false)
end

function Vector:dot(value)
    TypeError:assert(is(value, Vector), "vector", type(value), Vector)

    return vecmath(self, value, "dot", false)
end

function Vector:lerp(value, percentage, modify)
    local pa, pb, bv, av, as, bs, result, invert
    
    TypeError:assert(is(value, Vector), "vector", type(value), Vector)
    TypeError:assert(is(percentage, "number"), "percentage", type(percentage), "number")

    pa = private[self]
    pb = private[value]

    as = pa.size
    bs = pb.size

    SizeError:assert(as == bs, "vector", as, "vector", bs)

    av = pa.values
    bv = pb.values

    result = {}
    invert = 1 - percentage

    if modify then
        for i, v in ipairs(av) do
            av[i] = v * percentage + bv[i] * invert
        end

        pa.magnitude = magnitude(av)

        return self
    end

    for i, v in ipairs(pa.values) do
        result[i] = v * percentage + bv[i] * invert
    end

    return Vector:fromTable(result)
end

function Vector:reflect(value, modify)
    --https://www.3dkingdoms.com/weekly/weekly.php?a=2
    local pa, pb, normal

    TypeError:assert(is(value, Vector), "vector", type(value), Vector)

    pa = private[self]
    pb = private[value]

    SizeError:assert(pa.size == pb.size, "vector", pa.size, "vector", pb.size)

    normal = value:clone():normalize()
    normal = 2 * self:dot(normal) * normal - self
    
    if modify then
        for i, v in ipairs(private[normal].values) do
            pa.values[i] = v
        end
        
        pa.magnitude = magnitude(pa.values)

        return self
    end

    return normal
end

function Vector:rotate2D(degrees, modify)
    --https://matthew-brett.github.io/teaching/rotation_2d.html
    local p, cos, sin, x, y

    TypeError:assert(is(degrees, "number"), "degrees", type(degrees), "number")
    
    p   = private[self]
    cos = degrees:cos()
    sin = degrees:sin()

    VectorSizeError:assert(#p.values == 2, #p.values, 2)

    x = cos * p.values[1] - sin * p.values[2]
    y = sin * p.values[1] + cos * p.values[2]

    if modify then
        p.values[1] = x
        p.values[2] = y

        p.magnitude = magnitude(p.values)

        return self
    end

    return Vector:fromValues(x, y)
end

function Vector:normalize(modify)
    return vecmath(self, private[self].magnitude, "divide", modify)
end

function Vector:floor(modify)
    return vecmath(self, 1, "round", modify)
end

function Vector:ceil(modify)
    return vecmath(self, 2, "round", modify)
end

function Vector:round(modify)
    return vecmath(self, 3, "round", modify)
end

function Vector:clone()
    internal = math.uuid()

    return Vector{
        internal = internal,
        values = private[self].values
    }
end

function Vector:matches(value)
    local pa, pb, vb

    TypeError:assert(is(value, Vector), "vector", type(value), Vector)
    
    pa = private[self]
    pb = private[value]

    if pa.size ~= pb.size then return false end

    vb = pb.values
    
    for i, v in ipairs(pa.values) do
        if v ~= vb[i] then return false end
    end
    
    return true
end

function Vector:setAt(value, i)
    local p = private[self]

    TypeError:assert(is(value, "number"), "value", type(value), "number")
    TypeError:assert(is(i, "number"), "i", type(i), "number")
    RangeError:assert(1 <= i and i <= p.size, i, "i", 1, p.size)

    p.values[i] = value

    return self
end

    --======GETTERS======--

function Vector.__get:magnitude()
    return private[self].magnitude
end

function Vector.__get:length()
    return self.__get:magnitude()
end

function Vector.__get:size()
    return private[self].size
end

    --======SETTERS======--

function Vector.__set:magnitude(value)
    local p = private[self]
    
    TypeError:assert(is(value, "number"), "magnitude", type(value), "number")

    if value == 0 then
        for i, _ in ipairs(p.values) do
            p.values[i] = 0
        end
    end

    vecmath(self, p.magnitude, "divide", true)
    vecmath(self, value, "multiply", true)

    p.magnitude = math.abs(value)
end

function Vector.__set:length(value)
    self.__set:magnitude(value)
end

    --======METAMETHODS======--

function Vector:__add(value)
    if is(self, Vector) then return vecmath(self, value, "add", false) end

    return vecmath(value, self, "add", false)
end

function Vector:__sub(value)
    if is(self, Vector) then return vecmath(self, value, "subtract", false) end

    return vecmath(value, self, "subtract", false)
end

function Vector:__mul(value)
    if is(self, Vector) then return vecmath(self, value, "multiply", false) end

    return vecmath(value, self, "multiply", false)
end

function Vector:__div(value)
    if is(self, Vector) then return vecmath(self, value, "divide", false) end

    return vecmath(value, self, "divide", false)
end

function Vector:__mod(value)
    if is(self, Vector) then return vecmath(self, value, "modulo", false) end

    return vecmath(value, self, "modulo", false)
end

function Vector:__pow(value)
    if is(self, Vector) then return vecmath(self, value, "power", false) end

    return vecmath(value, self, "power", false)
end

function Vector:__unm()
    return vecmath(self, -1, "multiply", false)
end

function Vector:__len()
    return private[self].size
end

function Vector:__tostring()
    if self.is_instance then
        return self:tostringHelper(table.unpack(table.foreach(private[self].values, function(i, v)
            return i, v == -0 and 0 or v
        end)))
    end

    return self:tostringHelper("Class")
end

Vector.__type = "vector"

--NOTE: This has to be down here, otherwise Vector doesn't have any the
--metavalues and it falls back to object, making for a very confusing
--error message.
vec_or_num_error = TL("%{Vector}/%{Vector}-like(table-like[implements ipairs] consisting only of numbers)/number", { Vector = Vector })

return Vector