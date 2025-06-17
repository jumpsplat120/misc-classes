---@type Object
local Object
local Error, private, is

Object  = require("lib.Classy")
private = require("lib.Classy.instances")
is      = require("lib.is")

Error = Object:extend()

private[Error] = {}

--======PRIVATE FUNCTIONS======--

local oopsies = {
    "Dang, a crash!",
    "F in chat.",
    "Not again.",
    "0/10, worst game ever.",
    "Don't @ me.",
    "InDiE DeVeLoPeR",
    "Please oh god please I'm so sorry oh no oh god",
    "Oof.",
    "In the biz, we call this an oopsie daisy.",
    "Wow. This sucks.",
    "Please contact your system admin (or complain on twitter, you do you).",
    "Stopn't don't crashing.",
    "Crap, did I save?",
    "I would like to apologize.",
    "Alright, this could've gone better.",
    "Not my finest moment.",
    "Oh, wow, okay. RIP I guess.",
    "Okay don't panic doN'T PANIC",
    "You weren't supposed to see this.",
    "<insert quirky crash message here>",
    "WEE WOO ERROR ERROR WEE WOO",
    "Let's... just... pretend this didn't happen.",
    "Oh wow, this is embarrassing."
}

local function throw(self, ...)
    local p, c
    
    p = private[self]
    c = private[Error]

    c.title   = p.type:gsub("_", ""):title()
    c.src     = debug.getinfo(3, "S").short_src
    c.line    = debug.getinfo(3, "l").currentline
    c.message = p.message:format(...)

    error(c.message, 3)
end

local love = {}

function love.errorhandler(msg)
    local trace, err, onscreen_text, full_err_text, c
    
	msg = tostring(msg)
    
	if not love.window   then return end
    if not love.graphics then return end
    if not love.event    then return end

	if not love.window.isOpen() then
		local success, status = pcall(love.window.setMode, 800, 600)

        if not success then return end
        if not status  then return end
	end
    
    err = {}
    c   = private[Error]

    if c.title and c.src and c.line and c.message then
        trace = debug.traceback(("%sError: %s:%s: %s"):format(
            c.title,
            c.src,
            c.line,
            c.message
        ), 6)
    else
        trace = debug.traceback(msg, 4)
    end
    
    print(trace)
    --(trace:before("[love"):trim())

    if love.mouse then
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
		love.mouse.setRelativeMode(false)
		
        if love.mouse.isCursorSupported() then love.mouse.setCursor() end
	end

	if love.joystick then
		for _, v in ipairs(love.joystick.getJoysticks()) do v:setVibration() end
	end

	if love.audio then
        love.audio.stop()
    end

	love.graphics.reset()
	love.graphics.origin()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(14)

    err[#err + 1] = table.random(oopsies) .. "\n"

    do
        local after_traceback = false

        --Once we hit [love... that's love's native code that
        --is catching the errors. None of that will ever be relevant
        --so we can just stop at that point. I'm *pretty* sure that
        --they're always the last few lines.
        for line in trace:gmatch("(.-)\n") do
            if line:match("%[love") then break end

            line = line:gsub("stack traceback:", "\nTraceback\n")

            err[#err + 1] = after_traceback and "    " .. line or line

            if line:match("\nTraceback\n") then after_traceback = true end
        end
    end

	onscreen_text = table.concat(err, "\n")

	onscreen_text = onscreen_text:gsub("\t", "")
	onscreen_text = onscreen_text:gsub("%[string \"(.-)\"%]", "%1")

	full_err_text = onscreen_text

	if love.system then onscreen_text = onscreen_text .. "\n\nPress Ctrl+C or tap to copy this error" end

	return function()
		love.event.pump()

		for event, a in love.event.poll() do
			if event == "quit" then return 1 end

            if event == "keypressed" then
                if a == "escape" then return 1 end
                if a == "c" and love.keyboard.isDown("lctrl", "rctrl") then
                    if love.system then love.system.setClipboardText(full_err_text) end

                    onscreen_text = onscreen_text .. "\nCopied to clipboard!"
                end 
            end

            if event == "touchpressed" then
                local title, buttons, pressed, name
                
                title   = love.window.getTitle()
                buttons = {"OK", "Cancel"}

                if #title == 0        then name = "Game" end
                if name == "Untitled" then name = "Game" end

                if love.system then buttons[3] = "Copy to Clipboard" end

                pressed = love.window.showMessageBox(("Quit %s?"):format(name), "", buttons)

                if pressed == 1 then return 1 end
                if pressed == 3 then
                    if love.system then love.system.setClipboardText(full_err_text) end

                    onscreen_text = onscreen_text .. "\nCopied to clipboard!"
                end
            end
		end

		if love.graphics.isActive() then
            love.graphics.clear(89 / 255, 157 / 255, 220 / 255)
            love.graphics.printf(onscreen_text, 70, 70, love.graphics.getWidth() - 70)
            love.graphics.present()
        end

		if love.timer then love.timer.sleep(0.1) end
	end
end

--======CONSTRUCTOR======--

function Error:new(type, message)
    local p = private[self]

    assert(is(type,    "string"), "Error!")
    assert(is(message, "string"), "Error!")

    p.type     = type
    p.message  = message
end

--======METHODS======--

function Error:assert(bool, ...)
    if bool then return bool end
    
    throw(self, ...)
end

function Error:throw(...)
    throw(self, ...)
end

--======GETTERS======--

--======SETTERS======--

--======METAMETHODS======--

function Error:__tostring()
    local p = private[self]

    if self.is_instance then
        return self:tostringHelper(p.type, p.message)
    else
        return self:tostringHelper("Class")
    end
end

Error.__type = "error"

return Error