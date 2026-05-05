local Object, private
local Drawable
local Color, Transform

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Color     = require("classes.Color")
Transform = require("classes.Transform")

---@type Drawable.Mixin
Drawable = Object:init()

    --======PRIVATE FUNCTIONS======--

    --======CONSTRUCTOR======--

function Drawable:new()
    local p = private[self]

    p.drawable = {
        color     = Color:fromRGB(1, 1, 1, 1),
        transform = Transform()
    }
end

    --======METHODS======--

function Drawable:drawable()
    local p = private[self].drawable

    p.color:apply()   
    p.transform:apply()
end

    --======GETTERS======--

function Drawable.__get:color()
    return private[self].drawable.color
end

function Drawable.__get:transform()
    return private[self].drawable.transform
end

    --======SETTERS======--

    --======METAMETHODS======--

return Drawable