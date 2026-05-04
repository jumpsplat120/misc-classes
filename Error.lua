local Object, private
local Error

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Error = Object:init()

private[Error] = {}

--======PRIVATE FUNCTIONS======--

local oopsies, throw

--Custom error messages for the error handler.
oopsies = {
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

--Helper function that derives the relevant information, creates the message from
--the various passed values, and throws a real error at the right stack level.
function throw(self, ...)
    local p = private[self]

    private[Error].trace = debug.traceback(("%sError: %s:%s: %s"):format(
        table.concat(table.foreach(p.type:split("_"), function(i, v) return i, v:title() end), ""),
        debug.getinfo(3, "S").short_src,
        debug.getinfo(3, "l").currentline,
        p.message:format(...)
    ), 3)
    
    --We should never see this.
    error("I frew up.")
end

--Overwrite the love.errorhandler to specfically use our Error class.
function love.errorhandler(msg)
    local trace, lines, onscreen_text, full_err_text
    
    lines = {}
    
    --If a table is returned, that's an error from within a coroutine, likely
    --part of Async and Game. If all the Error stuff exists, then we use that,
    --otherwise we use the message pulled from the table, since that's the
    --inner stacktrace. If it's neither, then it's an error from outside the
    --coroutines, and so we just trace normally.
    if private[Error].trace then
        trace = private[Error].trace
    elseif type(msg) == "table" then
        trace = msg[1]
    else
        trace = debug.traceback(msg)
    end
    
    print(trace)

	if not love.window   then return end
    if not love.graphics then return end
    if not love.event    then return end

	if not love.graphics.isCreated() or not love.window.isOpen() then
		local success, status = pcall(love.window.setMode, 800, 600)

        if not success then return end
        if not status  then return end
	end

    if love.mouse then
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
		love.mouse.setRelativeMode(false)
		
        if love.mouse.isCursorSupported() then
            love.mouse.setCursor()
        end
	end

	if love.joystick then
		for _, v in ipairs(love.joystick.getJoysticks()) do
            v:setVibration()
        end
	end

	if love.audio then
        love.audio.stop()
    end

	love.graphics.reset()
	love.graphics.origin()
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(14)

    lines[#lines + 1] = table.random(oopsies) .. "\n"

    do
        local indent = ""

        for line in trace:gmatch("(.-)\n") do
            if line == "stack traceback:" then
                line   = "\nstack traceback:\n"
                indent = "        "
            end

            lines[#lines + 1] = indent .. line
        end
    end
    
	onscreen_text = table.concat(lines, "\n")

	onscreen_text = onscreen_text:gsub("\t", "")
	onscreen_text = onscreen_text:gsub("%[string \"(.-)\"%]", "%1")

	full_err_text = onscreen_text

	if love.system then
        onscreen_text = onscreen_text .. "\n\nPress Ctrl+C or tap to copy this error"
    end
    
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

function Error:new(t, message)
    local p = private[self]
    
    assert(type(t) == "string", "'t' is of type '" .. type(t) .. "' instead of type 'string'.")
    assert(type(message) == "string", "'message' is of type '" .. type(message) .. "' instead of type 'string'.")

    p.type     = t
    p.message  = message
end

--======METHODS======--

--If `bool` is `false`, then throws the error, along with all passed values.
function Error:assert(bool, ...)
    if bool then return bool end
    
    throw(self, ...)
end

--Immediately throw, along with all passed values.
function Error:throw(...)
    throw(self, ...)
end

--======GETTERS======--

--======SETTERS======--

--======METAMETHODS======--

function Error:__tostring()
    local p = private[self]

    return self:tostring(p.type, p.message)
end

Error.__type = "error"

return Object:create(Error)