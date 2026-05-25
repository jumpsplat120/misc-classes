local Object, private
local Shader
local Error
local varargs
local TypeError, FileError, ParameterAmountError

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

varargs = require("lib.varargs")

Error = require("classes.Error")

TypeError            = require("classes.errors.TypeError")
FileError            = require("classes.errors.FileError")
ParameterAmountError = require("classes.errors.ParameterAmountError")

Shader = Object:init()

--======PRIVATE FUNCTIONS======--

local SetOneError, InvalidShaderError, MissingUniformError

SetOneError = Error("set_one", "Either a fragment shader or vertex shader must be passed; both can not be nil at the same time.")
InvalidShaderError = Error("invalid_shader", "%s")
MissingUniformError = Error("missing_uniform", "Attempted to send '%s' to '%s', but no such uniform/extern variable exists in the shader.")

--======CONSTRUCTOR======--

function Shader:new(fragment, vertex, glslES)
    local p, code, err
    
    p = private[self]

    glslES = not not glslES

    TypeError:assert(vertex == nil or type(vertex) == "string", "vertex", type(vertex), "string/nil")
    TypeError:assert(fragment == nil or type(fragment) == "string", "fragment", type(fragment), "string/nil")
    SetOneError:assert(vertex or fragment)

    if vertex and not fragment then
        InvalidShaderError:assert(love.graphics.validateShader(glslES, vertex))
    end

    if fragment and not vertex then
        InvalidShaderError:assert(love.graphics.validateShader(glslES, fragment))
    end

    if fragment and vertex then
        InvalidShaderError:assert(love.graphics.validateShader(glslES, fragment, vertex))
    end

    p.expects = {}

    p.type     = (fragment and vertex) and "combined" or fragment and "fragment" or "vertex"
    p.vertex   = vertex
    p.fragment = fragment

    if p.type == "combined" then
        p.shader = love.graphics.newShader(p.fragment, p.vertex)
    else
        p.shader = love.graphics.newShader(p.fragment or p.vertex)
    end

    err = p.shader:getWarnings()

    InvalidShaderError:assert(err, err)
end

--======METHODS======--

function Shader:hasUniform(name)
    TypeError:assert(type(name) == "string", "name", type(name), "string")

    return private[self].shader:hasUniform(name)
end

function Shader:sendValue(name, ...)
    local p, args
    
    p     = private[self]
    args  = { ... }

    ParameterAmountError:assert(select("#", ...) > 0, "1 or more", "0")

    TypeError:assert(type(name) == "string", "name", type(name), "string")
    MissingUniformError:assert(p.shader:hasUniform(name), table.reduce(args, function(i, v, p) return i == 1 and tostring(v) or (p .. ", " .. tostring(v)) end, ""), name)

    p.shader:send(name, ...)

    return self
end

function Shader:sendColor(name, ...)
    local p, args, strval
    
    p     = private[self]
    args  = { ... }

    ParameterAmountError:assert(select("#", ...) > 0, "1 or more", "0")
    
    TypeError:assert(type(name) == "string", "name", type(name), "string")
    MissingUniformError:assert(p.shader:hasUniform(name), table.reduce(args, function(i, v, p) return i == 1 and tostring(v) or (p .. "/" .. tostring(v)) end, ""), name)

    for i, v in varargs(...) do
        TypeError:assert(type(v) == "color", "<...>[" .. i .. "]", type(v), "color")

        args[i] = v.table
    end

    p.shader:sendColor(name, table.unpack(args))

    return self
end

function Shader:apply()
    local p = private[self]

    love.graphics.setShader(p.shader)

    return self
end

--======GETTERS======--

--======SETTERS======--

--======METAMETHODS======--

function Shader:__tostring()
    local p = private[self]

    return self:tostring()
end

Shader.__type = "shader"

---@type Shader.Class
local Class = Object:create(Shader)

return Class