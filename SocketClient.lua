local Object, private
local SocketClient
local Emitter
local Error, Async
local socket
local msgpack
local TypeError, PositiveError

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Emitter = require("classes.mixins.Emitter")

Error = require("classes.Error")
Async = require("classes.Async")

socket = require("socket")

msgpack = require("third_party.msgpack")

TypeError     = require("classes.errors.TypeError")
PositiveError = require("classes.errors.PositiveError")

SocketClient = Object:init()

    --======PRIVATE FUNCTIONS======--

local SocketError, InvalidServerEventError
local add, now, send, event_responses, valid_events

SocketError = Error("socket", "%s")
InvalidServerEventError = Error("invalid_server_event", "The server sent a '%s' event, which isn't a valid server event.")

event_responses = {
    connected = function(p, uuid, baud)
        local time = now()
        
        p.server.rtt = { time }

        p.server.uuid         = uuid
        p.server.baud         = baud
        p.server.last_ping    = p.server.rtt[1]
        p.server.connected    = true
        p.server.average_rtt  = p.server.rtt[1]
        p.server.reconnecting = false

        p.server.timeout    = p.timeout + p.server.baud
        p.server.next_ping  = time + p.server.baud
        p.server.timeout_at = time + p.server.timeout

        send(p.udp, p.server.uuid, "ping")
    end,
    disconnected = function(p)
        p.server  = {}
        p.packets = {}
    end,
    ping = function(p)
        local time = now()

        p.server.last_ping = time

        table.insert(p.server.rtt, 1, p.server.last_ping)

        if #p.server.rtt > 5 then
            table.remove(p.server.rtt)
        end

        p.server.next_ping   = time + p.server.baud
        p.server.timeout_at  = time + p.server.timeout
        p.server.average_rtt = table.reduce(p.server.rtt, add) / #p.server.rtt
       
        send(p.udp, p.server.uuid, "ping")
    end
}

valid_events = {
    data = true,
    ping = true,
    rejected = true,
    connected = true,
    disconnected = true
}

--Add all the values in the table.
function add(_, a, b)
    return a + b
end

--This allows `SocketClient` to still work even if `love.timer` has been disabled.
--However, it won't do millsecond timing.
function now()
    if love and love.timer and love.timer.getTime() then
        return love.timer.getTime()
    end
    
    return os.time()
end

--Private sending function. This lets us provide an event type without also exposing
--that behaviour to the method. Otherwise, a user might be able to send their own
--pings or reconnects, confusing communication between server and client. There
--are only five events that should be ever sent; connect, disconnect, ping, data,
--and catchup.
--All data from the user comes during the data event. connect, disconnect, and ping
--are all sent internally as part of the server/client convo.
function send(udp, uuid, event, data)
    local out = {}
    
    out.uuid  = uuid
    out.event = event

    if event == "data" or event == "catchup" then
        out.data = data
    end

    if event == "connect" then
        out.ip   = data.ip
        out.port = data.port
    end

    udp:send(msgpack.encode(out))
end

    --======CONSTRUCTOR======--

--Timeout is in addition to the server baud rate. If the server pings every 60 seconds,
--then you aren't considered timed out until 60 + timeout.
--max_packet_rate is how many packets we will attempt to fetch every update loop. If
--multiple packets are recieved between one update tick and the next, then we fetch
--up to `max_packet_rate`, and leave the rest (if there are any) for the next update
--loop. This number should be balanced between the speed of the computer and the speed
--of the connection. A fast computer with a slow connection would set a high rate,
--since it'd be able to process all the packets every loop without causing client lag.
--A slow computer would decrease the rate, since they'd want to do less processing
--every loop, though this could cause possible client/server desync if the client can't
--keep up with the rate of data recieved. 
function SocketClient:new(timeout, max_packet_rate)
    local p = private[self]
    
    Emitter.new(self)

    max_packet_rate = max_packet_rate or 10

    TypeError:assert(type(timeout) == "number", "timeout", type(timeout), "number")
    TypeError:assert(type(max_packet_rate) == "number", "timeout", type(timeout), "number")
    PositiveError:assert(timeout > 0, "timeout")
    PositiveError:assert(max_packet_rate > 0, "max_packet_rate")

    p.udp             = SocketError:assert(socket.udp())
    p.server          = {}
    p.packets         = {}
    p.timeout         = timeout
    p.max_packet_rate = max_packet_rate

    p.udp:settimeout(0)
end

    --======METHODS======--
    
function SocketClient:connect(ip, port)
    local p = private[self]

    TypeError:assert(type(ip) == "string", "ip", type(ip), "string")
    TypeError:assert(type(port) == "number", "port", type(port), "number")

    SocketError:assert(p.udp:setpeername(ip, port))

    if p.server.connected or p.server.reconnecting then return self end

    p.ip, p.port, p.family = SocketError:assert(p.udp:getsockname())

    p.port = tonumber(p.port)

    send(p.udp, nil, "connect", {
        ip   = p.ip,
        port = p.port
    })

    p.server.connecting = true

    return self
end

function SocketClient:disconnect()
    local p = private[self]

    if not (p.server.connected or p.server.reconnecting) then return self end

    send(p.udp, p.server.uuid, "disconnect")

    p.server = {}

    return self
end

function SocketClient:send(data)
    local p = private[self]

    TypeError:assert(data ~= nil, "data", type(data), "any non-nil value")
    SocketError:assert(p.server.connected or p.server.reconnecting, "You must be connected to a server to send data.")

    if p.server.reconnecting then
        table.insert(p.packets, data)

        return self
    end

    send(p.udp, p.server.uuid, "data", data)

    return self
end

function SocketClient:update(dt)
    local p, time
    
    p    = private[self]
    time = now()

    if p.server.connected then
        if p.server.timeout_at < time then
            p.server.connected         = false
            p.server.reconnecting      = true
            p.server.reconnecting_at   = time + p.server.baud
            p.server.reconnect_attempt = 1

            self:dispatch("timeout")
            self:dispatchSync("timeout")
        end

        if #p.packets > 0 then
            send(p.udp, p.server.uuid, "catchup", p.packets)

            p.packets = {}
        end

        if p.server.next_ping < time then
            --TODO: Late ping! Do something prolly?
        end
    elseif p.server.reconnecting then
        if p.server.reconnecting_at < time then
            send(p.udp, p.server.uuid, "connect", {
                ip   = p.ip,
                port = p.port
            })

            p.server.reconnect_attempt = p.server.reconnect_attempt + 1
            p.server.reconnecting_at   = time + math.min(math.pow(p.server.baud, p.server.reconnect_attempt), p.server.timeout)

            self:dispatch("reconnect", p.server.reconnect_attempt, p.server.reconnecting_at)
            self:dispatchSync("reconnect", p.server.reconnect_attempt, p.server.reconnecting_at)
        end
    end
    
    if not (p.server.connected or p.server.reconnecting) and not p.server.connecting then return self end

    for i = 1, p.max_packet_rate, 1 do
        local data, err = p.udp:receive()

        if not data then return self end

        data = msgpack.decode(data)
        
        InvalidServerEventError:assert(valid_events[data.event], data.event)
        
        --The events `data` and `rejected` need no internal handling. By default, the server
        --won't reject the client; it'll only show up if someone's fucking around (like trying
        --to force a second connection to the server when already connected, or when flooding
        --the server with too much data). And ofc, data events are solely the responsibility
        --of the user.
        if data.event == "ping" then
            event_responses.ping(p)
        elseif data.event == "connected" then
            event_responses.connected(p, data.uuid, data.baud)
        elseif data.event == "disconnected" then
            event_responses.disconnected(p, data.reason)
        end

        self:dispatch(data.event, data)
        self:dispatchSync(data.event, data)
    end
end

    --======GETTERS======--
    
function SocketClient.__get:connected()
    local p = private[self]
    
    return p.server.connected or p.server.reconnecting
end

    --======SETTERS======--
    
    --======METAMETHODS======--

function SocketClient:__tostring()
    local p = private[self]

    return self:tostring()
end

SocketClient.__type = "socket_client"

---@type SocketClient.Class
local Class = Object:create(SocketClient, Emitter)

return Class