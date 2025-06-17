---@type Object
local Object
local Image, private
local is, varargs
local Drawable, Vector
local TypeError, VectorSizeError

Object = require("lib.Classy")
private = require("lib.Classy.instances")

is = require("lib.is")
varargs = require("lib.varargs")

Drawable = require("classes.mixins.Drawable")
Vector   = require("classes.Vector")

TypeError = require("classes.errors.TypeError")
VectorSizeError = require("classes.errors.VectorSizeError")

Image = Object:extend()

Image:implement(Drawable)

    --======PRIVATE FUNCTIONS======--

    --======CONSTRUCTOR======--

function Image:new(image, a, b, c, d)
    local p = private[self]
    
    Drawable.new(self)

    if is(a, Vector) and is(b, Vector) then
        p.position = a:clone()
        p.size = b:clone()
    elseif is(a, "number") and is(b, "number") and is(c, Vector) then
        p.position  = Vector:fromValues(a, b)
        p.size = c:clone()
    elseif is(a, Vector) and is(b, "number") and is(c, "number") then
        p.position  = a:clone()
        p.size = Vector:fromValues(b, c)
    elseif is(a, "number") and is(b, "number") and is(c, "number") and is(d, "number") then
        p.position  = Vector:fromValues(a, b)
        p.size = Vector:fromValues(c, d)
    else
        local ta, tb, tc, td

        ta = type(a)
        tb = type(b)
        tc = type(c)
        td = type(d)

        if ta == "vector" then
            TypeError:assert(tb == "number" or tb == "vector", "b", tb, "number/Vector")
            TypeError:throw("c", tc, "Vector")
        elseif ta == "number" then
            TypeError:assert(tb == "number", "b", tb, "number")
            TypeError:assert(tc == "number" or tc == "vector", "c", tc, "number/Vector")
            TypeError:throw("d", td, "number")
        else
            TypeError:throw("a", ta, "number/Vector")
        end
    end

    if is(image, "FileData") then
        p.file_data = image
        p.image = love.graphics.newImage(p.file_data)
    end
    
    if is(image, "ImageData") then
        p.image_data = image
        p.image = love.graphics.newImage(p.image_data)
    end

    if is(image, "CompressedImageData") then
        p.compressed_image_data = image
        p.image = love.graphics.newImage(p.compressed_image_data)
    end

    if is(image, "string") then
        p.path  = image
        p.image = love.graphics.newImage(p.path)
    end

    TypeError:assert(p.image, "image", image, "string/CompressedImageData/ImageData/FileData")

    p.dims  = Vector:fromValues(p.image:getDimensions())
    p.scale = p.size / p.dims
end

    --======METHODS======--

function Image:set(position, size)
    local p = private[self]
    
    if position then
        p.position:setToVector(position)
    end
    
    if size then
        p.size:setToVector(size)
        p.scale:setToTable(Vector:staticDivide(p.size, p.dims))
    end

    return self
end

function Image:draw()
    local p = private[self]

    Drawable.apply(self)
    
    love.graphics.draw(p.image, p.position.x, p.position.y, 0, p.scale.x, p.scale.y)

    Drawable.remove(self)
end

--Pass in any amount of transforms, apply them to determine if the
--image is located within the bounds of the window. Takes into account
--it's own position and Drawable transform.
--NOTE: Does not take into account it's own scale property. That should
--honestly be removed anyways.
--NOTE: Does not take into account shear or rotate for Drawable, since there's
--no easy way to apply those vectors to another without making a whole ass 
--transform object.
--NOTE: This might be a bit lazy/may need to be updated once Drawable is
--updated to use a transform instead of a bunch of different Vectors
--NOTE 2: This assumes AABB, we should probably update to SAT checking for
--rotations and stuff. https://gamedev.stackexchange.com/questions/25397/obb-vs-obb-collision-detection
--TODO: Error checking
function Image:isVisible(...)
    local p, clone, width, height

    p = private[self]

    clone = p.position:clone()

    width, height = love.window.getMode()

    for _, transform in varargs(...) do
        clone = transform:translateVector(clone, true)
    end

    clone
        :shiftByVector(-p.drawable.origin)
        :shiftByVector(p.drawable.translation)

    return clone.x + p.size.x >= 0 and
           clone.y + p.size.y >= 0 and
           clone.x <= width and
           clone.y <= height
end

    --======GETTERS======--

function Image.__get:size()
    return private[self].size
end

function Image.__get:position()
    return private[self].position
end

    --======SETTERS======--

function Image.__set:size(value)
    local p = private[self]

    TypeError:assert(is(value, Vector), value, "size", Vector)

    p.size:setToVector(value)
    p.scale:setToTable(Vector:staticDivide(p.size, p.dims))
end

function Image.__set:position(value)
    TypeError:assert(is(value, Vector), "position", type(value), Vector)
    VectorSizeError:assert(value.size == 2, value.size, 2)

    private[self].position = value
end

    --======METAMETHODS======--

function Image:__tostring()
    local p = private[self]

    if self.is_instance then
        if p.path                  then return self:tostringHelper(p.path)                     end
        if p.image_data            then return self:tostringHelper("love.ImageData")           end
        if p.compressed_image_data then return self:tostringHelper("love.CompressedImageData") end
        if p.file_data             then return self:tostringHelper("love.FileData")            end
    end

    return self:tostringHelper("Class")
end

Image.__type = "image"

return Image