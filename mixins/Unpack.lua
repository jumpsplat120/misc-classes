local Object, private
local Unpack

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Unpack = Object:init()

function Unpack:unpack()
    return table.unpack(private[self].values)
end

return Unpack