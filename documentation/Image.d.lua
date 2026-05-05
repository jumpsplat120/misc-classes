---@meta Image

---@class Image.Class : Classy.Object, Drawable.Mixin
---@field size Vector.Class
---@field offset Vector.Class
Image = {}

---@param image any
---@param x any
---@param y any
function Image:fromValues(image, x, y) end

function Image:fromVector(image, position) end

function Image:new(opts) end

function Image:draw() end

function Image:isVisible(...) end