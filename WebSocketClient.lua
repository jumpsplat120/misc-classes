---@type Object
local Object
local WebSocketClient, private
local TypeError, SocketError, NotLoadedError
local Emitter
local Symbol, Error, Async
local is, tobase, TL
local ssl
local surl, socket, mime, bit

Object  = require("lib.Classy")
private = require("lib.Classy.instances")
Symbol  = require("lib.Classy.Symbol")

NotLoadedError = require("classes.errors.NotLoadedError")
SocketError    = require("classes.errors.SocketError")
TypeError      = require("classes.errors.TypeError")

Emitter = require("classes.mixins.Emitter")

Error = require("classes.Error")
Async = require("classes.Async")

TL     = require("lib.string_template")
is     = require("lib.is")
tobase = require("lib.tobase")

ssl = require("third_party.luasec")

socket = require("socket")
mime   = require("mime")
surl   = require("socket.url")
bit    = require("bit")

WebSocketClient = Object:extend()

WebSocketClient:implement(Emitter)

    --======PRIVATE FUNCTIONS======--

local SchemeError, HandshakeError
local CRLF, GUID
local validate, generate, decode, encode, exists, byte, uint16, uint64, mask, readyToSend
local opcodes, frame_types
local FIN, FRAG, MASK
local CONTINUE, TEXT, BINARY, CLOSE, PING, PONG

HandshakeError = Error("handshake", "'%s' does not match the expected key '%s'.")
SchemeError    = Error("scheme", "'%s' is an invalid scheme. Valid schemes are %s.")

CONTINUE = Symbol("continue")
BINARY   = Symbol("binary")
CLOSE    = Symbol("close")
TEXT     = Symbol("text")
PING     = Symbol("ping")
PONG     = Symbol("pong")

FRAGMENT = Symbol("fragment")
FINAL    = Symbol("final")

opcodes = {
    ["0000"] = CONTINUE,
    ["0010"] = BINARY,
    ["1000"] = CLOSE,
    ["0001"] = TEXT,
    ["1001"] = PING,
    ["1010"] = PONG,
    [CONTINUE] = 0,
    [BINARY]   = 2,
    [CLOSE]    = 8,
    [TEXT]     = 1,
    [PING]     = 9,
    [PONG]     = 10
}

frame_types = {
    ["0"] = FRAGMENT,
    ["1"] = FINAL,
    [FRAGMENT] = "0",
    [FINAL]    = "1"
}

--Generate a random key as per spec (16 bytes, b64 encoded).
--https://datatracker.ietf.org/doc/html/rfc6455#page-18
function generate()
    local bytes = {}

    for i = 1, 16, 1 do
        bytes[i] = math.random(0, 255)
    end

    --NOTE: The brackets are shorthand for selecting just
    --the first returned value.
    return (mime.b64(string.char(table.unpack(bytes))))
end

--Take a previously generated key, then do the hashing process
--to see if the recieved version matches.
function validate(generated, recieved)
    return recieved == mime.b64(love.data.hash("sha1", generated .. GUID))
end

--Take a number, and convert it to an 8 length string of 1s and 0s.
function byte(value)
    return tobase(value, 2):padleft(8, "0")
end

--Take a number, and decompose it into two bytes (numbers) in a table.
function uint16(value)
    return {
        bit.band(bit.rshift(value, 8), 255), bit.band(value, 255)
    }
end

--Take a number, and decompose it into eight bytes (numbers) in a table.
--NOTE: Because bit operates on 32 bit numbers, we can't shift when
--decomposing a uint64. Instead, we simulate with math.floor (which is
--probably slower, but eh.)
function uint64(value)
    return {
        bit.band(math.floor(value / 2 ^ 56), 255), bit.band(math.floor(value / 2 ^ 48), 255),
        bit.band(math.floor(value / 2 ^ 40), 255), bit.band(math.floor(value / 2 ^ 32), 255),
        bit.band(math.floor(value / 2 ^ 24), 255), bit.band(math.floor(value / 2 ^ 16), 255),
        bit.band(math.floor(value / 2 ^ 8), 255),  bit.band(value, 255)
    }
end

--Take 2 bytes as numbers (in a table), and convert them to a uint16 number.
function ruint16(value)
    return bit.lshift(value[1], 8) + value[2]
end

--Take 8 bytes as numbers (in a table), and convert them to a uint64 number.
function ruint64(value)
    return bit.lshift(value[1], 56) + bit.lshift(value[2], 48) +
           bit.lshift(value[3], 40) + bit.lshift(value[4], 32) +
           bit.lshift(value[5], 24) + bit.lshift(value[6], 16) +
           bit.lshift(value[7], 8)  + value[8]
end

--Read a frame or frames, and return the data, if we found it.
function decode(data)
    local result, header, opcode, frame_type, masked, length, from, total
    
    --If we have less than two bytes in our data, then we don't have
    --enough for a complete frame. A minimal frame has FIN, RSV1-3,
    --mask, and an empty payload. This would be common for PONG and
    --PING frames.
    if #data < 2 then return end
    
    result = {}
    header = byte(data[1])

    frame_type = frame_types[header:sub(1, 1)]
    opcode     = opcodes[header:sub(5)]
    
    header = byte(data[2])

    masked = header:sub(1, 1) == "1"
    length = tonumber(header:sub(2), 2)
    from   = 3
    
    --TODO: Make this an appropriate error.
    assert(not masked, "Frame is masked, but server's aren't supposed to mask.")
    
    --If length is 126 or 127, then the next 16/64 bit number is the
    --true length. If we don't have enough bytes to calculate the
    --payload length, then we early return. We set from to know where
    --we start pulling our payload data from.
    --NOTE: Length of payload is in bytes.
    if length == 126 then
        if #data < 4 then return end
        
        from   = 5
        length = ruint16(table.subset(data, 3, 4))
    elseif length == 127 then
        if #data < 10 then return end
        
        from   = 11
        length = ruint64(table.subset(data, 3, 10))
    end
    
    total = #data - (from - 1)
    to    = #data

    --We can check if we have all the data at this point, since we have
    --all the information we need. If we take `from - 1` (because 1 indexed)
    --and subtract that from the length of data, it should exclude everything
    --other than the payload data, therefore matching length. If we have more
    --data then length wants, then we need to continue with that subset, and
    --return our leftovers for a decode next frame.
    if total > length then
        to = from + length - 1
    elseif total ~= length then
        return
    end
    
    --Now we know how long the data is supposed to be, and we know where to
    --start reading from amd to, so we  can convert our nums into strings.
    --NOTE: How does this work if the data isn't text? As well, we need to handle
    --binary data. This is all temporary stuff, I think.
    for i = from, to, 1 do
        result[#result + 1] = string.char(data[i])
    end

    return table.concat(result), frame_type, opcode, to and table.subset(data, to + 1) or {}
end

--Take a set of data, and encode it into a frame, based on the
--type of frame it is.
function encode(data, opcode, final)
    local bytes, length

    data = data or ""

    --Save the length, since we overwrite the data variable below.
    length = #data
    bytes  = {}

    --The first bit is FIN, and RSV1/RSV2/RSV3 are all 0s, as per spec.
    --The RSVs only change from zero if an extension has declared otherwise.
    --Then, the next four bits represent the opcode. Currently, only the
    --base opcodes are implemented.
    --NOTE: Right now, the extra zeros in FRAG/FIN are hardcoded in. As well,
    --no opcodes except vanilla are allowed. An example of an extension that
    --utilizes RSV and other opcodes is needed to determine a new paradigm.
    bytes[#bytes + 1] = string.char((not final and FIN or FRAG) + opcodes[opcode])
    
    --The next byte is the mask bit (always a 1, since the client MUST always
    --mask), along with the length of the payload. If the length of the payload
    --is more than 125 bytes, then we need to calculate out those values instead.
    if length <= 125 then
        bytes[#bytes + 1] = string.char(MASK + length)
    end
    
    --If our data is more than 125 bytes, and less than 2 ^ 15, we encode 126
    --specifically, followed by a uint16 of the actual length of the payload.
    if math.between(length, 126, 2 ^ 16 - 1) then
        bytes[#bytes + 1] = string.char(MASK + 126)
        
        for _, byte in ipairs(uint16(length)) do
            bytes[#bytes + 1] = string.char(byte) 
        end
    end

    --If our data is more than 2 ^ 15 - 1 and less than 2 ^ 64, we encode 127
    --specifically, followed by a uint64 of the actual length of the payload.
    if math.between(length, 2 ^ 16, 2 ^ 64 - 1) then
        bytes[#bytes + 1] = string.char(MASK + 127)

        for _, byte in ipairs(uint64(length)) do
            bytes[#bytes + 1] = string.char(byte) 
        end
    end
    
    --NOTE: Technically, data can be greater than the 64 bit limit.
    --If it is, then it gets fragmented across multiple frames. To
    --handle that, we can't just check length, as length won't accurately
    --represent the length of the data (since lua/love2d is 64bit).
    
    --Mask the data. The client MUST ALWAYS mask the data.
    for _, byte in ipairs(mask(data)) do
        bytes[#bytes + 1] = string.char(byte)
    end

    --Concat the data together, and send it off as a string (even if it's binary
    --data, we still do this).
    return table.concat(bytes)
end

--Helper function for sending data.
function send(client, data)
    local success, err, i
    
    i = 1

    --For large chunks of data (more than 65535 bytes), the client will
    --need to send multiple times. We Async await using socket.select.
    while not success do
        success, err, i = client:send(data, i)
        
        if not err then break end

        Async:waitFor(readyToSend, client)

        SocketError:assert(err == "wantwrite" or success, err)
    end
end

--Helper function to reduce anonymous function creation. Checks a
--table for a value, so you can waitFor something to exist before
--continuing.
function exists(tbl, value)
    return tbl[value]
end

--Mask data.
--https://en.wikipedia.org/wiki/WebSocket#Client-to-server_masking
function mask(data)
    --Generate a 4 byte random nonce. We can stick it in here,
    --since we need to return it anyways, and the modulo will never
    --let us access any of the other data.
    local result = {
        math.random(0, 255),
        math.random(0, 255),
        math.random(0, 255),
        math.random(0, 255)
    }

    --xor the data with the key, and add the byte to the table.
    for i = 1, #data, 1 do
        result[#result + 1] = bit.bxor(data:byte(i, i), result[((i - 1) % 4) + 1])
    end

    return result
end

--Helper function to reduce anonymous function creation. Returns true
--when the provided socket is ready to be written to.
function readyToSend(client)
    local _, tbl, err = socket.select(nil, { client }, 0)
    
    if err == nil and #tbl == 1 then return true end
end

--NOTE: This is a magic value, but that's just how the spec is written.
--https://www.rfc-editor.org/rfc/rfc6455#:~:text=concatenate%20this,Websocket%20Protocol
GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
CRLF = "\r\n"

--These partials are used in building the headers for a frame.
FIN  = 128
FRAG = 0
MASK = 128

    --======CONSTRUCTOR======--

function WebSocketClient:new(address)
    local p = private[self]
    
    TypeError:assert(is(address, "string"), "address", type(address), "string")
    
    p.connected = false
    p.running   = true
    p.address   = address:lower()
    p.buffer    = {}
    p.key       = generate()
    p.url       = surl.parse(p.address)
    
    --We create the client using tcp first, rather than socket.connect, so
    --we can give it a timeout. Otherwise, the inital connection can wait
    --forever.
    p.client = SocketError:assert(socket.tcp())

    p.client:settimeout(30)

    --If it's a TLS connection, we gotta do the ssl handshake first.
    --NOTE: This needs ssl via luasec, which we don't have precompiles
    --for every os and architecture. That being said, we have windows
    --x64 and x86 and linux x64, which are likely the big ones. Also
    --iOS, but we have no idea if that'll work for OSX.
    if p.url.scheme == "wss" then
        p.url.port = p.url.port or 443

        SocketError:assert(p.client:connect(p.url.host, p.url.port))

        --NOTE: Pulled from https://github.com/lipp/lua-websockets/issues/103#issuecomment-262133543
        p.client = ssl.wrap(p.client, {
            protocol = "any",
            options  = "all",
            verify   = "none",
            mode     = "client"
        })

        --NOTE: Yo, this stupid missing SNI request took me like 4 hours
        --to sort out.
        p.client:sni(p.url.host)

        SocketError:assert(p.client:dohandshake())
    end

    --If it's s standard connection, we don't have to
    --do anything special.
    if p.url.scheme == "ws" then
        p.url.port = p.url.port or 80

        SocketError:assert(p.client:connect(p.url.host, p.url.port))
    end

    --Verify that we connected to something. If the socket
    --connection errored, then SocketError will throw, so
    --this should only exist if we skipped both if statements.
    SchemeError:assert(p.client, p.url.scheme, "wss/ws")

    --Set the timeout to zero so we can do the update send/recieve process.
    p.client:settimeout(0)
end

    --======METHODS======--

--This connection function allowed you to Async the connection process,
--as the client needs to have access to the update function to do so
--(unless we were gonna do something hacky like putting Async into the
--constructor or whatever.) This goes through the upgrading process
--and must be run before any data is transmitted. Connecting only needs to
--be done once, and it will silentally return if you try to connect a
--second time.
--NOTE: Currently, protocols and extensions get sent, but we ignore them
--them when encoding/decoding.
function WebSocketClient:connect(protocols, extensions)
    local p, raw, data, parts, headers, _

    TypeError:assert(is(protocols, "table") or is(protocols, "nil"), "protocols", type(protocols), "table/nil")
    TypeError:assert(is(extensions, "string") or is(extensions, "nil"), "extensions", type(extensions), "table/nil")
    
    p = private[self]

    if not p.running then return self end
    if p.connected   then return self end

    --The client hello for websockets involves taking a
    --standard HTTP request and sending a special upgrade
    --header. It needs a key (a random 16 digit number that's
    --been b64 encoded), and the rest is just pretty standard
    --stuff. Technically, we can request protocol's and extensions
    --as well, but that's generally not needed for most connections.
    raw = {
        "GET %{path} HTTP/1.1",
        "Host: %{host}",
        "Connection: Upgrade",
        "Upgrade: websocket",
        "Sec-WebSocket-Version: 13",
        "Sec-WebSocket-Key: %{key}"
    }

    headers = {}

    if protocols then
        raw[#raw + 1] = "Sec-WebSocket-Protocol: %{protocols}"
    end

    if extensions then
        raw[#raw + 1] = "Sec-WebSocket-Protocol: %{extensions}"
    end

    --A HTTP request ends in two CRLF back to back.
    raw[#raw + 1] = CRLF
    
    --Send the upgrade request, and wait for a response.
    p.client:send(TL(table.concat(raw, CRLF), {
        key = p.key,
        host = p.url.host,
        port = p.url.port,
        path = p.url.path,
        protocols = table.concat(protocols or {}, ","),
        extensions = table.concat(extensions or {}, ","),
    }))
    
    --We don't have to do any processing or anything; since we're
    --unable to do anything before connecting, this'll be the first
    --set of data we recieve.
    data = Async:waitFor(exists, p, "upgrade")
    
    --Every line other than the first (the path stuff) and the last
    --(the termination CRLF) are headers.
    for i, header in ipairs(data) do
        if i > 1 and i < #data and header ~= "" then
            parts = header:split(": ")
            
            headers[parts[1]:lower()] = parts[2]
        end
    end

    --Validate the key we got from the server.
    HandshakeError:assert(validate(p.key, headers["sec-websocket-accept"]), headers["sec-websocket-accept"], p.key)
    
    p.connected = true

    --And that's it! Now we can send data.
    return self
end

--Update function to be placed in main loop.
function WebSocketClient:update()
    local p, data, status, partial, frame_type, opcode
    
    p = private[self]

    if not p.running then return self end

    data, status, partial = p.client:receive("*a")

    --Sometimes, we don't get a full piece of data, and it can end up
    --in partial, usually along with a status as to why that happened.
    --we don't really care though. If there's data in data, we use that,
    --and if there's data in partial, we use that.
    data = data or partial
    
    --If we have data, then we either parse the frame, or save it so connect
    --can finish processing.
    if data ~= "" then
        --This is our HTTP upgrade. We just assume we have the whole chunk
        --of data, split it, and do nothing else. The rest is handled in
        --connect.
        if data:startswith("HTTP") then
            p.upgrade = data:split(CRLF)
        end
        
        --We only collate data into the buffer if we're connected.
        if p.connected then
            for i = 1, #data, 1 do
                p.buffer[#p.buffer + 1] = data:byte(i, i)
            end
        end
    end

    --As long as we have any data at all, we want to try to decode the
    --buffer, since we don't know where one frame ends and another begins
    --without at least attempting to read it.
    if #p.buffer > 0 then
        data, frame_type, opcode, partial = decode(p.buffer)
        
        --If we recieve anything from decode, that's our data.
        --We can clear the buffer, and fire our event.
        if data then
            self:dispatch("response", data, frame_type, opcode)
            self:dispatchSync("response", data, frame_type, opcode)
        end

        --If we get a partial from decode, then we update the buffer
        --to contain only that partial. This is in a case where we
        --get multiple frames in our buffer; we split out the data,
        --and save the rest back into our buffer for later processing.
        --If there's not extra data, then partial will be an empty table,
        --clearing the buffer for future data.
        p.buffer = partial
    end

    --The server has closed the connection, so we clear the buffer
    --and set running to false. We ignore any partial data, since
    --this only should happen if the server didn't close correctly,
    --and we don't want to make descions on malformed data.
    if status == "closed" then
        p.running   = false
        p.connected = false
        p.buffer    = {}
    end

    return self
end

--Send some data to the server. If you set `binary` to true, the data
--will be sent as binary, otherwise it will be sent as text.
function WebSocketClient:send(data, binary)
    local p = private[self]

    if not p.running   then return self end
    if not p.connected then return self end
    
    TypeError:assert(is(data, "string"), "data", type(data), "string")

    send(p.client, encode(data, binary and BINARY or TEXT))
    
    return self
end

--Send a ping to the server, along with an optional payload.
function WebSocketClient:ping(data)
    local p = private[self]

    if not p.running   then return self end
    if not p.connected then return self end

    TypeError:assert(is(data, "string") or is(data, "nil"), "data", type(data), "string/nil")

    send(p.client, encode(data, PING))
    
    return self
end

--Send a pong to the server, along with an optional payload.
--NOTE: Pongs must be sent in response to any server sent pings. This
--function should be placed in it's own event, as the instance does
--not handle pings by default.
function WebSocketClient:pong(data)
    local p = private[self]

    if not p.running   then return self end
    if not p.connected then return self end

    TypeError:assert(is(data, "string") or is(data, "nil"), "data", type(data), "string/nil")

    send(p.client, encode(data, PONG))
    
    return self
end

--Send a close frame. Closes the connection, and no more frames can
--be sent after this point. Also frees up the socket.
function WebSocketClient:close()
    local p = private[self]

    if not p.running   then return self end
    if not p.connected then return self end

    send(p.client, encode(nil, CLOSE))
    
    p.client:close()

    return self
end

    --======GETTERS======--

function WebSocketClient.__get:running()
    return private[self].running
end

function WebSocketClient.__get:connected()
    return private[self].connected
end

function WebSocketClient.__get:CONTINUE()
    return CONTINUE
end

function WebSocketClient.__get:BINARY()
    return BINARY
end

function WebSocketClient.__get:CLOSE()
    return CLOSE
end

function WebSocketClient.__get:TEXT()
    return TEXT
end

function WebSocketClient.__get:PING()
    return PING
end

function WebSocketClient.__get:PONG()
    return PONG
end

function WebSocketClient.__get:FRAGMENT()
    return FRAGMENT
end

function WebSocketClient.__get:FINAL()
    return FINAL
end

    --======SETTERS======--
    
    --======METAMETHODS======--

function WebSocketClient:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper() end

    return self:tostringHelper("Class")
end

WebSocketClient.__type = "websocket_client"

return WebSocketClient