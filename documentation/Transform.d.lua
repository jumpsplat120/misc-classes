---@meta Transform

---@class Transform.Class : Classy.Object
---@field affine2DTransform boolean
---@field matrix number[]
Transform = {}

---comment
---@param x any
---@param y any
---@param angle any
---@param sx any
---@param sy any
---@param ox any
---@param oy any
---@param kx any
---@param ky any
function Transform:new(x, y, angle, sx, sy, ox, oy, kx, ky) end

---comment
function Transform:apply() end

---comment
function Transform:clone() end

---comment
function Transform:identity() end

---comment
function Transform:invert() end

---comment
---@param vector any
function Transform:transformVector(vector) end

---comment
---@param vector any
function Transform:inverseTransformVector(vector) end

---comment
---@param x any
---@param y any
function Transform:transformValues(x, y) end

---comment
---@param x any
---@param y any
function Transform:inverseTransformValues(x, y) end

---comment
---@param transform any
function Transform:multiply(transform) end

---comment
---@param angle any
function Transform:rotate(angle) end

---comment
---@param vector any
function Transform:scale(vector) end

---comment
---@param vector any
function Transform:shear(vector) end

---comment
---@param vector any
function Transform:translate(vector) end

---comment
---@param transform any
function Transform:matches(transform) end