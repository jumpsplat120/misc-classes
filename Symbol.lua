local Object, private
local Symbol

---@type Classy.BaseObject
Object = require(file_path)
---@type Classy.private
private = require(file_path .. ".instances")

Symbol = Object:init()

    --======PRIVATE FUNCTIONS======--

    --======STATIC======--

    --======CONSTRUCTOR======--

function Symbol:new(id)
    private[self].id = tostring(id or (math.uuid and math.uuid()) or math.random())
end

    --======METHODS======--

    --======GETTERS======--

function Symbol.__get:id() 
    return private[self].id
end

    --======SETTERS======--

    --======METAMETHODS======--

function Symbol:__tostring()
    return Object:tostring(private[self].id)
end

Symbol.__type = "symbol"

---@type Symbol.Class
local Class = Object:create(Symbol)

return Class
