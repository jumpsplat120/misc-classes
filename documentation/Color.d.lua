---@meta Color

---@class Color.Class : Classy.Object, Unpack.Mixin, Ipairs.Mixin, AsTable.Mixin
---@field hex string
---@field rgb {red:number,green:number,blue:number,alpha:number}
---@field hsv {hue:number,saturation:number,value:number,alpha:number}
---@field hsl {hue:number,saturation:number,lightness:number,alpha:number}
---@field hsb {hue:number,saturation:number,brightness:number,alpha:number}
---@field red number
---@field blue number
---@field alpha number
---@field green number
---@field value number
---@field red255 number
---@field rgb255 {red:number,green:number,blue:number,alpha:number}
---@field hsv_hue number
---@field hsl_hue number
---@field blue255 number
---@field green255 number
---@field lightness number
---@field brightness number
---@field hsv_saturation number
---@field hsl_saturation number
Color = {}

---comment
---@param hue any
---@param saturation any
---@param value any
---@param alpha any
function Color:fromHSV(hue, saturation, value, alpha) end

---comment
---@param hue any
---@param saturation any
---@param brightness any
---@param alpha any
function Color:fromHSB(hue, saturation, brightness, alpha) end

---comment
---@param hue any
---@param saturation any
---@param lightness any
---@param alpha any
function Color:fromHSL(hue, saturation, lightness, alpha) end

---comment
---@param red any
---@param green any
---@param blue any
---@param alpha any
function Color:fromRGB(red, green, blue, alpha) end

---comment
---@param red any
---@param green any
---@param blue any
---@param alpha any
function Color:fromRGB255(red, green, blue, alpha) end

---comment
---@param hex any
function Color:fromHex(hex) end

---comment
---@param opts any
function Color:new(opts) end

---comment
function Color:apply() end

---comment
function Color:applyBackground() end

---comment
---@param color any
---@param mode any
---@param percentage any
function Color:blend(color, mode, percentage) end

---comment
function Color:clone() end