local Object, private
local SocketServer
local Emitter
local Error, Async
local socket
local msgpack
local TypeError, RangeError, PositiveError

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Emitter = require("classes.mixins.Emitter")

Error = require("classes.Error")
Async = require("classes.Async")

socket = require("socket")

msgpack = require("third_party.msgpack")

TypeError     = require("classes.errors.TypeError")
RangeError    = require("classes.errors.RangeError")
PositiveError = require("classes.errors.PositiveError")

SocketServer = Object:init()

    --======PRIVATE FUNCTIONS======--

local SocketError, InvalidPeerError
local now, send, ratelimit, event_responses, valid_events

SocketError      = Error("socket", "%s")
InvalidPeerError = Error("invalid_peer", "'%s' is not a currently connected peer.")

event_responses = {
    connect = function(p, ip, port)
        local time, uuid

        --If someone attempts to connect but is failing to build their data correctly,
        --we just ignore it. We only need to respond to valid peers, and they aren't
        --one yet.
        if not ip                 then return end
        if not port               then return end
        if type(ip) ~= "string"   then return end
        if type(port) ~= "number" then return end
        if port <= 0              then return end

        time = now()
        uuid = math.uuid()

        if #p.peers > p.max_peers then
            send(p.udp, "rejected", p.peers, "max_peers", {
                ip   = ip,
                port = port
            })
            
            return
        end

        if p.connections[ip .. ":" .. port] then
            send(p.udp, "rejected", p.peers, "already_connected", {
                ip   = ip,
                port = port
            })

            p.connections[ip .. ":" .. port].timeout = time + p.timeout

            return
        end

        p.peers[uuid] = {
            ip              = ip,
            port            = port,
            uuid            = uuid,
            timeout         = time + p.timeout,
            not_before      = time + p.ratelimit,
            ratelimit_count = 0
        }

        p.connections[ip .. ":" .. port] = p.peers[uuid]
        
        send(p.udp, "connected", p.peers, {
            uuid = uuid,
            baud = p.baud
        }, p.peers[uuid])

        return true
    end,
    disconnect = function(p, peer)
        send(p.udp, "disconnected", p.peers, "requested", peer)

        p.peers[peer]                    = nil
        p.connections[ip .. ":" .. port] = nil
    end,
    ping = function(p, peer)
        local time = now()

        peer.timeout = time + p.timeout

        if ratelimit(p, peer) then return end

        peer.ratelimit_count = math.max(peer.ratelimit_count - 1, 0)

        peer.not_before = time + p.ratelimit

        return true
    end,
    data = function(p, peer)
        peer.timeout = now() + p.timeout

        if ratelimit(p, peer) then return end

        return true
    end
}

--Handles ratelimit logic from any response from the client. Returns true if ratelimited.
function ratelimit(p, peer)
    local time = now()
    
    if peer.not_before < time then return end

    if peer.ratelimit_count > p.generosity then
        send(p.udp, "disconnected", p.peers, "too_many_ratelimits", peer)

        p.peers[peer]                              = nil
        p.connections[peer.ip .. ":" .. peer.port] = nil

        return true
    end

    send(p.udp, "rejected", p.peers, "ratelimit", peer)

    peer.ratelimit_count = peer.ratelimit_count + 1

    return true
end

--This allows `SocketServer` to still work even if `love.timer` has been disabled.
--However, it won't do millsecond timing.
function now()
    if love and love.timer and love.timer.getTime() then
        return love.timer.getTime()
    end
    
    return os.time()
end

function send(udp, event, peers, data, peer)
    local out = {}

    out.event = event
    
    if event == "rejected" or event == "disconnected" then
        out.reason = data
    end

    if event == "data" then
        out.data = data
    end

    if event == "connected" then
        out.uuid = data.uuid
        out.baud = data.baud
    end

    out = msgpack.encode(out)

    if peer then
        local success = pcall(udp.sendto, udp, out, peer.ip, peer.port)

        --sendto will only fail if "the underlying transport layer refuses to
        --send a message to the specified address (i.e. no interface accepts
        --the address)". Therefore we need to remove this peer, because
        --the info they gave us isn't valid.
        if not success then
            peers[peer.uuid] = nil
        end
    else
        for _, peer in pairs(peers) do
            local success = pcall(udp.sendto, udp, out, peer.ip, peer.port)
            
            if not success then
                peers[peer.uuid] = nil
            end
        end
    end
end

    --======CONSTRUCTOR======--

---comment
---@param timeout number How many seconds before the server decides a peer has disconnected.
---@param port number The port of the server. 0 for ephemeral.
---@param baud numer The rate at which the server pings connected peers. Defaults to 1 a second.
---@param max_peers number The maximum amount of peers allowed to be connected at one time. Defaults to 64.
---@param ratelimit number How frequently a client can send a message to the server. Must be less than `baud`. Defaults to four times per ping.
---@param generosity number How many times a client can hit the ratelimit before they're force disconnected. Hits are removed once a ping. Defaults to 5.
function SocketServer:new(timeout, port, baud, max_peers, ratelimit, generosity)
    local p = private[self]
    
    Emitter.new(self)

    baud       = baud      or 1
    max_peers  = max_peers or 64
    ratelimit  = ratelimit or baud * 0.25
    generosity = generosity or 5

    TypeError:assert(type(baud) == "number", "port", type(baud), "number")
    TypeError:assert(type(port) == "number", "port", type(port), "number")
    TypeError:assert(type(timeout) == "number", "timeout", type(timeout), "number")
    TypeError:assert(type(max_peers) == "number", "max_peers", type(max_peers), "number")
    TypeError:assert(type(ratelimit) == "number", "ratelimit", type(ratelimit), "number")
    TypeError:assert(type(generosity) == "number", "generosity", type(generosity), "number")
    PositiveError:assert(baud > 0, "baud")
    PositiveError:assert(port >= 0, "port")
    PositiveError:assert(timeout > 0, "timeout")
    PositiveError:assert(max_peers > 0, "max_peers")
    PositiveError:assert(generosity > 0, "generosity")
    RangeError:assert(0 < ratelimit and ratelimit < baud, "ratelimit")

    p.udp         = SocketError:assert(socket.udp())
    p.peers       = {}
    p.connections = {}
    p.baud        = baud
    p.timeout     = timeout
    p.ratelimit   = ratelimit
    p.max_peers   = math.round(max_peers)
    p.generosity  = math.round(generosity)

    p.next_ping = now() + p.baud

    p.udp:settimeout(0)

    SocketError:assert(p.udp:setsockname("*", port))

    p.ip, p.port, p.family = SocketError:assert(p.udp:getsockname())

    p.port = tonumber(p.port)
end

    --======METHODS======--

function SocketServer:send(peer, data)
    local p = private[self]

    TypeError:assert(type(peer) == "string", "peer", type(peer), "string")
    TypeError:assert(data ~= nil, "data", type(data), "any non-nil value")
    InvalidPeerError:assert(p.peers[peer], peer)

    send(p.udp, "data", p.peers, data, p.peers[peer])

    return self
end

function SocketError:broadcast(data)
    local p = private[self]

    TypeError:assert(data ~= nil, "data", type(data), "any non-nil value")

    send(p.udp, "data", p.peers, data)

    return self
end

function SocketServer:update(dt)
    local p, time
    
    p    = private[self]
    time = now()

    if p.next_ping < time then
        send(p.udp, "ping", p.peers)

        p.next_ping = time + p.baud
    end
    
    while true do
        local success, data, peer, event, uuid
        
        data = p.udp:receive()

        if not data then return self end

        --We must assume that *any* failure to decode is invalid data from the client.
        success, data = pcall(msgpack.decode, data)

        --If we fail to decode, we can't respond, since we don't know who it came from.
        --We don't use receivefrom, because it's not on us to respond to every piece
        --of fuzz (https://en.wikipedia.org/wiki/Fuzzing) sent to the server.
        if not success                          then goto continue end
        if data.uuid and not p.peers[data.uuid] then goto continue end
        
        peer = p.peers[data.uuid]
        
        --When a user sends a ping or data, we need to account for the ratelimit.
        --For connections, you'd think we don't need to check, but if a user spams
        --connection requests, that counts as flooding with data, and so we need to
        --check there as well. Disconnections, however, are always handled.
        if data.event == "ping" then
            if not event_responses.ping(p, peer) then goto continue end
        elseif data.event == "data" then
            if not event_responses.data(p, peer) then goto continue end
        elseif data.event == "catchup" then
            if not event_responses.data(p, peer) then goto continue end
        elseif data.event == "connect" then
            if not event_responses.connect(p, data.ip, data.port) then goto continue end

            peer = p.connections[data.ip .. ":" .. data.port]
        elseif data.event == "disconnect" then
            event_responses.disconnect(p, peer)
        else
            send(p.udp, "rejected", p.peers, "invalid_event", peer)

            goto continue
        end

        self:dispatch(data.event, data)
        self:dispatchSync(data.event, data)

        ::continue::
    end

    for _, peer in pairs(p.peers) do
        if peer.timeout < time then
            send(p.udp, "disconnected", p.peers, "timeout", peer)

            p.peers[peer]                              = nil
            p.connections[peer.ip .. ":" .. peer.port] = nil
        end
    end
end

    --======GETTERS======--

function SocketServer.__get:ip()
    return private[self].ip
end

function SocketServer.__get:port()
    return private[self].port
end

    --======SETTERS======--
    
    --======METAMETHODS======--

function SocketServer:__tostring()
    local p = private[self]

    return self:tostring(p.ip, p.port)
end

SocketServer.__type = "socket_server"

---@type SocketServer.Class
local Class = Object:create(SocketServer, Emitter)

return Class