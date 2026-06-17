local Object, private
local Shader
local Error
local varargs
local FileError, TypeError, ParameterAmountError, CircularReferenceError

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

varargs = require("lib.varargs")

Error = require("classes.Error")

FileError              = require("classes.errors.FileError")
TypeError              = require("classes.errors.TypeError")
ParameterAmountError   = require("classes.errors.ParameterAmountError")
CircularReferenceError = require("classes.errors.CircularReferenceError")

Shader = Object:init()

--======PRIVATE FUNCTIONS======--

local SetOneError, InvalidShaderError, MissingUniformError
local resolveRelative, recursivelyInclude

SetOneError = Error("set_one", "Either a fragment shader or vertex shader must be passed; both can not be nil at the same time.")
InvalidShaderError = Error("invalid_shader", "%s")
MissingUniformError = Error("missing_uniform", "Attempted to send '%s' to '%s', but no such uniform/extern variable exists in the shader.")

function resolveRelative(paths)
    local result = {}

    for _, folder in ipairs(paths) do
        if folder == ".." then
            table.remove(result)
        else
            table.insert(result, folder)
        end
    end

    return table.concat(result, "/")
end

function recursivelyInclude(file, paths, loaded, loading)
    local path, include, included, result, newpaths
    
    result = {}

    for line in file:lines() do
        if line:startswith("#include") then
            line = line
                :after("#include")
                :trim()
                :gsub("\"", "")
            
            newpaths = table.imerge(paths, line:split("/"))
            path     = table.concat(newpaths, "/")

            if not loaded[path] then
                CircularReferenceError:assert(not loading[path])

                include = love.filesystem.newFile(resolveRelative(newpaths))

                FileError:assert(include:open("r"))

                loading[path] = true

                table.remove(newpaths)

                included = recursivelyInclude(include, newpaths, loaded, loading)

                loaded[path]  = included
                loading[path] = false
            else
                included = loaded[path]
            end

            table.insert(result, "// == START_INCLUDE <" .. path .. "> == //")
            table.insert(result, included)
            table.insert(result, "// == END_INCLUDE <" .. path .. "> == //")
        else
            table.insert(result, line)
        end
    end

    return table.concat(result, "\n")
end

--======CONSTRUCTOR======--

function Shader:new(fragment, vertex, glslES)
    local p, file, err, paths
    
    p = private[self]

    glslES = not not glslES

    TypeError:assert(vertex == nil or type(vertex) == "string", "vertex", type(vertex), "string/nil")
    TypeError:assert(fragment == nil or type(fragment) == "string", "fragment", type(fragment), "string/nil")
    SetOneError:assert(vertex or fragment)

    p.expects = {}

    p.type     = (fragment and vertex) and "combined" or fragment and "fragment" or "vertex"
    p.vertex   = vertex
    p.fragment = fragment

    if p.fragment then
        p.fragment_file = not not love.filesystem.getInfo(p.fragment, "file")
    end

    --Preprocess the shader, looking for `#include "path.to.file"`, and replacing it
    --with the contents of the actual file. Let's us "require" library files, since
    --LOVE doesn't have true include's.
    if p.vertex then
        if love.filesystem.getInfo(p.vertex, "file") then
            file = love.filesystem.newFile(p.vertex)

            FileError:assert(file:open("r"))
        else
            file = p.vertex
        end

        paths = p.vertex:split("/")

        table.remove(paths)

        p.vertex = recursivelyInclude(file, paths, {}, { [p.vertex] = true })
    end

    if p.fragment then
        if love.filesystem.getInfo(p.fragment, "file") then
            file = love.filesystem.newFile(p.fragment)

            FileError:assert(file:open("r"))
        else
            file = p.fragment
        end

        paths = p.fragment:split("/")

        table.remove(paths)

        p.fragment = recursivelyInclude(file, paths, {}, { [p.fragment] = true })
    end

    if p.vertex and not p.fragment then
        print(p.vertex)
        InvalidShaderError:assert(love.graphics.validateShader(glslES, p.vertex))
    end

    if p.fragment and not p.vertex then
        InvalidShaderError:assert(love.graphics.validateShader(glslES, p.fragment))
    end

    if p.fragment and p.vertex then
        InvalidShaderError:assert(love.graphics.validateShader(glslES, p.fragment, p.vertex))
    end

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