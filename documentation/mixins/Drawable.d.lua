---@meta Drawable

---A mixin that adds [color](lua://Color.Class) and a [transform](lua://Transform.Class) to an object. The object
---will still need to define it's own specific drawing logic.
---@class Drawable.Mixin
---@field color Color.Class A getter for the [color](lua://Color.Class) object. No setter exists for this field.
---@field transform Transform.Class A getter for the [transform](lua://Transform.Class) object. No setter exists for this field.
Drawable = {}

---Creates the entries in [private](lua://Classy.private) needed for Drawable to function. Call in it's parent class
---with `Drawable.new(self)`.
function Drawable:new() end

---Method meant to be called interally, which applies the [color](lua://Color.Class) and
---[transform](lua://Transform.Class). Since `apply` is a common method name, you will likely want to call this
---method with `Drawable.apply(self)`.
---@protected
function Drawable:apply() end