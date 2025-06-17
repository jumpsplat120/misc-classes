---@type Object
local Object
local IRCClient, private
local SocketError, TypeError
local Emitter
local socket
local is

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

SocketError = require("classes.errors.SocketError")
TypeError   = require("classes.errors.TypeError")

Emitter = require("classes.mixins.Emitter")

is = require("lib.is")

socket = require("socket")

IRCClient = Object:extend()

IRCClient:implement(Emitter)

    --======PRIVATE FUNCTIONS======--

local CRLF
local send

CRLF = "\r\n"

--Helper function that makes sure a command has a CRLF
--attached to the command before sending it off. Trims 
--whitespace, and also does string templating.
function send(client, command, args)
    client:send(TL(command:trim(), args) .. CRLF)
end

    --======CONSTRUCTOR======--

function IRCClient:new(address)
    local p = private[self]

    TypeError:assert(is(address, "string"), "address", type(address), "string")

    --We create the client using tcp first, rather than socket.connect, so
    --we can give it a timeout. Otherwise, the inital connection can wait
    --forever.
    p.client = SocketError:assert(socket.tcp())

    p.client:settimeout(30)

    SocketError:assert(p.client:connect(address, 6667))

    p.running = true
    p.address = address
    p.data    = {}

    --Set the timeout to zero so we can do the update send/recieve process.
    p.client:settimeout(0)
end

    --======METHODS======--

--Set or change the nickname of the client.
--https://modern.ircdocs.horse/#nick-message
function IRCClient:nick(nickname)
    local p = private[self]

    if not p.running then return self end 

    send(p.client, "%{old} NICK %{new}", {
        old = p.nickname or "",
        new = nickname
    })

    p.nickname = nickname

    return self
end

--Set the password for the user.
--https://modern.ircdocs.horse/#pass-message
function IRCClient:pass(password)
    local p = private[self]

    if not p.running then return self end 

    send(p.client, "PASS %{password}", {
        password = password
    })

    return self
end

--Set the username and realname of the client. Can only be run once (generally
--at the beginning of the registration process), and will simply return if
--attempted to run again, without throwing any error.
--https://modern.ircdocs.horse/#user-message
function IRCClient:user(username, realname)
    local p = private[self]

    if not p.running then return self end 
    if p.registered  then return self end

    send(p.client, "USER %{username} 0 * %{realname}", {
        username = username,
        realname = realname
    })

    p.registered = true

    return self
end

--Send a ping to the server, along with optional token.
--https://modern.ircdocs.horse/#ping-message
function IRCClient:ping(token)
    local p = private[self]

    if not p.running then return self end 

    send(p.client, "PING %{token}", {
        token = token or ""
    })

    return self
end

--Send a pong to the server, along with optional token.
--NOTE: The living doc currently mentions that the client
--MUST NOT send a server, but does need to send a token,
--if there one. According to the spec, an empty param
--should be a colon space.
--https://modern.ircdocs.horse/#pong-message
function IRCClient:pong(token)
    local p = private[self]

    if not p.running then return self end 

    send(p.client, "PONG : %{token}", {
        token = token or ""
    })

    return self
end

--Request capabilities from the server.
--https://ircv3.net/specs/extensions/capability-negotiation.html
function IRCClient:cap(subcommand, params)
    local p = private[self]

    if not p.running then return self end 

    send(p.client, "CAP %{subcommand} %{params}", {
        subcommand = subcommand,
        params     = params
    })

    return self
end

--Send a message to the server, or a user.
--https://modern.ircdocs.horse/#privmsg-message
function IRCClient:privmsg(target, message)
    local p = private[self]

    if not p.running then return self end 

    send(p.client, "PRIVMSG %{target} :%{message}", {
        target  = target,
        message = message
    })

    return self
end

--Get a list of users based on the mask provided.
--https://modern.ircdocs.horse/#who-message
function IRCClient:who(mask)
    local p = private[self]

    if not p.running then return self end 

    send(p.client, "WHO %{mask}", {
        mask = mask
    })

    return self
end

--Join a channel or channels, along with their passwords, if needed.
--https://modern.ircdocs.horse/#join-message
function IRCClient:join(channels, passwords)
    local p = private[self]

    if not p.running then return self end 

    send(p.client, "JOIN %{channels} %{passwords}", {
        channels = channels,
        passwords = passwords or ""
    })

    return self
end

--Function meant to be placed in an update loop.
function IRCClient:update()
    local p, data, status, partial
    
    p = private[self]

    if not p.running then return self end 
    
    --Use the built in line handling for IRC. No need for a buffer.
    data, status, partial = p.client:receive("*l")
        
    --Sometimes, we don't get a full piece of data, and it can end up
    --in partial, usually along with a status as to why that happened.
    --we don't really care though. If there's data in data, we use that,
    --and if there's data in partial, we use that.
    data = data or partial

    --If we have data, then we post it. IRC is simple enough we don't have 
    --to worry about buffering data.
    if data ~= "" then
        self:dispatch("response", data)
        self:dispatchSync("response", data)
    end

    --The server has closed the connection, so we set running to false. Ez.
    if status == "closed" then
        p.running = false
    end

    return self
end

    --======GETTERS======--
    
function IRCClient.__get:running()
    return private[self].running
end

    --======SETTERS======--
    
    --======METAMETHODS======--

function IRCClient:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper() end

    return self:tostringHelper("Class")
end

IRCClient.__type = "irc_client"

return IRCClient