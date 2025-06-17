---@type Object
local Object
local Shader, private, varargs

Object  = require("lib.Classy")
private = require("lib.Classy.instances")
varargs = require("lib.varargs")

Shader = Object:extend()

--======PRIVATE FUNCTIONS======--

--======CONSTRUCTOR======--

function Shader:new(filename, stype)
    local p = private[self]

    p.filename = filename
    p.stype    = stype
    p.expects  = {}
    
    if not p.stype then
        if filename:endswith(".frag") then p.stype = "fragment" end
        if filename:endswith(".vert") then p.stype = "vertex" end
    end

    if not p.stype then return end

    p.shader = love.graphics.newShader(p.filename)
end

--======METHODS======--

function Shader:expect(...)
    local p = private[self]

    for _, v in varargs(...) do p.expects[#p.expects + 1] = v end

    return self
end

function Shader:send(...)
    local p = private[self]

    for i, v in varargs(...) do
        p.shader:send(p.expects[i], v)
    end

    return self
end

function Shader:apply()
    local p = private[self]
    
    p.previous = love.graphics.getShader()

    love.graphics.setShader(p.shader)

    return self
end

function Shader:remove()
    local p = private[self]

    love.graphics.setShader(p.previous)

    p.previous = nil

    return self
end

--======GETTERS======--

--======SETTERS======--

--======METAMETHODS======--

function Shader:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper(p.stype, p.filename) end

    return self:tostringHelper("Class")
end

Shader.__type = "shader"

return Shader