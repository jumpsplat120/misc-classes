local Object, GoogleOauth2, Async, Symbol, HTTPS
local private, TL, is, socket, surl, json, varargs
local TypeError, UnsetError, ConflictError, InvalidError, PatternError, LengthError
local WithinAsyncError, NotLoadedError, MissingError

Object  = require("lib.Classy")
private = require("lib.Classy.instances")
Symbol  = require("lib.Classy.Symbol")

TL      = require("lib.string_template")
is      = require("lib.is")
varargs = require("lib.varargs")

Async = require("classes.Async")
HTTPS = require("classes.HTTPS")

WithinAsyncError = require("classes.errors.WithinAsyncError")
NotLoadedError   = require("classes.errors.NotLoadedError")
ConflictError    = require("classes.errors.ConflictError")
InvalidError     = require("classes.errors.InvalidError")
MissingError     = require("classes.errors.MissingError")
PatternError     = require("classes.errors.PatternError")
LengthError      = require("classes.errors.LengthError")
UnsetError       = require("classes.errors.UnsetError")
TypeError        = require("classes.errors.TypeError")

surl   = require("socket.url")
socket = require("socket")

json = require("third_party.json")

GoogleOauth2 = Object:extend()

    --======PRIVATE FUNCTIONS======--

local SHA256, PLAIN
local GOOGLE_OAUTH_URL, DEFAULT_HTML, VALID_CHARS
local symbols

SHA256 = Symbol("S256")
PLAIN  = Symbol("plain")

private[GoogleOauth2] = {
    [SHA256] = true,
    [PLAIN]  = true
}

symbols = table.join(table.keys(private[GoogleOauth2]), ", ")

GOOGLE_OAUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
DEFAULT_HTML     = [[
<html>
	<link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Kanit:thin&text=You%20may%20now%20close%20this%20window%2E">
    <style>
		body {
			background-color: #e3e4ed;
			font-family: "Kanit", sans-serif;
        	font-size: 48px;
		}

		#outer {
			display: flex;
			align-items: center;
			justify-content: center;
		}

		#inner {
			border-radius: 19px;
			background: #e3e4ed;
			box-shadow:  32px 32px 51px #b8b9c0,
						-32px -32px 51px #ffffff;
			font-weight: 100;
			flex-grow: 0;
			padding: 5%;
			margin: 10%;
		}
	</style>
	<body>
		<div id="outer">
			<div id="inner">
				You may now close this window.
			</div>
		</div>
	</body>
</html>
]]
VALID_CHARS      = {
    "a", "b", "c", "d", "e", "f", "g",
    "h", "i", "j", "k", "l", "m", "n",
    "o", "p", "q", "r", "s", "t", "u",
    "v", "w", "x", "y", "z",
    "A", "B", "C", "D", "E", "F", "G",
    "H", "I", "J", "K", "L", "M", "N",
    "O", "P", "Q", "R", "S", "T", "U",
    "V", "W", "X", "Y", "Z", 
    "0", "1", "2", "3", "4", "5", "6",
    "7", "8", "9",
    ".", "-", "_", "~"
}

    --======CONSTRUCTOR======--

function GoogleOauth2:new(client_id, client_secret)
    local p = private[self]

    TypeError:assert(is(client_id, "string"), "client_id", type(client_id), "string")
    TypeError:assert(is(client_secret, "string"), "client_secret", type(client_secret), "string")

    p.client_id     = client_id
    p.client_secret = client_secret
end

    --======METHODS======--

function GoogleOauth2:openURL(html)
    local p, url, server, client, data, output, host, code, token
    
    p = private[self]

    --If the user closed the URL, but we're currently waiting for a response,
    --then we just reopen the link to the page we're waiting for, rather than
    --regenerating from scratch. We return false to let the user know that this
    --version isn't the one you want to wait for.
    if p.url then
        love.system.openURL(p.url)

        return false
    end

    UnsetError:assert(p.scopes, "scopes", "openURL")

    if html then
        TypeError:assert(is(html, "string"), "html", type(html), "string")
    end

    if not p.custom_redirect_uri and not p.loopback_port then
        p.loopback_port = "*"
    end

    url = TL("%{GOOGLE_OAUTH_URL}?%{arguments}", {
        GOOGLE_OAUTH_URL = GOOGLE_OAUTH_URL,
        arguments = table.reduce(table.entries(table.map({
            code_challenge_method = p.code_challenge_method.id,
            code_challenge = p.code_challenge,
            response_type  = "code",
            redirect_uri   = p.custom_redirect_uri,
            login_hint     = p.login_hint,
            client_id = p.client_id,
            scope     = p.scopes,
            state     = p.state
        }, function(k, v)
            if v == nil then return end

            if k == "scope" then
                local scope_str = ""

                for _, scope in ipairs(v) do
                    scope_str = scope_str .. TL("https://www.googleapis.com/auth/%{scope} ", {
                        scope = scope
                    })
                end

                v = scope_str:sub(1, -2)
            end

            if k == "code_challenge" and p.code_challenge_method == SHA256 then
                v = love.data.hash("sha256", p.code_challenge)
                v = love.data.encode("string", "base64", v)

                --https://stackoverflow.com/a/74527436/6772918
                --Without these replacements, google just doesn't accept it.
                v = v:gsub("=", "")
                v = v:gsub("/", "_")
                v = v:gsub("+", "-")
            end

            return k, v
        end)), function(_, a, b)
            return TL("%{b}%{a[1]}=%{surl.escape(a[2])}&", {
                a = a,
                b = b,
                surl = surl
            })
        end, ""):sub(1, -2)
    })
    
    if p.custom_redirect_uri then return url end

    server = WithinAsyncError:assert(socket.tcp())
    
    WithinAsyncError:assert(server:bind("127.0.0.1", p.loopback_port == "*" and 0 or p.loopback_port))
    WithinAsyncError:assert(server:listen())

    server:settimeout(0)
    
    if p.loopback_port == "*" then
        host = "http://127.0.0.1:" .. server:getsockname()
        url  = url .. "&redirect_uri=" .. surl.escape(host)
    end

    p.url = url

    love.system.openURL(url)

    client = Async:waitFor(function(server, WithinAsyncError)
        local client, err = server:accept()

        if client then return client end

        WithinAsyncError:assert(err == "timeout", err)
    end, server, WithinAsyncError)
    
    client:settimeout(0)

    output = Async:waitFor(function(client, output)
        local data, a, b, status

        a, status, b = client:receive()

        data = a ~= "" and a or b ~= "" and b or nil

        if data then
            output[#output + 1] = data 
            
            if data:endswith("\r\n0\r\n\r\n") then return output end
        end

        if status == "closed" then return output end
        if output[#output]:startswith("GET /?code=") then return output end
    end, client, {})

    html = html or DEFAULT_HTML

    client:send(table.concat({
        output[#output]:split(' ')[3] .. " 200 OK",
        "Content-Length: " .. html:len(),
        "Content-Type: text/html",
        "",
        html,
        "\r\n"
    }, "\r\n"))

    output = output[#output]

    client:close()

    output = output:split(" ")[2]
    output = output:after("?"):split("&")
    output = table.map(output, function(_, v) return table.unpack(v:split("=")) end)

    token = HTTPS("https://oauth2.googleapis.com/token", nil, {
        encoding = HTTPS.FORM,
        data     = {
            code          = output.code,
            client_id     = p.client_id,
            grant_type    = "authorization_code",
            redirect_uri  = host,
            code_verifier = p.code_challenge,
            client_secret = p.client_secret
        }
    })

    code, data = token:fetch()

    WithinAsyncError:assert(code == 200, data)

    data = json.parse(data)

    p.access_token  = data.access_token
    p.refresh_token = data.refresh_token

    return self
end

function GoogleOauth2:generateCodeChallenge(s256)
    local p, result

    p      = private[self]
    result = {}

    table.shuffle(VALID_CHARS)

    for i = 1, 128, 1 do result[i] = VALID_CHARS[math.random(#VALID_CHARS)] end

    p.code_challenge        = table.concat(result, "")
    p.code_challenge_method = s256 and SHA256 or PLAIN

    return self
end

function GoogleOauth2:setScopes(...)
    local result = {}

    for i, scope in varargs(...) do
        local index = TL("args[%{i}]", { i = i })

        TypeError:assert(is(scope, "string"), index, type(scope), "string")
        InvalidError:assert(scope ~= "", "<EMPTY STRING>", index, "<NONEMPTY STRING>")

        result[#result + 1] = scope:lower()
    end

    private[self].scopes = result

    return self
end

function GoogleOauth2:addScope(scope)
    TypeError:assert(is(scope, "string"), scope, type(scope), "string")
    InvalidError:assert(scope ~= "", "<EMPTY STRING>", "scope", "<NONEMPTY STRING>")

    table.insert(private[self].scopes, scope:lower())

    return self
end

function GoogleOauth2:setTokens(access, refresh)
    local p, code, data
    
    p = private[self]

    TypeError:assert(is(access, "string"), access, type(access), "string")
    TypeError:assert(is(refresh, "string"), refresh, type(refresh), "string")
    InvalidError:assert(access ~= "", "<EMPTY STRING>", "access", "<NONEMPTY STRING>")
    InvalidError:assert(refresh ~= "", "<EMPTY STRING>", "refresh", "<NONEMPTY STRING>")
    UnsetError:assert(p.scopes, "scopes", "setTokens")

    p.access_token  = access
    p.refresh_token = refresh
    
    if true then return self end

    code, data = HTTPS("https://oauth2.googleapis.com/tokeninfo?access_token=" .. p.access_token):fetch()

    WithinAsyncError:assert(code == 200, data)

    data = json.parse(data)

    if data.error == "invalid_token" then
        self:refreshTokens()
    else
        for _, scope in data.scope:split(" ") do
            MissingError:assert(table.find(p.scopes, scope), scope, "scopes")
        end
    end

    return self
end

function GoogleOauth2:refreshTokens(html)
    local p, token, code, data

    p = private[self]

    UnsetError:assert(p.refresh_token, "refresh_token", "refreshTokens")
    UnsetError:assert(p.scopes, "scopes", "refreshTokens")

    token = HTTPS("https://oauth2.googleapis.com/token", nil, {
        encoding = HTTPS.FORM,
        data     = {
            client_id     = p.client_id,
            grant_type    = "refresh_token",
            client_secret = p.client_secret,
            refresh_token = p.refresh_token
        }
    })

    code, data = token:fetch()
    
    WithinAsyncError:assert(code == 400 or code == 200, data)

    data = json.parse(data)

    if code == 400 then
        p.refresh_token = nil
        p.access_token  = nil

        self:openURL(html)

        return self
    end
    
    for _, scope in ipairs(data.scope:split(" ")) do        
        MissingError:assert(table.find(p.scopes, scope), scope, "scopes")
    end

    p.access_token = data.access_token

    return self
end

function GoogleOauth2:makeAPIRequest(url)
    local p, code, data
    
    p = private[self]

    NotLoadedError:assert(p.access_token and p.refresh_token, "openURL", "makeAPIRequest")

    code, data = HTTPS(url, {
        Authorization = "Bearer " .. p.access_token
    }):fetch()
    
    WithinAsyncError:assert(code == 200 or code == 401, data)

    data = json.parse(data)

    --401 errors can be (but are not limited to) invalid tokens.
    --If we get one, rather than throwing an error, we attempt to
    --refresh, and rerequest. If that still doesn't work, THEN
    --we can throw an error.
    if code == 401 then
        WithinAsyncError:assert(data.error.status == "UNAUTHENTICATED", data)

        self:refreshTokens()
        
        return self:makeAPIRequest(url)
    end

    return data
end

    --======GETTERS======--

function GoogleOauth2.__get:custom_redirect_uri()
    return private[self].custom_redirect_uri
end

function GoogleOauth2.__get:loopback_port()
    return private[self].loopback_port
end

function GoogleOauth2.__get:access_token()
    return private[self].access_token
end

function GoogleOauth2.__get:refresh_token()
    return private[self].refresh_token
end

function GoogleOauth2.__get:token_expiry()
    local token, code, data

    token = HTTPS("https://oauth2.googleapis.com/tokeninfo?access_token=" .. private[self].access_token)

    code, data = token:fetch()

    WithinAsyncError:assert(code == 200, data)

    data = json.parse(data)

    return tonumber(data.expires_in)
end

function GoogleOauth2.__get:scopes()
    return setmetatable(private[self].scopes, {
        __newindex = function (tbl, i, v)
            local index = TL("args[%{i}]", { i = i })

            TypeError:assert(is(i, "number"), index, type(i), "string")
            InvalidError:assert(v ~= "", "<EMPTY STRING>", index, "<NONEMPTY STRING>")

            rawset(tbl, i, v)
        end
    })
end

function GoogleOauth2.__get:code_challenge()
    return private[self].code_challenge
end

function GoogleOauth2.__get:code_challenge_method()
    return private[self].code_challenge_method
end

function GoogleOauth2.__get:state()
    return private[self].state
end

function GoogleOauth2.__get:login_hint()
    return private[self].login_hint
end

function GoogleOauth2.__get:SHA256()
    if not self.instance then return SHA256 end

    return rawget(self, "SHA256")
end

function GoogleOauth2.__get:PLAIN()
    if not self.instance then return PLAIN end

    return rawget(self, "PLAIN")
end

    --======SETTERS======--

function GoogleOauth2.__set:custom_redirect_uri(value)
    local p = private[self]

    ConflictError:assert(not p.loopback_port, "custom_redirect_uri", "loopback_port")
    TypeError:assert(is(value, "string"), "custom_redirect_uri", type(value), "string")

    p.custom_redirect_uri = value
end

function GoogleOauth2.__set:loopback_port(value)
    local p = private[self]

    ConflictError:assert(not p.custom_redirect_uri, "loopback_port", "custom_redirect_uri")
    TypeError:assert(is(value, "number"), "loopback_port", type(value), "number")

    p.loopback_port = value
end

function GoogleOauth2.__set:scopes(value)
    local result = {}

    TypeError:assert(is(value, "table"), "scopes", type(value), "table")

    table.foreach(value, function(i, scope)
        local index = TL("scopes[%{i}]", { i = i })

        TypeError:assert(is(scope, "string"), index, type(scope), "string")
        InvalidError:assert(scope ~= "", "<EMPTY STRING>", index, "<NONEMPTY STRING>")

        result[i] = scope:lower()

        return i, scope
    end)

    private[self].scopes = result
end

function GoogleOauth2.__set:code_challenge(value)
    local p = private[self]

    TypeError:assert(is(value, "string"), "code_challenge", type(value), "string")
    PatternError:assert(not value:match("[^%a%d%-%._~]"), value, "[^%a%d%-%._~]")
    LengthError:assert(#value >= 43 and #value <= 128, value, "code_challenge", 43, 128)

    p.code_challenge        = value
    p.code_challenge_method = PLAIN
end

function GoogleOauth2.__set:code_challenge_method(value)
    local p = private[self]

    TypeError:assert(is(value, "string"), "code_challenge_method", type(value), "string")
    InvalidError:assert(private[GoogleOauth2][value], value, "mode", symbols)

    p.code_challenge_method = value
end

function GoogleOauth2.__set:state(value)
    TypeError:assert(is(value, "string"), "state", type(value), "string")

    private[self].state = value
end

function GoogleOauth2.__set:login_hint(value)
    TypeError:assert(is(value, "string"), "login_hint", type(value), "string")

    private[self].login_hint = value
end

    --======METAMETHODS======--

function GoogleOauth2:__tostring()
    if self.is_instance then return self:tostringHelper(table.unpack(private[self].scopes)) end

    return self:tostringHelper("Class")
end

GoogleOauth2.__type = "google_oauth2"

return GoogleOauth2
