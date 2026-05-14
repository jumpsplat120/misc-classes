---@meta Image

---Image class.
---@class Image.Class
---@overload fun(): Image
local ImageClass = {}

---Stuff what you done see.
---@class Image : Classy.Object, Drawable.Mixin
---@field size Vector
---@field offset Vector
local Image = {}

---@param image any
---@param x any
---@param y any
function ImageClass:fromValues(image, x, y) end

function ImageClass:fromVector(image, position) end

function ImageClass:new(opts) end

function Image:draw() end

function Image:isVisible(...) end