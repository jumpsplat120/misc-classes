local Object, private
local Oauth2, Async, HTTPS, HTTPServer
local TypeError, UnsetError, UnimplementedError, StateMismatchError, WithinAsyncError, AuthorizationError
local TL, is, surl, json

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

TL = require("lib.string_template")
is = require("lib.is")

HTTPServer = require("classes.HTTPServer")
Async      = require("classes.Async")
HTTPS      = require("classes.HTTPS")

AuthorizationError = require("classes.errors.AuthorizationError")
StateMismatchError = require("classes.errors.StateMismatchError")
UnimplementedError = require("classes.errors.UnimplementedError")
WithinAsyncError   = require("classes.errors.WithinAsyncError")
UnsetError         = require("classes.errors.UnsetError")
TypeError          = require("classes.errors.TypeError")

surl = require("socket.url")

json = require("third_party.json")

Oauth2 = Object:extend()

    --======PRIVATE FUNCTIONS======--

local default_html
local parseScopes, paramify

default_html = [[
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

--The default function used when no parse callback is set. Uses surl
--to uri encode the table.
function parseScopes(scopes)
    local parsed = table.keys(scopes)

    for i, scope in ipairs(parsed) do
        parsed[i] = surl.escape(scope)
    end

    return table.concat(parsed, "+")
end

--Turns a table into url parameters.
function paramify(params)
    local args = {}
    
    --Turn the params table into url parameters
    for k, v in pairs(params) do
        args[#args + 1] = TL("%{k}=%{v}", {
            k = k,
            v = v
        })
    end

    return table.concat(args, "&")
end

    --======CONSTRUCTOR======--

function Oauth2:new(client_id, client_secret)
    local p = private[self]

    TypeError:assert(is(client_id, "string"), "client_id", type(client_id), "string")
    TypeError:assert(is(client_secret, "string"), "client_secret", type(client_secret), "string")

    p.client_id     = client_id
    p.client_secret = client_secret

    p.scopes         = {}
    p.fetch_requests = {}

    p.scope_callback = parseScopes
end

    --======METHODS======--

--Attempt to authorize the user using the Oauth2 implicit grant flow. Provide a
--port to specify, otherwise uses an ephermal port. Provide html for the redirect
--page, otherwise uses a default page. Generally not the version you want to use,
--as it requires you to implement a whole ass client sided browser.
--NOTE: Not fully completed, as the implicit flow (via Twitch, specifically) does not
--pass the token to the server. This function in some way assumes you're running a web
--browser inside of love2d to capture that info, which we're just not doing.
--Will throw an unimplemented error when called.
function Oauth2:implicitGrant(url, port, html)
    UnimplementedError:throw("implicitGrant")

    local p, server, uuid, client, data

    p = private[self]

    TypeError:assert(is(url, "string"), "url", type(url), "string")
    TypeError:assert(is(port, "number") or is(port, "nil"), "port", type(port), "string/nil")
    TypeError:assert(is(html, "string") or is(html, "nil"), "html", type(html), "string/nil")

    server = HTTPS("localhost", port or 0)
    html   = html or default_html
    uuid   = math.uuid()

    --Open the user's system browser with the url from the server.
    love.system.openURL(TL("%{url}?%{args}", {
        url  = url,
        args = paramify({
            response_type = "token",
            redirect_uri  = server.url,
            client_id     = p.client_id,
            scope         = p.scope_callback(p.scopes),
            state         = uuid
        })
    }))
    
    --Rather than make Ouath2 need to access the main loop, we just
    --briefly create an Async function, and shut it down when we're
    --no longer using it.
    Async(function()
        while server.running do
            server:update()
            Async:wait(0)
        end
    end)

    --Wait for the data from the client, which in this case will be the
    --client submitting the data, and requesting the redirect. We send a
    --raw HTML response after.
    --GOTCHA: Does *not* handle chunked encoding; expects specifically a single
    --data call with all of the data in it.
    server, data, client = Async:waitForEvent(server, "request")

    --Send the new page to the client.
    client:send(server:response(data.protocol, self.default_html))

    --Close the server.
    --NOTE: Might be worth listening for the "closed" event, and closing then.
    --That way, if the user refreshes the page, or something, it's not lost.
    --Just incase the HTML contains something that the user might want to
    --keep track of.
    server:close()

    AuthorizationError:assert(not data.error, data.error_description)
    
    --GOTCHA: Here's the rub; the data in the url exists only in the *fragment*,
    --and therefore isn't sent to the server. We can split the url into it's
    --parts, but we won't have access to the `data.code`. That is basically the
    --ONLY difference between implicitGrant and authorizationCodeGrant.
    
    --Split the query values into a table, and unescape the uri encoding.
    data = table.foreach(data.url.query:split("&"), function(_, v)
        return table.unpack(surl.unescape(v):split("="))
    end)
    
    --According to Twitch, we're supposed to check to make sure the state
    --still matches. The spec says it as well, I believe, but this *may*
    --be a GOTCHA if others don't implement oauth2 correctly.
    StateMismatchError:assert(data.state == uuid, data.state, uuid)
    
    --Cache the token request.
    if not p.token_request then
        p.token_request = HTTPS(p.token_url)
    end

    --Set the form data. This is not cached, because the code will
    --likely be different.
    p.token_request:setData({
        client_secret = p.client_secret,
        redirect_uri  = server.url,
        grant_type    = "authorization_code",
        client_id     = p.client_id,
        code          = data.code
    }, p.token_request.FORM)

    return self
end

--Unimplemented, but here for completeness. You would use this if you were
--trying to ouath on something like a game console. Quote; This flow is designed
--for applications which do not use a server and are located on a stand alone
--device, such as a set-top box or a video game console.
function Oauth2:deviceCodeGrant()
    UnimplementedError:throw("deviceCodeGrant")

    return self
end

--Attempts to authorize using the Oauth2 client credentials grant flow.
--Only for server-to-server API requests that use an app access token.
function Oauth2:clientCredentialsGrant(url)
    local p, request, code, data

    p = private[self]

    request = HTTPS(TL("%{url}?%{args}", {
        url  = url,
        args = paramify({
            client_secret = p.client_secret,
            grant_type    = "client_credentials",
            client_id     = p.client_id
        })
    }))

    code, data = request:fetch()

    WithinAsyncError:assert(code == 200, data)

    data = json.parse(data)

    p.access_token = data.access_token

    return self
end

--Attempts to authorize using the Oauth2 authorization code grant flow.
--This flow is meant for apps that use a server, can securely store a
--client secret, and can make server-to-server requests to the Twitch API. Provide a
--port to specify, otherwise uses an ephermal port. Provide html for the redirect
--page, otherwise uses a default page.
--Likely the one you want.
function Oauth2:authorizationCodeGrant()
    local p, server, uuid, client, data, code

    p = private[self]

    UnsetError:assert(p.authorization_url, "authorization_url", "authorizationCodeGrant")
    UnsetError:assert(p.token_url, "token_url", "authorizationCodeGrant")

    server = HTTPServer("localhost", self.redirect_port)
    uuid   = math.uuid()

    --Open the user's system browser with the url from the server.
    --GOTCHA: If you're using localhost for Twitch, it is incredibly
    --incredibly picky. The `server.url` value does not have a trailing
    --slash by default, so it is important to provide one. As well,
    --a port is required, since Twitch *needs* to know the port address.
    love.system.openURL(TL("%{url}?%{args}", {
        url  = p.authorization_url,
        args = paramify({
            response_type = "code",
            redirect_uri  = server.url,
            client_id     = p.client_id,
            scope         = p.scope_callback(p.scopes),
            state         = uuid
        })
    }))
    
    --Rather than make Ouath2 need to access the main loop, we just
    --briefly create an Async function, and shut it down when we're
    --no longer using it.
    Async(function()
        while server.running do
            server:update()
            Async:wait(0)
        end
    end)
    
    --Wait for the data from the client, which in this case will be the
    --client submitting the data, and requesting the redirect. We send a
    --raw HTML response after.
    --GOTCHA: Does *not* handle chunked encoding; expects specifically a single
    --data call with all of the data in it.
    server, data, client = Async:waitForEvent(server, "request")

    --Send the new page to the client.
    client:send(server:response(data.protocol, self.default_html))

    --Close the server.
    --NOTE: Might be worth listening for the "closed" event, and closing then.
    --That way, if the user refreshes the page, or something, it's not lost.
    --Just incase the HTML contains something that the user might want to
    --keep track of.
    server:close()

    AuthorizationError:assert(not data.error, data.error_description)
    
    --Split the query values into a table, and unescape the uri encoding.
    data = table.foreach(data.url.query:split("&"), function(_, v)
        return table.unpack(surl.unescape(v):split("="))
    end)
    
    --According to Twitch, we're supposed to check to make sure the state
    --still matches. The spec says it as well, I believe, but this *may*
    --be a GOTCHA if others don't implement oauth2 correctly.
    StateMismatchError:assert(data.state == uuid, data.state, uuid)
    
    --Cache the token request.
    if not p.token_request then
        p.token_request = HTTPS(p.token_url)
    end

    --Set the form data. This is not cached, because the code will
    --likely be different.
    p.token_request:setData({
        client_secret = p.client_secret,
        redirect_uri  = server.url,
        grant_type    = "authorization_code",
        client_id     = p.client_id,
        code          = data.code
    }, p.token_request.FORM)

    --Make the request, check to make sure we have a 200 code, parse the json.
    code, data = p.token_request:fetch()
    
    WithinAsyncError:assert(code == 200, data)

    data = json.parse(data)

    p.access_token  = data.access_token
    p.refresh_token = data.refresh_token

    return self
end

--An alias for authorizationCodeGrant.
Oauth2.authorize = Oauth2.authorizationCodeGrant

--Provide the authorization, token, and refresh urls so they don't
--need to be passed around like a trans puppy girl at a dungeon.
--Allows you to set them all at once, rather than needing to do them
--individually with the getters/setters, and is chainable.
function Oauth2:defineURLs(auth, token, refresh)
    local p = private[self]

    TypeError:assert(is(refresh, "string"), "refresh", type(refresh), "string")
    TypeError:assert(is(token, "string"), "token", type(token), "string")
    TypeError:assert(is(auth, "string"), "auth", type(auth), "string")

    p.authorization_url = auth
    p.refresh_url       = refresh
    p.token_url         = token

    return self
end

--Add a scope to the list of scopes that will be requested.
function Oauth2:addScope(scope)
    TypeError:assert(is(scope, "string"), scope, type(scope), "string")

    private[self].scopes[scope:lower()] = true

    return self
end

--Remove a scope from the list of scopes that will be requested.
function Oauth2:removeScope(scope)
    TypeError:assert(is(scope, "string"), scope, type(scope), "string")

    private[self].scopes[scope:lower()] = nil

    return self
end

--Attepts to refresh tokens.
function Oauth2:refreshTokens()
    local p, code, data

    p = private[self]

    UnsetError:assert(p.client_id, "client_id", "refreshTokens")
    UnsetError:assert(p.refresh_url, "refresh_url", "refreshTokens")
    UnsetError:assert(p.refresh_token, "refresh_token", "refreshTokens")
    UnsetError:assert(p.client_secret, "client_secret", "refreshTokens")

    --Cache the request instance.
    if not p.refresh_request then
        p.refresh_request = HTTPS(p.refresh_url)
    end

    --Do not cache the data, as the refresh token may have changed.
    p.refresh_request:setData({
        client_id     = p.client_id,
        grant_type    = "refresh_token",
        client_secret = p.client_secret,
        refresh_token = p.refresh_token
    }, p.refresh_request.FORM)

    code, data = p.refresh_request:fetch()
    
    WithinAsyncError:assert(code == 400 or code == 200, data)

    data = json.parse(data)

    --If it's a 400 token, then the refresh_token was likely invalid. We
    --fully start over from the beginning. If a refresh token is expected,
    --then it's assumed that the bot is using authorization code grant
    --flow, since that's the only one that provides a refresh token.
    if code == 400 then
        p.refresh_token = nil
        p.access_token  = nil

        return self:authorizationCodeGrant()
    end

    p.access_token = data.access_token

    return self
end

    --======GETTERS======--

function Oauth2.__get:redirect_port()
    return private[self].redirect_port or 0
end

function Oauth2.__get:default_html()
    return private[self].default_html or default_html
end

function Oauth2.__get:authorization_url()
    return private[self].authorization_url
end

function Oauth2.__get:refresh_url()
    return private[self].refresh_url
end

function Oauth2.__get:token_url()
    return private[self].token_url
end

function Oauth2.__get:access_token()
    return private[self].access_token
end

function Oauth2.__get:refresh_token()
    return private[self].refresh_token
end

function Oauth2.__get:scopes()
    return private[self].scopes
end
    --======SETTERS======--

function Oauth2.__set:redirect_port(value)
    TypeError:assert(is(value, "number") or is(value, "nil"), "redirect_port", type(value), "number/nil")

    private[self].redirect_port = value
end

function Oauth2.__set:default_html(value)
    TypeError:assert(is(value, "string") or is(value, "nil"), "default_html", type(value), "string/nil")

    private[self].default_html = value
end

function Oauth2.__set:authorization_url(value)
    TypeError:assert(is(value, "string"), "authorization_url", type(value), "string")

    private[self].authorization_url = value
end

function Oauth2.__set:refresh_url(value)
    TypeError:assert(is(value, "string"), "refresh_url", type(value), "string")

    private[self].refresh_url = value
end

function Oauth2.__set:token_url(value)
    TypeError:assert(is(value, "string"), "token_url", type(value), "string")

    private[self].token_url = value
end

function Oauth2.__set:access_token(value)
    TypeError:assert(is(value, "string"), "access_token", type(value), "string")

    private[self].access_token = value
end

function Oauth2.__set:refresh_token(value)
    TypeError:assert(is(value, "string"), "refresh_token", type(value), "string")

    private[self].refresh_token = value
end

    --======METAMETHODS======--

function Oauth2:__tostring()
    if self.is_instance then return self:tostringHelper(table.unpack(private[self].scopes)) end

    return self:tostringHelper("Class")
end

Oauth2.__type = "google_Oauth22"

return Oauth2
