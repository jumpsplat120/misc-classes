---@type Object
local Object
---@type Async
local Async
local Symbol, private, HTTP, is, json
local TypeError, InvalidError, UnsetError

Object  = require("lib.Classy")
Symbol  = require("lib.Classy.Symbol")
private = require("lib.Classy.instances")
is      = require("lib.is")

Async = require("classes.Async")
Error = require("classes.Error")

InvalidError = require("classes.errors.InvalidError")
UnsetError   = require("classes.errors.UnsetError")
TypeError    = require("classes.errors.TypeError")

json = require("third_party.json")

HTTP = Object:extend()

    --======PRIVATE FUNCTIONS======--

local GET, POST, FORM, JSON
local thread_body, symbols, encoding, content_type

GET  = Symbol("get")
POST = Symbol("post")
FORM = Symbol("x-www-form-urlencoded")
JSON = Symbol("json")

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

private[HTTP] = {
    methods = {
        [GET]  = true,
        [POST] = true
    },
    encoding = {
        [FORM] = true,
        [JSON] = true
    }
}

symbols = {
    methods = table.join(table.keys(private[HTTP].methods), ", "),
    encoding = table.join(table.keys(private[HTTP].encoding), ", ")
}

encoding = {
    [FORM] = function(data)
        return table.reduce(table.entries(data), function(_, a, b)
            return TL("%{b}%{a[1]}=%{a[2]}&", { a = a, b = b })
        end, "")
    end,
    [JSON] = function(data)
        return json.stringify(data)
    end
}

content_type = {
    [FORM] = "application/x-www-form-urlencoded",
    [JSON] = "application/json"
}

HTTPError = Error("http", "HTTP request has failed for unknown reason.")

    --======CONSTRUCTOR======--

function HTTP:new(url, headers, data, method)
    local p = private[self]

    TypeError:assert(is(url, "string"), "url", type(url), "string")
    TypeError:assert(not headers or is(headers, "table"), "headers", type(headers), "table")
    TypeError:assert(not data or is(data, "string") or is(data, "table"), "data", type(data), "string/table")
    TypeError:assert(not method or is(method, Symbol), "method", type(method), Symbol)

    for k, v in pairs(headers or {}) do
        TypeError:assert(is(k, "string"), "headers[<VALUE>]", type(k), "string")
        TypeError:assert(is(v, "string"), TL('headers["%{v}"]', { v = v }), type(v), "string")
    end

    if method then InvalidError:assert(private[HTTP].methods[method], method, "method", symbols.methods) end

    if data and is(data, "table") then
        UnsetError:assert(data.data, "data", "data")
        TypeError:assert(is(data.data, "table"), "data.data", type(data.data), "table")

        if data.encoding then
            TypeError:assert(is(data.encoding, Symbol), "data.encoding", type(data.encoding), Symbol)
            InvalidError:assert(private[HTTP].encoding[data.encoding], data.encoding, "data.encoding", symbols.encoding)

            data = encoding[data.encoding](data.data)

            headers = headers or {}
            
            if not headers["Content-Type"] then
                headers["Content-Type"] = content_type[data.encoding]
            end
        else
            data = encoding[JSON](data.data)

            headers = headers or {}
            
            if not headers["Content-Type"] then
                headers["Content-Type"] = content_type[JSON]
            end
        end
    end

    p.url     = url
    p.data    = data
    p.uuid    = math.uuid()
    p.thread  = love.thread.newThread(thread_body)
    p.headers = headers
end

    --======METHODS======--

function HTTP:fetch()
    local p, options, output
    
    p = private[self]

    options = {}

    channel = love.thread.getChannel(p.uuid)
    
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
    
    Async:waitFor(ready, p.thread)
    
    p.thread:start(p.url, options, p.uuid)

    output = Async:waitFor(channel.pop, channel)
    
    HTTPError:assert(output.code ~= 0)
    
    return output.code, output.data, output.headers
end

    --======GETTERS======--

function HTTP.__get:url()
    return private[self].url
end

function HTTP.__get:headers()
    local p = private[self]

    if not p.headers then p.headers = {} end
    
    return setmetatable(p.headers, {
        __newindex = function (tbl, k, v)
            TypeError:assert(is(k, "string"), "headers[<VALUE>]", type(k), "string")
            TypeError:assert(is(v, "string"), TL('headers["%{v}"]', { v = v }), type(v), "string")
            
            rawset(tbl, k, v)
        end
    })
end

function HTTP.__get:data()
    return private[self].data
end

function HTTP.__get:method()
    return private[self].method
end

function HTTP.__get:GET()
    if not self.is_instance then return GET end

    return self.GET
end

function HTTP.__get:POST()
    if not self.is_instance then return POST end

    return self.POST
end

function HTTP.__get:FORM()
    if not self.is_instance then return FORM end

    return self.FORM
end

function HTTP.__get:JSON()
    if not self.is_instance then return JSON end

    return self.JSON
end

    --======SETTERS======--

function HTTP.__set:url(value)
    TypeError:assert(is(value, "string"), "url", type(value), "string")

    private[self].url = value
end

function HTTP.__set:headers(value)
    local p = private[self]

    TypeError:assert(is(value, "table"), "headers", type(value), "table")

    for k, v in pairs(value) do
        TypeError:assert(is(k, "string"), "headers[<VALUE>]", type(k), "string")
        TypeError:assert(is(v, "string"), TL('headers["%{v}"]', { v = v }), type(v), "string")
    end

    p.headers = {}

    --Shallow copy avoids table from being modified after setting.
    --We don't give it a metatable to avoid overwriting one that
    --could already be there.
    for k, v in pairs(value) do p.headers[k] = v end
end

function HTTP.__set:data(value)
    TypeError:assert(is(value, "string") or is(value, "table") or is(value, "nil"), "data", type(value), "string/table")
    
    --TODO: Convert based on encoding type
    if is(value, "table") then value = json.stringify(value) end
    
    private[self].data = value
end

function HTTP.__set:method(value)
    TypeError:assert(is(value, Symbol), "method", type(value), Symbol)
    InvalidError:assert(private[HTTP].methods[value], value, "method", symbols.methods)

    private[self].method = value
end

    --======METAMETHODS======--

function HTTP:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper(p.url) end

    return self:tostringHelper("Class")
end

HTTP.__type = "http"

return HTTP