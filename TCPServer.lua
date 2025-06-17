---@type Object
local Object
local TCPServer, private
local Emitter
local TypeError, SocketError
local is, TL
local socket

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Emitter = require("classes.mixins.Emitter")

SocketError = require("classes.errors.SocketError")
TypeError   = require("classes.errors.TypeError")

TL = require("lib.string_template")
is = require("lib.is")

socket = require("socket")

TCPServer = Object:extend()

TCPServer:implement(Emitter)

    --======PRIVATE FUNCTIONS======--

    --======CONSTRUCTOR======--

--Create a server listening on some arbitrary port and address using TCP.
function TCPServer:new(address, port)
    local p = private[self]

    TypeError:assert(is(port, "number") or is(port, "nil"), "port", type(port), "number/nil")
    TypeError:assert(is(address, "string"), "address", type(address), "string")
    
    p.port    = port or 0
    p.address = address
    p.server  = SocketError:assert(socket.tcp())
    p.running = true
    p.clients = {}

    p.termination_pattern = string.char(0):rep(4)

    SocketError:assert(p.server:bind(p.address, p.port))
    SocketError:assert(p.server:listen())

    p.server:settimeout(0)
    
    --If the port was not provided, then an ephemeral one is created.
    if p.port == 0 then
        p.port = select(2, p.server:getsockname())
    end
end

    --======METHODS======--

--Function to be placed in an update loop.
function TCPServer:update()
    local p, client, err, data, status, partial
    
    p = private[self]

    if not p.running then return self end

    --Check for new clients.
    client, err = p.server:accept()
    
    --We ignore timeouts, as we are setting the server's timeout to 0,
    --and checking it every update loop.
    SocketError:assert(client or err == "timeout", err)

    --If we have a new client, add it to the table.
    if client then
        client:settimeout(0)

        p.clients[client] = {} 
    end

    --Iterate through each client.
    for client, buffer in pairs(p.clients) do
        data, status, partial = client:receive("*a")
        
        --Sometimes, we don't get a full piece of data, and it can end up
        --in partial, usually along with a status as to why that happened.
        --we don't really care though. If there's data in data, we use that,
        --and if there's data in partial, we use that.
        data = data or partial

        --If we have data, then we add it to the buffer.
        if data then
            buffer[#buffer + 1] = data
            
            --If we found the termination pattern, then we dispatch
            --an event, and clear the buffer.
            if data:endswith(p.termination_pattern) then
                data = table.concat(buffer)

                p.clients[client] = {}

                self:dispatch("data", client, data)
                self:dispatchSync("data", client, data)
            end
        end

        --The client has closed the connection, so we can remove it
        --from the table.
        if status == "closed" then
            p.clients[client] = nil
        end
    end

    return self
end

--Close the server when you're done with it, freeing up the port and address.
--Once a server is closed, it can't be reopened. Dispatch an event for any
--partial data a client might have.
function TCPServer:close()
    local p, data
    
    p = private[self]

    p.running = false

    p.server:close()

    for client, buffer in pairs(p.clients) do
        if buffer then
            data = table.concat(buffer)

            self:dispatch("partial", data)
            self:dispatchSync("partial", data)
        end

        client:close()
    end

    return self
end

    --======GETTERS======--

function TCPServer.__get:ip()
    local p = private[self]

    return TL("%{address}:%{port}", {
        address = p.address,
        port    = p.port
    })
end

function TCPServer.__get:termination_pattern()
    return private[self].termination_pattern
end

function TCPServer.__get:running()
    return private[self].running
end

    --======SETTERS======--

function TCPServer.__set:termination_pattern(value)
    TypeError:assert(is(value, "string"), "termination_pattern", type(value), "string")

    private[self].termination_pattern = value
end

    --======METAMETHODS======--

function TCPServer:__tostring()
    if self.is_instance then return self:tostringHelper() end

    return self:tostringHelper("Class")
end

TCPServer.__type = "tcp_server"

return TCPServer