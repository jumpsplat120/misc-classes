---@type Object
local Object
---@type Async
local Async
local Symbol, private, HTTPS, is, TL, json
local TypeError, InvalidError

Object  = require("lib.Classy")
Symbol  = require("lib.Classy.Symbol")
private = require("lib.Classy.instances")

TL = require("lib.string_template")
is = require("lib.is")

Async = require("classes.Async")
Error = require("classes.Error")

InvalidError = require("classes.errors.InvalidError")
TypeError    = require("classes.errors.TypeError")

json = require("third_party.json")

HTTPS = Object:extend()

    --======PRIVATE FUNCTIONS======--

local PUT, GET, POST, HEAD, TRACE, PATCH, DELETE, CONNECT, OPTIONS
local FORM, JSON, TEXT
local thread_body, symbols, encodings

PUT     = Symbol("put")
GET     = Symbol("get")
POST    = Symbol("post")
HEAD    = Symbol("head")
TRACE   = Symbol("trace")
PATCH   = Symbol("patch")
DELETE  = Symbol("delete")
CONNECT = Symbol("connect")
OPTIONS = Symbol("options")

FORM = Symbol("x-www-form-urlencoded")
JSON = Symbol("json")
TEXT = Symbol("text")

local function ready(thread)
    return not thread:isRunning()
end

thread_body = [[
    local http, args, code, data, headers
    local url, data, options

    --DOES NOT WORK ON ZORIN AS OF AUG21st
    --Could maybe cheese it with io.popen("curl")
    https = require("https")
    args  = { ... }

    url     = args[1]
    options = args[2] or {}
    channel = love.thread.getChannel(args[3])

    code, data, headers = https.request(url, options)
    
    channel:push({ 
        code = code,
        data = data,
        headers = headers
    })
    
    return 1
]]

private[HTTPS] = {
    methods = {
        [PUT]     = true,
        [GET]     = true,
        [POST]    = true,
        [HEAD]    = true,
        [TRACE]   = true,
        [PATCH]   = true,
        [DELETE]  = true,
        [CONNECT] = true,
        [OPTIONS] = true
    },
    encoding = {
        [FORM] = true,
        [JSON] = true,
        [TEXT] = true
    }
}

symbols = {
    methods  = table.join(table.keys(private[HTTPS].methods), ", "),
    encoding = table.join(table.keys(private[HTTPS].encoding), ", ")
}

encodings = {
    [FORM] = function(data)
        TypeError:assert(is(data, "table"), "data", type(data), "table")

        return table.reduce(table.entries(data), function(_, a, b)
            return TL("%{b}%{a[1]}=%{a[2]}&", { a = a, b = b })
        end, "")
    end,
    [JSON] = function(data)
        TypeError:assert(is(data, "table"), "data", type(data), "table")

        return json.stringify(data)
    end,
    [TEXT] = function(data)
        TypeError:assert(is(data, "string"), "data", type(data), "string")

        return data
    end
}

content_types = {
    [FORM] = "application/x-www-form-urlencoded",
    [JSON] = "application/json",
    [TEXT] = "text/plain"
}

HTTPSError = Error("http", "HTTPS request has failed for unknown reason.")

    --======CONSTRUCTOR======--

function HTTPS:new(url)
    local p = private[self]

    TypeError:assert(is(url, "string"), "url", type(url), "string")

    p.url     = url
    p.uuid    = math.uuid()
    p.thread  = love.thread.newThread(thread_body)
    p.headers = {}
end

    --======METHODS======--

function HTTPS:fetch()
    local p, options, output
    
    p = private[self]

    options = {}

    channel = love.thread.getChannel(p.uuid)
    
    --GOTCHA: Rather than set p.method, we set options.method. That way,
    --the user can send data in a non-post method, if they so desire.
    --This may be unexpected, if the method has been force set to something
    --like GET ahead of time.
    if p.data then
        options.method = "POST"
        options.data   = p.data
    end

    if p.headers then
        options.headers = p.headers
    end

    if p.method then
        options.method = p.method.id:upper()
    end
    
    --Make sure there's not already an HTTPS request running. We can only really do
    --one at a time, since we reuse the thread. Might be worth considering a setup
    --in which lots of requests could be batched, but it hasn't been an issue so far.
    Async:waitFor(ready, p.thread)
    
    p.thread:start(p.url, options, p.uuid)

    --Wait until anything is returned.
    --GOTCHA: Errors are not captured, and will simply `print` the error output.
    --Could be worth considering refactoring Async so that errors are actually caught
    --and thrown, rather than just printed.
    --GOTCHA: If there's an error, then waitFor returns nothing. We need an empty
    --table so that the assert checks appropriately.
    output = Async:waitFor(channel.pop, channel) or {}
    
    HTTPSError:assert(output.code ~= 0)
    
    return output.code, output.data, output.headers
end

function HTTPS:addHeader(name, value)
    TypeError:assert(is(name, "string"), "name", type(name), "string")
    TypeError:assert(is(value, "string"), "value", type(value), "string")

    private[self].headers[name] = value

    return self
end

function HTTPS:removeHeader(name)
    TypeError:assert(is(name, "string"), "name", type(name), "string")

    private[self].headers[name] = nil

    return self
end

function HTTPS:setData(data, encoding)
    local p = private[self]

    TypeError:assert(is(encoding, Symbol), "encoding", type(encoding), Symbol)
    InvalidError:assert(private[HTTPS].encoding[encoding], encoding, "encoding", symbols.encoding)

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

function HTTPS.__get:PUT()
    return PUT
end

function HTTPS.__get:GET()
    return GET
end

function HTTPS.__get:POST()
    return POST
end

function HTTPS.__get:HEAD()
    return HEAD
end

function HTTPS.__get:TRACE()
    return TRACE
end

function HTTPS.__get:PATCH()
    return PATCH
end

function HTTPS.__get:DELETE()
    return DELETE
end

function HTTPS.__get:CONNECT()
    return CONNECT
end

function HTTPS.__get:OPTIONS()
    return OPTIONS
end

function HTTPS.__get:FORM()
    return FORM
end

function HTTPS.__get:JSON()
    return JSON
end

function HTTPS.__get:TEXT()
    return TEXT
end

    --======SETTERS======--

function HTTPS.__set:url(value)
    TypeError:assert(is(value, "string"), "url", type(value), "string")

    private[self].url = value
end

function HTTPS.__set:method(value)
    TypeError:assert(is(value, Symbol) or is(value, "nil"), "method", type(value), tostring(Symbol) .. "/nil")
    if value then InvalidError:assert(private[HTTPS].methods[value], value, "method", symbols.methods) end

    private[self].method = value
end

    --======METAMETHODS======--

function HTTPS:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper(p.url) end

    return self:tostringHelper("Class")
end

HTTPS.__type = "http"

return HTTPS