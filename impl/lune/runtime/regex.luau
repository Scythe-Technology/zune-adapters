--[=[
	@class RegexMatch

	A match from a regular expression.

	Contains the following values:

	- `start` -- The start index of the match in the original string.
	- `finish` -- The end index of the match in the original string.
	- `text` -- The text that was matched.
	- `len` -- The length of the text that was matched.
]=]
local RegexMatch = {
	start = (nil :: any) :: number,
	finish = (nil :: any) :: number,
	text = (nil :: any) :: string,
	len = (nil :: any) :: number,
}

RegexMatch.__type = "RegexMatch"
RegexMatch.__tostring = function(self: RegexMatch): string
	return self.text
end
RegexMatch.__len = function(self: RegexMatch): number
	return self.len
end

local function newRegexMatch(zune_match): RegexMatch
	return setmetatable({
		start = zune_match.index,
		finish = zune_match.index + #zune_match.string - 1,
		text = zune_match.string,
		len = #zune_match.string,
	}, RegexMatch) :: any
end

type RegexMatch = typeof(RegexMatch)

local RegexCaptures = {}
RegexCaptures.__type = "RegexCaptures"
RegexCaptures.__index = RegexCaptures
RegexCaptures.__tostring = function(self: RegexCaptures): string
	if self.len == nil or self.len == 0 then
		return "0"
	end
	return tostring(self.len - 1)
end
RegexCaptures.__len = function(self: RegexCaptures): number
	return self.len - 1
end

function RegexCaptures.get(self: RegexCaptures, index: number): RegexMatch?
	local res = self[index + 1]
	if res == nil then
		return nil
	end
	return newRegexMatch(res)
end

function RegexCaptures.group(self: RegexCaptures, group: string): RegexMatch?
	for i = 1, self.len do
		local match = self[i]
		if match.name == group then
			return newRegexMatch(match)
		end
	end
	return
end

function RegexCaptures.format(self: RegexCaptures, format: string): string
	return self.__internal:format(self[1].string, format)
end

--[=[
	@class RegexCaptures

	Captures from a regular expression.
]=]
export type RegexCaptures = typeof(setmetatable(
	{} :: {
		__internal: Regex,
		len: number,
		--[=[
			@within RegexCaptures
			@tag Method
			@method get

			Returns the match at the given index, if one exists.

			@param index -- The index of the match to get
			@return RegexMatch -- The match, if one exists
		]=]

		get: (self: RegexCaptures, index: number) -> RegexMatch?,

		--[=[
			@within RegexCaptures
			@tag Method
			@method group

			Returns the match for the given named match group, if one exists.

			@param group -- The name of the group to get
			@return RegexMatch -- The match, if one exists
		]=]
		group: (self: RegexCaptures, group: string) -> RegexMatch?,

		--[=[
			@within RegexCaptures
			@tag Method
			@method format

			Formats the captures using the given format string.

			### Example usage

			```lua
			local regex = require("@lune/regex")

			local re = regex.new("(?<day>[0-9]{2})-(?<month>[0-9]{2})-(?<year>[0-9]{4})")

			local caps = re:captures("On 14-03-2010, I became a Tenneessee lamb.");
			assert(caps ~= nil, "Example pattern should match example text")

			local formatted = caps:format("year=$year, month=$month, day=$day")
			print(formatted) -- "year=2010, month=03, day=14"
			```

			@param format -- The format string to use
			@return string -- The formatted string
		]=]
		format: (self: RegexCaptures, format: string) -> string,
	},
	{} :: {
		__len: (self: RegexCaptures) -> number,
	}
))

local Regex = {
	pattern = (nil :: any) :: string,
	__internal = (nil :: any) :: Regex,
}
Regex.__type = "Regex"
Regex.__tostring = function(self: LuneRegex): string
	return self.pattern
end
Regex.__index = Regex

--[=[
	@within Regex
	@tag Method

	Check if the given text matches the regular expression.

	This method may be slightly more efficient than calling `find`
	if you only need to know if the text matches the pattern.

	@param text -- The text to search
	@return boolean -- Whether the text matches the pattern
]=]
function Regex.isMatch(self: LuneRegex, text: string): boolean
	return self.__internal:isMatch(text) or self.__internal:search(text) ~= nil
end

--[=[
	@within Regex
	@tag Method

	Finds the first match in the given text.

	Returns `nil` if no match was found.

	@param text -- The text to search
	@return RegexMatch? -- The match object
]=]
function Regex.find(self: LuneRegex, text: string): RegexMatch?
	local result = self.__internal:search(text)
	if not result then
		return nil
	end
	local match = result[1]
	return newRegexMatch(match)
end

--[=[
	@within Regex
	@tag Method

	Finds all matches in the given text as a `RegexCaptures` object.

	Returns `nil` if no matches are found.

	@param text -- The text to search
	@return RegexCaptures? -- The captures object
]=]
function Regex.captures(self: LuneRegex, text: string): RegexCaptures?
	local captures = self.__internal:captures(text, false)
	if #captures == 0 then
		return nil
	end
	local capture = captures[1]
	capture.len = #capture
	capture.__internal = self.__internal
	return setmetatable(capture, RegexCaptures)
end

--[=[
	@within Regex
	@tag Method

	Splits the given text using the regular expression.

	@param text -- The text to split
	@return { string } -- The split text
]=]
function Regex.split(self: LuneRegex, text: string): { string }
	return self.__internal:split(text, true)
end

--[=[
	@within Regex
	@tag Method

	Replaces the first match in the given text with the given replacer string.

	@param haystack -- The text to search
	@param replacer -- The string to replace matches with
	@return string -- The text with the first match replaced
]=]
function Regex.replace(self: LuneRegex, haystack: string, replacer: string): string
	return self.__internal:replace(haystack, replacer)
end

--[=[
	@within Regex
	@tag Method

	Replaces all matches in the given text with the given replacer string.

	@param haystack -- The text to search
	@param replacer -- The string to replace matches with
	@return string -- The text with all matches replaced
]=]
function Regex.replaceAll(self: LuneRegex, haystack: string, replacer: string): string
	return self.__internal:replaceAll(haystack, replacer)
end

export type LuneRegex = typeof(Regex)

--[=[
	@class Regex

	Built-in library for regular expressions

	### Example usage

	```lua
	local Regex = require("@lune/regex")

	local re = Regex.new("hello")

	if re:isMatch("hello, world!") then
		print("Matched!")
	end

	local caps = re:captures("hello, world! hello, again!")

	print(#caps) -- 2
	print(caps:get(1)) -- "hello"
	print(caps:get(2)) -- "hello"
	print(caps:get(3)) -- nil
	```
]=]
local regex = {}

--[=[
	@within Regex
	@tag Constructor

	Creates a new `Regex` from a given string pattern.

	### Errors

	This constructor throws an error if the given pattern is invalid.

	@param pattern -- The string pattern to use
	@return Regex -- The new Regex object
]=]
function regex.new(pattern: string): LuneRegex
	local compiled = zune.regex.create(pattern)
	return setmetatable({
		pattern = pattern,
		__internal = compiled,
	}, Regex) :: any
end

return regex