---@type Object
local Object
local private, Symbol
local TypeError, HTTPResponseError, InvalidError, RangeError
local Weather, HTTPS, Error, Date
local TL, is
local url
local json


Object  = require("lib.Classy")
private = require("lib.Classy.instances")
Symbol  = require("lib.Classy.Symbol")

HTTPResponseError = require("classes.errors.HTTPResponseError")
InvalidError      = require("classes.errors.InvalidError")
RangeError        = require("classes.errors.RangeError")
TypeError         = require("classes.errors.TypeError")

Error = require("classes.Error")
HTTPS = require("classes.HTTPS")
Date  = require("classes.Date")

TL = require("lib.string_template")
is = require("lib.is")

json = require("third_party.json")

url  = require("socket.url")

Weather = Object:extend()

--======PRIVATE FUNCTIONS======--

local CURRENT, FORECAST, SEARCH, HISTORY, FUTURE, ASTRONOMY, TIMEZONE, SPORTS, JSON, XML
local symbols, IPAPIError

ASTRONOMY = Symbol("astronomy")
FORECAST  = Symbol("forecast")
TIMEZONE  = Symbol("timezone")
HISTORY   = Symbol("history")
CURRENT   = Symbol("current")
FUTURE    = Symbol("future")
SEARCH    = Symbol("search")
SPORTS    = Symbol("sports")
JSON      = Symbol("json")
XML       = Symbol("xml")

private[Weather] = {
    query = {
        [ASTRONOMY] = true,
        [FORECAST]  = true,
        [TIMEZONE]  = true,
        [HISTORY]   = true,
        [CURRENT]   = true,
        [FUTURE]    = true,
        [SEARCH]    = true,
        [SPORTS]    = true,
    },
    response = {
        [JSON] = true,
        [XML]  = true
    }
}

symbols = {
    response = table.join(table.keys(private[Weather].response), ", "),
    query    = table.join(table.keys(private[Weather].query), ", ")
}

IPAPIError = Error("ip_api", "No location was set, and failed to query 'ip-api' to get latitude/longitude. %s")

--======CONSTRUCTOR======--

function Weather:new(api_key)
    local p = private[self]

    TypeError:assert(is(api_key, "string"), "api_key", type(api_key), "string")

    p.api_key  = api_key
    p.query    = FORECAST
    p.response = JSON
    p.days     = 1
    p.aqi      = true
    p.alerts   = true
end

--======METHODS======--

function Weather:fetch()
    local p, connect, code, body

    p = private[self]

    if not p.location then
        --49344 provides only status, message, lat and lon as fields
        --to save on bandwidth.
        connect = HTTPS("http://ip-api.com/json/?fields=49344")

        code, body = connect:fetch()
        
        HTTPResponseError:assert(code == 200, code, 200)

        body = json.parse(body)

        IPAPIError:assert(body.status == "success", body.message)

        p.location = TL("{(body.lat},{body.lon}", { body = body })
    end

    connect = HTTPS(TL(
        "http://api.weatherapi.com/v1/"   ..
        "%{p.query.id}.%{p.response.id}"  ..
        "?key=%{p.api_key}&q=%{location}" .. 
        "&days=%{p.days}&aqi=%{p.aqi}"    ..
        "&alerts=%{p.alerts}%{date}", {
        location = url.escape(p.location),
        date = p.date and TL(
            "&dt=%{p.year}-" .. 
            "%{tostring(p.month):padLeft(2, '0')}-" .. 
            "%{tostring(p.day):padLeft(2, '0)}", {
                p = p
            }) or "",
        p = p
    }))

    code, body = connect:fetch()

    HTTPResponseError:assert(code == 200, code, 200)
    
    return json.parse(body)
end

--======GETTERS======--

function Weather.__get:date()
    return private[self].date
end

function Weather.__get:alerts()
    return private[self].alerts
end

function Weather.__get:aqi()
    return private[self].aqi
end

function Weather.__get:days()
    return private[self].days
end

function Weather.__get:location()
    return private[self].location
end

function Weather.__get:query()
    return private[self].query
end

function Weather.__get:response()
    return private[self].response
end

function Weather.__get:ASTRONOMY()
    if not self.instance then return ASTRONOMY end

    return rawget(self, "ASTRONOMY")
end

function Weather.__get:FORECAST()
    if not self.instance then return FORECAST end

    return rawget(self, "FORECAST")
end

function Weather.__get:TIMEZONE()
    if not self.instance then return TIMEZONE end

    return rawget(self, "TIMEZONE")
end

function Weather.__get:HISTORY()
    if not self.instance then return HISTORY end

    return rawget(self, "HISTORY")
end

function Weather.__get:CURRENT()
    if not self.instance then return CURRENT end

    return rawget(self, "CURRENT")
end

function Weather.__get:FUTURE()
    if not self.instance then return FUTURE end

    return rawget(self, "FUTURE")
end

function Weather.__get:SEARCH()
    if not self.instance then return SEARCH end

    return rawget(self, "SEARCH")
end

function Weather.__get:SPORTS()
    if not self.instance then return SPORTS end

    return rawget(self, "SPORTS")
end

function Weather.__get:JSON()
    if not self.instance then return JSON end

    return rawget(self, "JSON")
end

function Weather.__get:XML()
    if not self.instance then return XML end

    return rawget(self, "XML")
end

--======SETTERS======--

function Weather.__set:date(value)
    TypeError:assert(is(value, Date), "date", type(value), Date)

    private[self].date = value
end

function Weather.__set:alerts(value)
    TypeError:assert(is(value, "boolean"), "alerts", type(value), "boolean")

    private[self].alerts = value
end

function Weather.__set:aqi(value)
    TypeError:assert(is(value, "boolean"), "aqi", type(value), "boolean")

    private[self].aqi = value
end

function Weather.__set:days(value)
    TypeError:assert(is(value, "number"), "location", type(value), "number")
    RangeError:assert(value >= 1 and value <= 7, value, "location", 1, 7) --TODO: Double check the days range

    private[self].days = value
end

function Weather.__set:location(value)
    TypeError:assert(is(value, "string"), "location", type(value), "string")

    private[self].location = value
end

function Weather.__set:query(value)
    TypeError:assert(is(value, Symbol), "query", type(value), Symbol)
    InvalidError:assert(private[Weather].query[value], value, "query", symbols.query)

    private[self].query = value
end

function Weather.__set:response(value)
    TypeError:assert(is(value, Symbol), "response", type(value), Symbol)
    InvalidError:assert(private[Weather].response[value], value, "response", symbols.response)

    private[self].response = value
end

--======METAMETHODS======--

function Weather:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper(p.query) end

    return self:tostringHelper("Class")
end

Weather.__type = "weather"

return Weather