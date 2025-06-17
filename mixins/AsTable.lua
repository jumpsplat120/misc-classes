---@type Object
local Object
local private, AsTable

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

AsTable = Object:extend()

function AsTable.__get:table()
    return { table.unpack(private[self].values or {}) }
end

AsTable.__type = "as_table"

return AsTable