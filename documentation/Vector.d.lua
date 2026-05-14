---@meta Vector

---A vector is a table that contains an arbitrary amount of values, which can be treated as a quantity that
---has both a direction and magnitude.
---
---<img src="https://c.tenor.com/-bsYDmc6AqkAAAAC/tenor.gif" height=100 alt="Vector! Oh yeah!" />
---
---Vector math features heavily in game programming, and this class features all of the various functions
---that you'll likely need (and some you probably won't) during the process of moving something from
---point A to point B.
---@class Vector.Class
---@overload fun(): Vector
local VectorClass = {}

---@class Vector : Classy.Object, Unpack.Mixin, Ipairs.Mixin, AsTable.Mixin
---@field x number 
---@field y number 
---@field z number 
---@field r number 
---@field g number 
---@field b number 
---@field a number 
---@field size number 
---@field length number 
---@field magnitude number 
---@operator add(Vector|number): Vector
---@operator sub(Vector|number): Vector
---@operator mul(Vector|number): Vector
---@operator div(Vector|number): Vector
---@operator mod(Vector|number): Vector
---@operator pow(Vector|number): Vector
---@operator unm: Vector
---@operator len: number
local Vector = {}

---comment
---@param tbl any
---@return Vector
function VectorClass:fromTable(tbl) end

---comment
---@param ... unknown
---@return Vector
function VectorClass:fromValues(...) end

---comment
---@param opts any
function VectorClass:new(opts) end

---comment
---@param vector any
function Vector:setToVector(vector) end

---comment
---@param tbl any
function Vector:setToTable(tbl) end

---comment
---@param value any
function Vector:setToValue(value) end

---comment
---@param ... unknown
function Vector:setToValues(...) end

---comment
---@param vector any
function Vector:shiftByVector(vector) end

---comment
---@param tbl any
function Vector:shiftByTable(tbl) end

---comment
---@param ... unknown
function Vector:shiftByValues(...) end

---comment
---@param value any
function Vector:add(value) end

---comment
---@param value any
function Vector:subtract(value) end

---comment
---@param value any
function Vector:multiply(value) end

---comment
---@param value any
function Vector:divide(value) end

---comment
---@param value any
function Vector:modulo(value) end

---comment
---@param value any
function Vector:power(value) end

---comment
---@param vector any
function Vector:cross(vector) end

---comment
function Vector:invert() end

---comment
---@param vector any
function Vector:distance(vector) end

---comment
---@param value any
function Vector:dot(value) end

---comment
---@param vector any
---@param percentage any
function Vector:lerp(vector, percentage) end

---comment
---@param axis any
function Vector:reflect(axis) end

---comment
---@param surface any
function Vector:bounce(surface) end

---comment
---@param degrees any
function Vector:rotate2D(degrees) end

---comment
function Vector:normalize() end

---comment
function Vector:floor() end

---comment
function Vector:ceil() end

---comment
function Vector:round() end

---comment
function Vector:clone() end

---comment
---@param vector any
function Vector:matches(vector) end