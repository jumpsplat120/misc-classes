local Object, private
local Transform
local TypeError, TableLengthError

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

TypeError        = require("classes.errors.TypeError")
TableLengthError = require("classes.errors.TableLengthError")

Transform = Object:init()

    --======PRIVATE FUNCTIONS======--

    --======CONSTRUCTOR======--

function Transform:new(x, y, angle, sx, sy, ox, oy, kx, ky)
    local p = private[self]

    TypeError:assert(not x or type(x) == "number", "x", type(x), "number")
    TypeError:assert(not y or type(y) == "number", "y", type(y), "number")
    TypeError:assert(not sx or type(sx) == "number", "sx", type(sx), "number")
    TypeError:assert(not sy or type(sy) == "number", "sy", type(sy), "number")
    TypeError:assert(not ox or type(ox) == "number", "ox", type(ox), "number")
    TypeError:assert(not oy or type(oy) == "number", "oy", type(oy), "number")
    TypeError:assert(not kx or type(kx) == "number", "kx", type(kx), "number")
    TypeError:assert(not ky or type(ky) == "number", "ky", type(ky), "number")
    TypeError:assert(not angle or type(angle) == "number", "angle", type(angle), "number")

    p.transform = love.math.newTransform(
        x     or 0,
        y     or 0,
        angle or 0,
        sx    or 1,
        sy    or sx or 1,
        ox    or 0,
        oy    or 0,
        kx    or 0,
        ky    or 0
    )
end

    --======METHODS======--

function Transform:apply()
    local p = private[self]
    
    love.graphics.applyTransform(p.transform)
    
    return self
end

function Transform:clone()
    local result = getmetatable(self)()

    result.matrix = self.matrix

    return result
end

function Transform:identity()
    private[self].transform:setMatrix(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)

    return self
end

function Transform:invert()
    local p = private[self]
    
    p.transform = p.transform:inverse()

    return self
end

function Transform:transform(x, y)
    local p = private[self]

    TypeError:assert(type(x) == "number", "x", type(x), "number")
    TypeError:assert(type(y) == "number", "y", type(y), "number")

    return p.transform:transformPoint(x, y)
end

function Transform:inverseTransform(x, y)
    local p = private[self]

    TypeError:assert(type(x) == "number", "x", type(x), "number")
    TypeError:assert(type(y) == "number", "y", type(y), "number")

    return p.transform:inverseTransformPoint(x, y)
end

function Transform:multiply(transform)
    local p = private[self]

    TypeError:assert(type(transform) == "transform", "transform", type(transform), "transform")

    p.transform:apply(private[transform].transform)

    return self
end

function Transform:rotate(angle)
    local p = private[self]

    TypeError:assert(type(angle) == "number", "angle", type(angle), "number")

    p.transform:rotate(angle)

    return self
end

function Transform:scale(x, y)
    local p = private[self]

    y = y or x

    TypeError:assert(type(x) == "number", "x", type(x), "number")
    TypeError:assert(type(y) == "number", "y", type(y), "number")

    p.transform:scale(x, y)

    return self
end

function Transform:shear(x, y)
    local p = private[self]

    TypeError:assert(type(x) == "number", "x", type(x), "number")
    TypeError:assert(type(y) == "number", "y", type(y), "number")
    
    p.transform:shear(x, y)

    return self
end

function Transform:translate(x, y)
    local p = private[self]

    TypeError:assert(type(x) == "number", "x", type(x), "number")
    TypeError:assert(type(y) == "number", "y", type(y), "number")
    
    p.transform:translate(x, y)

    return self
end

function Transform:matches(transform)
    local matrix

    TypeError:assert(type(transform) == "transform", "transform", type(transform), "transform")

    matrix = transform.matrix

    for i, v in ipairs(self.matrix) do
        if matrix[i] ~= v then return false end
    end

    return true
end

    --======GETTERS======--

function Transform.__get:affine2DTransform()
    return private[self].transform:isAffine2DTransform()
end

function Transform.__get:matrix()
    return { private[self].transform:getMatrix() }
end

    --======SETTERS======--

function Transform.__set:matrix(value)
    TypeError:assert(type(value) == "table", "matrix", type(value), "table")
    TableLengthError:assert(#value == 16, 16, #value)
    
    for i, v in ipairs(value) do
        TypeError:assert(type(value), "matrix[" .. i .. "]", type(v), "number")
    end
    
    private[self].transform:setMatrix(value)
end

    --======METAMETHODS======--

function Transform:__tostring()
    return self:tostring(private[self].transform:getMatrix())
end

Transform.__type = "transform"

---@type Transform.Class
local Class = Object:create(Transform)

return Class