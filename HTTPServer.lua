---@type Object
local Object
local HTTPServer, private
local TCPServer
local Emitter
local TypeError
local is
local surl

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

TCPServer = require("classes.TCPServer")

Emitter = require("classes.mixins.Emitter")

TypeError = require("classes.errors.TypeError")

is = require("lib.is")

surl = require("socket.url")

HTTPServer = Object:extend()

HTTPServer:implement(Emitter)

    --======PRIVATE FUNCTIONS======--

local parse
local CRLF

CRLF = "\r\n"

--Whenever a response is received, parse out the request,
--and dispatch a more appropriate event. As well, give the
--user access to a function to respond appropriately, without
--having to manually write out a response.
function parse(_, self, client, data)
    local response, parts
    
    --We hold onto the raw response, just in case someone
    --wants to fiddle with it.
    response = {
        raw = data
    }
    
    data = data:split(CRLF)

    --Split the first line into it's parts
    parts = data[1]:split(" ")

    response.request_type = parts[1]
    response.protocol     = parts[3]
    response.headers      = {}

    --Every line other than the first (the path stuff)
    --and the last (the termination CRLF) are headers.
    for i, header in ipairs(data) do
        if i > 1 and i < #data then
            parts = header:split(": ")

            response.headers[parts[1]:lower()] = parts[2]
        end
    end

    --Convert path into parts using surl, and the host (sent as a header)
    response.url = surl.parse("http://" .. response.headers.host .. data[1]:after(" "):before(" "))
    
    self:dispatch("request", response, client)
    self:dispatchSync("request", response, client)
end

    --======CONSTRUCTOR======--

function HTTPServer:new(address, port)
    local p = private[self]

    TypeError:assert(is(port, "number") or is(port, "nil"), "port", type(port), "number/nil")
    TypeError:assert(is(address, "string"), "address", type(address), "string")

    p.tcp_server = TCPServer(address, port or 80)

    p.tcp_server.termination_pattern = CRLF:rep(2)

    p.tcp_server:onSync("data", parse, self)
end

    --======METHODS======--

--Function to be placed in an update loop.
function HTTPServer:update()
    private[self].tcp_server:update()

    return self
end

--Helper function for creating a standard HTML response to the client.
function HTTPServer:response(protocol, html)
    TypeError:assert(is(protocol, "string"), "protocol", type(protocol), "string")
    TypeError:assert(is(html, "string"), "html", type(html), "string")

    return table.concat({
        protocol .. " 200 OK",
        "Content-Length: " .. html:len(),
        "Content-Type: text/html",
        "",
        html,
        CRLF
    }, CRLF)
end

--Close the http server when you're done with it. Dispatch events for any
--partial data.
function HTTPServer:close()
    local p = private[self]

    p.tcp_server:close()

    return self
end

    --======GETTERS======--
    
function HTTPServer.__get:url()
    return "http://" .. private[self].tcp_server.ip
end

function HTTPServer.__get:running()
    return private[self].tcp_server.running
end

    --======SETTERS======--
    
    --======METAMETHODS======--

function HTTPServer:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper() end

    return self:tostringHelper("Class")
end

HTTPServer.__type = "http_server"

return HTTPServer