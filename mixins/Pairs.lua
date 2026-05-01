local Object, private
local Pairs

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Pairs = Object:init()

Pairs.__call = coroutine.wrap(function(self)
    local values = private[self].values or {}

    for k, v in pairs(values) do
        coroutine.yield(k, v)
    end
end)

return Pairs