---@meta ANSIColor

--Add colors to your terminal. Will return a singleton.
---@class ANSIColor.Class
---@overload fun(): ANSIColor
local ANSIColorClass = {}

---This table should be treated as a modified form of `print`. Pass in any amount of values, along with
---colors codes, and it will print the result to the terminal. The outputted colors assume that your
---terminal can handle truecolor color codes, which are in the format `<U+001B>[<38/48>;2;<red>;<green>;<blue>m`,
---where `<U+001B>` is the unicode escape character, `<38/48>` is the literal number 38 or 48 (foreground
---or background), and `<red>`, `<green>`, and `<blue>` are the red, green, and blue numeric values of
---the color, each being in the range of 0 to 255.
---
---You must have an equal amount of open and closing tags, but color tags can stack within each other.
---The following is an contrived example, where "ERROR" has white brackets and red text, followed by
---changing the background color of "greater than" to white, and it's actual text to black:
---```lua
---local ANSIColor, cprint
---
---ANSIColor = require("classes.ANSIColor")
---
---cprint = ANSIColor()
---
---if some_value > 0 then
---    cprint("{#FFFFFF}[{#FF0000}ERROR{#/}]{#/}", some_value, " should be {b#FFFFFF}{#000000}greater than{#/}{#/} 0.")
---end
---```
---@class ANSIColor : Classy.Object
---@overload fun(value: string)
local ANSIColor = {}