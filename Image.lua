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

local internal, image_types_lut, image_types

internal = math.uuid()

image_types_lut = {
    string              = true,
    FileData            = true,
    ImageData           = true,
    CompressedImageData = true
}

image_types = table.join(table.keys(image_types_lut), ", ", " and ")

    --======CONSTRUCTOR======--

function Image:fromValues(image, x, y)
    local parsed, opts, t, image_ref

    t = type(image)

    TypeError:assert(type(x) == "number", "x", type(x), "number")
    TypeError:assert(type(y) == "number", "y", type(y), "number")
    TypeError:assert(image_types_lut[t], "image", t, image_types)

    internal = math.uuid()
    
    --If the image already exists in the private[Image] table, then we just use
    --that one, rather than recreating it. That way, if a user tries to create
    --100 copies of "character.png", it's only actually created a single time,
    --and simply referenced the other 99 times.
    image_ref = private[Image][image] or love.graphics.newImage(image)

    private[Image][image] = image_ref

    return self {
        path                  = t == "string" and image or nil,
        file_data             = t == "FileData" and image or nil,
        image_data            = t == "ImageData" and image or nil,
        compressed_image_data = t == "CompressedImageData" and image or nil,
        image    = image_ref,
        position = Vector:fromValues(x, y),
        internal = internal
    }
end

function Image:fromVector(image, position)
    local parsed, opts, t, image_ref

    t = type(image)

    TypeError:assert(type(position) == "vector", "position", type(position), "vector")
    TypeError:assert(image_types_lut[t], "image", t, image_types)

    VectorSizeError:assert(position.size == 2, position.size, 2)

    internal = math.uuid()
    
    --If the image already exists in the private[Image] table, then we just use
    --that one, rather than recreating it. That way, if a user tries to create
    --100 copies of "character.png", it's only actually created a single time,
    --and simply referenced the other 99 times.
    image_ref = private[Image][image] or love.graphics.newImage(image)

    private[Image][image] = image_ref

    return self {
        path                  = t == "string" and image or nil,
        file_data             = t == "FileData" and image or nil,
        image_data            = t == "ImageData" and image or nil,
        compressed_image_data = t == "CompressedImageData" and image or nil,
        image    = image_ref,
        position = position:clone(),
        internal = internal
    }
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

    Drawable.apply(self)

    love.graphics.draw(p.image, p.offset.x, p.offset.y)

    love.graphics.pop()

    return self
end

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
            transform:translateByVector(vector)
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