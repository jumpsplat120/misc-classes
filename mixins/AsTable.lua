local Object, private
local AsTable

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

AsTable = Object:init()

function AsTable.__get:table()
    return { table.unpack(private[self].values) }
end

return AsTable