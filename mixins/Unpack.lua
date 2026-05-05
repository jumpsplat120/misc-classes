local Object, private
local Unpack

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

---@type Unpack.Mixin
Unpack = Object:init()

function Unpack:unpack()
    return table.unpack(private[self].values or {})
end

return Unpack