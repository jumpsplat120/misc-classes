---@type Object
local Object
local Transform, private, is, Vector
local TypeError, VectorSizeError

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

is = require("lib.is")

Vector = require("classes.Vector")

VectorSizeError = require("classes.errors.VectorSizeError")
TypeError       = require("classes.errors.TypeError")

Transform = Object:extend()

    --======PRIVATE FUNCTIONS======--

    --======CONSTRUCTOR======--

function Transform:new()
    local p = private[self]

    p.transform = love.math.newTransform()
    p.inverse   = p.transform:inverse()
end

    --======METHODS======--

function Transform:apply()
    local p = private[self]
    
    love.graphics.applyTransform(p.transform)
    
    return self
end

function Transform:remove()
    local p = private[self]
    
    love.graphics.applyTransform(p.inverse)

    return self
end

function Transform:clone()
    local p, pr, result

    p = private[self]

    result = Transform()

    pr = private[result]

    pr.transform = p.transform:clone()
    pr.inverse   = pr.transform:inverse()

    return result
end

function Transform:invert(modify)
    local p, tmp

    p = private[self]

    if modify then
        tmp = p.inverse

        p.inverse   = p.transform
        p.transform = tmp

        return self
    end

    return self
        :clone()
        :invert(true)
end

function Transform:translateVector(vector, modify)
    local p = private[self]

    TypeError:assert(is(vector, Vector), "vector", type(vector), Vector)
    VectorSizeError:assert(vector.size == 2, vector.size, 2)

    if modify then
        return vector:setToValues(p.transform:transformPoint(vector.x, vector.y))
    end

    return Vector:fromValues(p.transform:transformPoint(vector.x, vector.y))
end

function Transform:inverseTranslateVector(vector, modify)
    local p = private[self]

    TypeError:assert(is(vector, Vector), "vector", type(vector), Vector)
    VectorSizeError:assert(vector.size == 2, vector.size, 2)

    if modify then
        return vector:setToValues(p.transform:inverseTransformPoint(vector.x, vector.y))
    end

    return Vector:fromValues(p.transform:inverseTransformPoint(vector.x, vector.y))
end

function Transform:translateValues(x, y)
    local p = private[self]

    TypeError:assert(is(x, "number"), "x", type(x), "number")
    TypeError:assert(is(y, "number"), "y", type(y), "number")

    return p.transform:transformPoint(x, y)
end

function Transform:inverseTranslateValues(x, y)
    local p = private[self]

    TypeError:assert(is(x, "number"), "x", type(x), "number")
    TypeError:assert(is(y, "number"), "y", type(y), "number")

    return p.transform:inverseTransformPoint(x, y)
end

function Transform:multiply(transform, modify)
    local p = private[self]

    TypeError:assert(is(transform, Transform), "transform", type(transform), Transform)

    if modify then
        p.inverse = p.transform
            :apply(private[transform].transform)
            :inverse()

        return self
    end
    
    return self
        :clone()
        :multiply(transform, true)
end

function Transform:rotate(angle, modify)
    local p = private[self]

    TypeError:assert(is(angle, "number"), "angle", type(angle), "number")

    if modify then
        p.inverse = p.transform
            :rotate(angle)
            :inverse()

        return self
    end
    
    return self
        :clone()
        :rotate(angle, true)
end

function Transform:scale(vector, modify)
    local p = private[self]

    TypeError:assert(is(vector, Vector), "vector", type(vector), Vector)
    VectorSizeError:assert(vector.size == 2, vector.size, 2)

    if modify then
        p.inverse = p.transform
            :scale(vector.x, vector.y)
            :inverse()

        return self
    end
    
    return self
        :clone()
        :scale(vector, true)
end

function Transform:shear(vector, modify)
    local p = private[self]

    TypeError:assert(is(vector, Vector), "vector", type(vector), Vector)
    VectorSizeError:assert(vector.size == 2, vector.size, 2)

    if modify then
        p.inverse = p.transform
            :shear(vector.x, vector.y)
            :inverse()

        return self
    end
    
    return self
        :clone()
        :shear(vector, true)
end

function Transform:translate(vector, modify)
    local p = private[self]

    TypeError:assert(is(vector, Vector), "vector", type(vector), Vector)
    VectorSizeError:assert(vector.size == 2, vector.size, 2)

    if modify then
        p.inverse = p.transform
            :translate(vector.x, vector.y)
            :inverse()

        return self
    end
    
    return self
        :clone()
        :translate(vector, true)
end

function Transform:matches(transform)
    local matrix

    TypeError:assert(is(transform, Transform), "transform", type(transform), Transform)

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
    TypeError:assert(is(value, "table"), "matrix", type(value), "table")

    for i, v in ipairs(value) do
        TypeError:assert(is(v, "number"), "matrix[" .. i .. "]", type(v), "number")
    end
    
    private[self].transform:setMatrix(table.unpack(value))
end

    --======METAMETHODS======--

function Transform:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper(p.transform:getMatrix()) end

    return self:tostringHelper("Class")
end

Transform.__type = "transform"

return Transform