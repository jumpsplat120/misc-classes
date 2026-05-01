local Object, private
local Ipairs

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Ipairs = Object:init()

Ipairs.__call = coroutine.wrap(function(self)
    for i, v in ipairs(private[self].values) do
        coroutine.yield(i, v)
    end
end)

return Ipairs