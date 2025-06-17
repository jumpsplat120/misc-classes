---@type Object
local Object
local private, Unpack

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Unpack = Object:extend()

function Unpack:unpack()
    return table.unpack(private[self].values or {})
end

Unpack.__type = "unpack"

return Unpack