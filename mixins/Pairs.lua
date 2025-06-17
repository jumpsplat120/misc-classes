---@type Object
local Object
local Pairs, private

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Pairs = Object:extend()

Pairs.__call = coroutine.wrap(function(self)
    local values = private[self].values or {}

    for k, v in pairs(values) do
        coroutine.yield(k, v)
    end
end)

Pairs.__type = "pairs"

return Pairs