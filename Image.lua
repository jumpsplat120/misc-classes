local Object, private
local Image
local varargs
local Vector
local Drawable
local TypeError, VectorSizeError, ConstructorError

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

varargs = require("lib.varargs")

Vector = require("classes.Vector")

Drawable = require("classes.mixins.Drawable")

TypeError        = require("classes.errors.TypeError")
VectorSizeError  = require("classes.errors.VectorSizeError")
ConstructorError = require("classes.errors.ConstructorError")

Image = Object:init()

private[Image] = {}

    --======PRIVATE FUNCTIONS======--

local internal, image_types_lut, image_types, imagetype

internal = math.uuid()

image_types_lut = {
    string              = true,
    FileData            = true,
    ImageData           = true,
    CompressedImageData = true
}

image_types = table.join(table.keys(image_types_lut), ", ", " and ")

--Helper function that returns a table that contains the type of image it is,
--as well as the love image instance. For example, if the image is FileData,
--then it will return a table containing a key called `file_data` with the
--original value, and a key called `image` with the love image instance,
--whereas an `ImageData` would have a key called `image_data` instead. Memoizes
--images, so that if the same path has already been provided, then we use that
--love image instance, rather than creating a copy of it.
function imagetype(value)
    local t, result
    
    t = type(value)

    if t == "string" then
        result = { path = value }
    elseif t == "FileData" then
        result = { file_data = value }
    elseif t == "ImageData" then
        result = { image_data = value }
    elseif t == "CompressedImageData" then
        result = { compressed_image_data = value }
    end

    result.image = private[Image][value] or love.graphics.newImage(value)

    private[Image][value] = result.image

    return result
end


    --======CONSTRUCTOR======--

function Image:fromValues(image, x, y)
    local parsed, opts

    TypeError:assert(type(x) == "number", "x", type(x), "number")
    TypeError:assert(type(y) == "number", "y", type(y), "number")
    TypeError:assert(image_types_lut[type(image)], "image", type(image), image_types)

    parsed = imagetype(image)

    internal = math.uuid()
    
    opts = {
        position = Vector:fromValues(x, y),
        internal = internal
    }
    
    opts.path                  = parsed.path
    opts.image                 = parsed.image
    opts.file_data             = parsed.file_data
    opts.image_data            = parsed.image_data
    opts.compressed_image_data = parsed.compressed_image_data

    return self(opts)
end

function Image:fromVector(image, position)
    local parsed, opts

    TypeError:assert(type(position) == "vector", "position", type(position), "vector")
    TypeError:assert(image_types_lut[type(image)], "image", type(image), image_types)

    VectorSizeError:assert(position.size == 2, position.size, 2)

    parsed = imagetype(image)

    internal = math.uuid()
    
    opts = {
        position = position:clone(),
        internal = internal
    }

    opts.path                  = parsed.path
    opts.image                 = parsed.image
    opts.file_data             = parsed.file_data
    opts.image_data            = parsed.image_data
    opts.compressed_image_data = parsed.compressed_image_data

    return self(opts)
end

function Image:new(opts)
    local p = private[self]
    
    ConstructorError:assert(opts.internal == internal, "Image")

    Drawable.new(self)
    
    p.path                  = opts.path
    p.image                 = opts.image
    p.file_data             = opts.file_data
    p.image_data            = opts.image_data
    p.compressed_image_data = opts.compressed_image_data

    p.size   = Vector:fromValues(p.image:getDimensions())
    p.offset = Vector:fromValues(0, 0)

    p.drawable.transform:translate(opts.position)
end

    --======METHODS======--

function Image:draw()
    local p = private[self]

    love.graphics.push()

    self:drawable()

    love.graphics.draw(p.image, p.offset.x, p.offset.y)

    love.graphics.pop()

    return self
end

--Take any amount of transforms, and use them to determine if the image
--is within the bounds of the window. Uses the transforms in order, and 
--uses it's own internal transform last.
function Image:isVisible(...)
    local p, args, width, height, corners

    p = private[self]
    
    args = { ... }

    width, height = love.window.getMode()

    --We only need to checck the transforms once, so we do that before looping.
    for i, transform in varargs(...) do
        TypeError:assert(type(transform) == "transform", "<...>[" .. i .. "]", type(transform), "transform")
    end

    --Get each corner of the image's rectangle, pre-transformations.
    corners = {
        p.offset:clone(),
        p.offset + Vector:fromValues(p.size.x, 0),
        p.offset + Vector:fromValues(0, p.size.y),
        p.offset + p.size
    }

    --If any of the corners exist within the window, then we can break early
    --and return true. The method only verifies that the image is visible, not
    --that the image is fully within the window. This isn't 100% truly accurate,
    --since, if an image's bounding box doesn't actually have any art up to the
    --corner, it might not *literally* be visible. In the case of trying to cull
    --drawing images that don't exist, this works perfectly fine.
    for _, vector in ipairs(corners) do
        for _, transform in ipairs(args) do
            transform:translateVector(vector)
        end

        self.transform:transformVector(vector)

        if vector.x >= 0 and vector.y >= 0 and vector.x < width and vector.y < height then
            return true
        end
    end

    return false
end

    --======GETTERS======--

function Image.__get:size()
    return private[self].size
end

function Image.__get:offset()
    return private[self].offset
end

    --======SETTERS======--

    --======METAMETHODS======--

function Image:__tostring()
    local p = private[self]

    if p.path       then return self:tostring(p.path)           end
    if p.file_data  then return self:tostring("love.FileData")  end
    if p.image_data then return self:tostring("love.ImageData") end
    
    return self:tostring("love.CompressedImageData")
end

Image.__type = "image"

---@type Image.Class
local Class = Object:create(Image, Drawable)

return Class