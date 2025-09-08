export type Color = "reset" | "black" | "red" | "green" | "yellow" | "blue" | "purple" | "cyan" | "white"
export type Style = "reset" | "bold" | "dim"

type PromptFn = (
	(() -> string)
	& ((kind: "text", message: string?, defaultOrOptions: string?) -> string)
	& ((kind: "confirm", message: string, defaultOrOptions: boolean?) -> boolean)
	& ((kind: "select", message: string?, defaultOrOptions: { string }) -> number?)
	& ((kind: "multiselect", message: string?, defaultOrOptions: { string }) -> { number }?)
)

--[=[
	@within Stdio
	@function prompt
	@tag must_use

	Prompts for user input using the wanted kind of prompt:

	* `"text"` - Prompts for a plain text string from the user
	* `"confirm"` - Prompts the user to confirm with y / n (yes / no)
	* `"select"` - Prompts the user to select *one* value from a list
	* `"multiselect"` - Prompts the user to select *one or more* values from a list
	* `nil` - Equivalent to `"text"` with no extra arguments

	@param kind The kind of prompt to use
	@param message The message to show the user
	@param defaultOrOptions The default value for the prompt, or options to choose from for selection prompts
]=]
local prompt: PromptFn = function(kind: any, message: any, defaultOrOptions: any)
	return require("@intern/tui").prompt(kind, message, defaultOrOptions)
end

--[=[
	@class Stdio

	Built-in standard input / output & utility functions

	### Example usage

	```lua
	local stdio = require("@lune/stdio")

	-- Prompting the user for basic input
	local text: string = stdio.prompt("text", "Please write some text")
	local confirmed: boolean = stdio.prompt("confirm", "Please confirm this action")

	-- Writing directly to stdout or stderr, without the auto-formatting of print/warn/error
	stdio.write("Hello, ")
	stdio.write("World! ")
	stdio.write("All on the same line")
	stdio.ewrite("\nAnd some error text, too")

	-- Reading a single line from stdin
	local line = stdio.readLine()

	-- Reading the entire input from stdin
	local input = stdio.readToEnd()
	```
]=]
local stdio = {}

stdio.prompt = prompt

--[=[
	@within Stdio
	@tag must_use

	Return an ANSI string that can be used to modify the persistent output color.

	Pass `"reset"` to get a string that can reset the persistent output color.

	### Example usage

	```lua
	stdio.write(stdio.color("red"))
	print("This text will be red")
	stdio.write(stdio.color("reset"))
	print("This text will be normal")
	```

	@param color The color to use
	@return A printable ANSI string
]=]
function stdio.color(color: Color): string
	return require("@intern/ansi")[color] or error("unknown color")
end

--[=[
	@within Stdio
	@tag must_use

	Return an ANSI string that can be used to modify the persistent output style.

	Pass `"reset"` to get a string that can reset the persistent output style.

	### Example usage

	```lua
	stdio.write(stdio.style("bold"))
	print("This text will be bold")
	stdio.write(stdio.style("reset"))
	print("This text will be normal")
	```

	@param style The style to use
	@return A printable ANSI string
]=]
function stdio.style(style: Style): string
	return require("@intern/ansi")[style] or error("unknown style")
end

--[=[
	@within Stdio
	@tag must_use

	Formats arguments into a human-readable string with syntax highlighting for tables.

	@param ... The values to format
	@return The formatted string
]=]
function stdio.format(...: any): string
	local function fmt(value: any, depth: number, key: boolean?)
		local INDENT = "    "
		depth = depth or 0

		if value == nil then
			return "nil"
		elseif type(value) == "boolean" or type(value) == "number" then
			return tostring(value)
		elseif type(value) == "string" then
			return `"{value:gsub(`[%z\128-\255]`, ""):gsub('"', '\\"'):gsub('\n', '\\n')}"`
		elseif type(value) == "function" then
			return `<{tostring(value)}>`
		elseif type(value) == "table" then
			if key then
				return `<{tostring(value)}>`
			end
			if depth >= 4 then
				return "{ ... }"
			end
			local mt = getmetatable(value)
			if mt ~= nil then
				local typename
				if type(mt) == "table" then
					if mt.__type ~= nil then
						typename = mt.__type
					end
				end
				if typename then
					return `<{typename}({tostring(value)})>`
				end
				return tostring(value)
			end
			local array_result = {}
			local string_result = {}
			local any_result = {}
			local size = #value
			local real_size = 0
			for _ in value do
				real_size += 1
			end
			for k, v in value do
				if type(k) == "string" then
					table.insert(string_result, `\n{string.rep(INDENT, depth + 1)}{k} = {fmt(v, depth + 1)}`)
				elseif type(k) == "number" and k <= size and size == real_size then
					table.insert(array_result, `\n{string.rep(INDENT, depth + 1)}{fmt(v, depth + 1)}`)
				else
					table.insert(any_result, `\n{string.rep(INDENT, depth + 1)}[{fmt(k, depth, true)}] = {fmt(v, depth + 1)}`)
				end
			end
			table.sort(string_result, function(a: string, b: string): boolean
				return a < b
			end)
			table.sort(any_result, function(a: string, b: string): boolean
				return a < b
			end)
			table.sort(array_result, function(a: string, b: string): boolean	
				return a < b
			end)
			local result = {}
			table.move(array_result, 1, #array_result, #result + 1, result)
			table.move(any_result, 1, #any_result, #result + 1, result)
			table.move(string_result, 1, #string_result, #result + 1, result)
			if #result == 0 then
				return "{}"
			end
			table.insert(result, `\n{string.rep(INDENT, depth)}`)
			return `\{{table.concat(result, ',')}}`
		else
			return `<{type(value)}>`
		end
	end
	local out = {}
	for _, v in {...} do
		if type(v) == "string" then
			table.insert(out, v)
			continue
		elseif type(v) == "table" and getmetatable(v) ~= nil then
			local mt = getmetatable(v)
			if mt ~= nil then
				local typename
				if type(mt) == "table" then
					if mt.__type ~= nil then
						typename = mt.__type
					end
				end
				if typename then
					table.insert(out, `{typename}`)
					continue
				end
				table.insert(out, tostring(v))
				continue
			end
		end
		table.insert(out, fmt(v, 0))
	end
	return table.concat(out, " ")
end

--[=[
	@within Stdio

	Writes a string directly to stdout, without any newline.

	@param s The string to write to stdout
]=]
function stdio.write(s: string)
	zune.io.stdout:write(s)
end

--[=[
	@within Stdio

	Writes a string directly to stderr, without any newline.

	@param s The string to write to stderr
]=]
function stdio.ewrite(s: string)
	zune.io.stderr:write(s)
end

--[=[
    @within Stdio
    @tag must_use

    Reads a single line from stdin.

    If stdin is closed, returns all input up until its closure.

    @return The input from stdin
]=]
function stdio.readLine(): string
	local thread = coroutine.running()

	zune.task.defer(function()
		local result = ""
		while true do
			local ok, char = pcall(zune.io.stdin.read, zune.io.stdin, 1)
			if not ok then
				break
			end
			result ..= char
			if char ~= "\n" then
				continue
			end
			break
		end
		zune.task.spawn(thread, result)
	end)

	return coroutine.yield()
end

--[=[
    @within Stdio
    @tag must_use

    Reads the entire input from stdin.

    @return The input from stdin
]=]
function stdio.readToEnd(): string
	local thread = coroutine.running()

	zune.task.defer(function()
		local loop_thread = coroutine.running()
		local result = ""
		while true do
			local resume = zune.task.delay(0.5, function()
				zune.task.spawn(loop_thread, nil)
			end)
			local ok, char = pcall(zune.io.stdin.read, zune.io.stdin, 1)
			zune.task.cancel(resume)
			if not ok or not char then
				break
			end
			result ..= char
		end
		zune.task.spawn(thread, result)
	end)

	return coroutine.yield()
end

return stdio