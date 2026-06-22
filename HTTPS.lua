local Object, private
local HTTPS
local Async
local json
local TypeError, InvalidError

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Async = require("classes.Async")

TypeError    = require("classes.errors.TypeError")
InvalidError = require("classes.errors.InvalidError")

json = require("third_party.json")

HTTPS = Object:init()

    --======PRIVATE FUNCTIONS======--

local thread_body, method_lut, encoding_lut, encodings
local methods_str, encoding_str, content_types
local HTTPSError

thread_body = [[
    local http, args, code, data, headers
    local url, data, options

    --DOES NOT WORK ON ZORIN AS OF AUG21st, 2024
    --Could maybe cheese it with io.popen("curl")
    https = require("https")
    args  = { ... }

    url     = args[1]
    options = args[2] or {}
    channel = love.thread.getChannel(args[3])

    code, data, headers = https.request(url, options)
    
    channel:push({ 
        code    = code,
        data    = data,
        headers = headers
    })
    
    return 1
]]

method_lut = {
    put     = true,
    get     = true,
    post    = true,
    head    = true,
    trace   = true,
    patch   = true,
    delete  = true,
    connect = true,
    options = true
}

encoding_lut = {
    form = true,
    json = true,
    text = true
}

encodings = {
    form = function(data)
        TypeError:assert(type(data) == "table", "data", type(data), "table")

        return table.reduce(table.entries(data), function(_, a, b)
            return string.format(
                "%s%s=%s&",
                b,
                a[1],
                a[2]
            )
        end, "")
    end,
    json = function(data)
        TypeError:assert(type(data) == "table", "data", type(data), "table")

        return json.stringify(data)
    end,
    text = function(data)
        TypeError:assert(type(data) == "string", "data", type(data), "string")

        return data
    end
}

content_types = {
    form = "application/x-www-form-urlencoded",
    json = "application/json",
    text = "text/plain"
}

methods_str  = table.join(table.keys(method_lut), ", ")
encoding_str = table.join(table.keys(encoding_lut), ", ")

HTTPSError = Error("http", "HTTPS request has failed for unknown reason.")

    --======CONSTRUCTOR======--

function HTTPS:new(url)
    local p = private[self]

    TypeError:assert(type(url) == "string", "url", type(url), "string")

    p.url     = url
    p.uuid    = math.uuid()
    p.thread  = love.thread.newThread(thread_body)
    p.headers = {}
end

    --======METHODS======--

function HTTPS:fetch()
    local p, options, output, channel
    
    p = private[self]

    options = {}

    channel = love.thread.getChannel(p.uuid)
    
    if p.method then
        options.method = p.method:upper()
    end

    if p.data then
        options.data   = p.data
        options.method = options.method or "POST"
    end

    if p.headers then
        options.headers = p.headers
    end
    
    p.thread:start(p.url, options, p.uuid)

    output = Async:waitFor(channel.pop, channel)
    
    return output.code, output.data, output.headers
end

function HTTPS:addHeader(name, value)
    TypeError:assert(type(name) == "string", "name", type(name), "string")
    TypeError:assert(type(value) == "string", "value", type(value), "string")

    private[self].headers[name] = value

    return self
end

function HTTPS:removeHeader(name)
    TypeError:assert(type(name) == "string", "name", type(name), "string")

    private[self].headers[name] = nil

    return self
end

function HTTPS:setData(data, encoding)
    local p = private[self]

    TypeError:assert(type(encoding) == "string", "encoding", type(encoding), "string")
    InvalidError:assert(encoding_lut[encoding], encoding, "encoding", encoding_str)

    p.data                    = encodings[encoding](data)
    p.headers["Content-Type"] = content_types[encoding]

    return self

end

function HTTPS:removeData()
    local p = private[self]

    p.data                    = nil
    p.headers["Content-Type"] = nil

    return self
end

    --======GETTERS======--

function HTTPS.__get:url()
    return private[self].url
end

function HTTPS.__get:headers()
    return private[self].headers
end

function HTTPS.__get:data()
    return private[self].data
end

function HTTPS.__get:method()
    return private[self].method
end

    --======SETTERS======--

function HTTPS.__set:url(value)
    TypeError:assert(type(value) == "string", "url", type(value), "string")

    private[self].url = value
end

function HTTPS.__set:method(value)
    TypeError:assert(type(value) == "string", "method", type(value), "string")
    
    InvalidError:assert(method_lut[value], value, "method", methods_str)

    private[self].method = value
end

    --======METAMETHODS======--

function HTTPS:__tostring()
    local p = private[self]

    return self:tostring(p.url)
end

HTTPS.__type = "https"

---@type HTTPS.Class
local Class = Object:create(HTTPS)

return Class