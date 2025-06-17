---@type Object
local Object
local Ipairs, private

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Ipairs = Object:extend()

Ipairs.__call = coroutine.wrap(function(self)
    local values = private[self].values or {}

    for i, v in ipairs(values) do
        coroutine.yield(i, v)
    end
end)

Ipairs.__type = "ipairs"

return Ipairs