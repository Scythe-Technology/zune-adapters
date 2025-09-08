local time = {}

local NANOSECONDS_PER_SECOND = 1_000_000_000
local MICROSECONDS_PER_SECOND = 1_000_000
local MILLISECONDS_PER_SECOND = 1_000
local SECONDS_PER_MINUTE = 60
local SECONDS_PER_HOUR = 3600
local SECONDS_PER_DAY = 86400
local SECONDS_PER_WEEK = 604800
local NANOSECONDS_PER_MICROSECOND = 1_000
local NANOSECONDS_PER_MILLISECOND = 1_000_000

local function newTimespec(sec: number, nsec: number): buffer
	local spec = buffer.create(12)
	buffer.writef64(spec, 0, sec)
	buffer.writeu32(spec, 8, nsec)
	return spec
end
local function readTimespec(spec: buffer): (number, number)
	return buffer.readf64(spec, 0), buffer.readu32(spec, 8)
end
local function timespecToSeconds(spec: buffer): number
	local sec, nsec = readTimespec(spec)
	return sec + (nsec / NANOSECONDS_PER_SECOND)
end

local function diffTimespec(a: buffer, b: buffer): number
	local a_sec, a_nsec = readTimespec(a)
	local b_sec, b_nsec = readTimespec(b)
	local sec = a_sec - b_sec
	local nsec = a_nsec - b_nsec
	if nsec < 0 then
		sec -= 1
		nsec += NANOSECONDS_PER_SECOND
	end
	return sec + (nsec / NANOSECONDS_PER_SECOND)
end

local duration_ops = {}
duration_ops.__metatable = "The metatable is locked!"
duration_ops.__index = duration_ops

local function newDuration(spec: buffer): Duration
	return setmetatable({timestamp = spec}, duration_ops)
end

duration_ops.__tostring = function(self: Duration): string
	return string.format("%d.%09d", readTimespec(self.timestamp))
end
duration_ops.__add = function(a: Duration, b: Duration): Duration
	local left_sec, left_nsec = readTimespec(a.timestamp)
	local right_sec, right_nsec = readTimespec(b.timestamp)
	local sec = left_sec + right_sec
	local nsec = left_nsec + right_nsec
	if nsec >= NANOSECONDS_PER_SECOND then
		sec += 1
		nsec -= NANOSECONDS_PER_SECOND
	end
	return newDuration(newTimespec(sec, nsec))
end
duration_ops.__sub = function(a: Duration, b: Duration): Duration
	local left_sec, left_nsec = readTimespec(a.timestamp)
	local right_sec, right_nsec = readTimespec(b.timestamp)
	local sec = left_sec - right_sec
	local nsec = left_nsec - right_nsec
	if nsec < 0 then
		sec -= 1
		nsec += NANOSECONDS_PER_SECOND
	end
	return newDuration(newTimespec(math.max(sec, 0), math.max(nsec, 0)))
end
duration_ops.__eq = function(a: Duration, b: Duration): boolean
	local a_sec, a_nsec = readTimespec(a.timestamp)
	local b_sec, b_nsec = readTimespec(b.timestamp)
	return a_sec == b_sec and a_nsec == b_nsec
end
duration_ops.__lt = function(a: Duration, b: Duration): boolean
	local a_sec, a_nsec = readTimespec(a.timestamp)
	local b_sec, b_nsec = readTimespec(b.timestamp)
	return a_sec < b_sec or (a_sec == b_sec and a_nsec < b_nsec)
end
duration_ops.__le = function(a: Duration, b: Duration): boolean
	local a_sec, a_nsec = readTimespec(a.timestamp)
	local b_sec, b_nsec = readTimespec(b.timestamp)
	return a_sec < b_sec or (a_sec == b_sec and a_nsec <= b_nsec)
end

local function createDurationFromSeconds(seconds: number): Duration
	local sec = math.floor(seconds)
	local nsec = math.floor((seconds % 1) * NANOSECONDS_PER_SECOND)
	return newDuration(newTimespec(sec, nsec))
end

local instant = {}
instant.__metatable = "The metatable is locked!"
instant.__index = instant
instant.__sub = function(a: Instant, b: Instant): Duration
	return createDurationFromSeconds(diffTimespec(a.timestamp, b.timestamp))
end

local function newInstant(spec: buffer): Instant
	return setmetatable({timestamp = spec}, instant)
end

function time.now(): Instant
	return newInstant(zune.time.instant.now())
end

function time.since(instant: Instant): number
	local now = time.now()
	local left_sec, left_nsec = readTimespec(now.timestamp)
	local right_sec, right_nsec = readTimespec(instant.timestamp)
	local sec = left_sec - right_sec
	local nsec = left_nsec - right_nsec
	if nsec < 0 then
		sec = sec - 1
		nsec = nsec + NANOSECONDS_PER_SECOND
	end
	return sec + (nsec / 1e9)
end

time.duration = {}

function time.duration.nanoseconds(nanoseconds: number): Duration
	if (nanoseconds < 0) then
		error("duration cannot be negative", 2)
	end
	local seconds = 0
	if (nanoseconds >= NANOSECONDS_PER_SECOND) then
		seconds = nanoseconds // NANOSECONDS_PER_SECOND
		nanoseconds = nanoseconds % NANOSECONDS_PER_SECOND
	end
	return newDuration(newTimespec(seconds, nanoseconds))
end

function time.duration.microseconds(microseconds: number): Duration
	if (microseconds < 0) then
		error("duration cannot be negative", 2)
	end
	local seconds = 0
	if (microseconds >= MICROSECONDS_PER_SECOND) then
		seconds = microseconds // MICROSECONDS_PER_SECOND
		microseconds = microseconds % MICROSECONDS_PER_SECOND
	end
	return newDuration(newTimespec(seconds, microseconds * NANOSECONDS_PER_MICROSECOND))
end

function time.duration.milliseconds(milliseconds: number): Duration
	if (milliseconds < 0) then
		error("duration cannot be negative", 2)
	end
	local seconds = 0
	if (milliseconds >= MILLISECONDS_PER_SECOND) then
		seconds = milliseconds // MILLISECONDS_PER_SECOND
		milliseconds = milliseconds % MILLISECONDS_PER_SECOND
	end
	return newDuration(newTimespec(seconds, milliseconds * NANOSECONDS_PER_MILLISECOND))
end

function time.duration.seconds(seconds: number): Duration
	if (seconds < 0) then
		error("duration cannot be negative", 2)
	end
	return newDuration(newTimespec(seconds, 0))
end

function time.duration.minutes(minutes: number): Duration
	if (minutes < 0) then
		error("duration cannot be negative", 2)
	end
	return newDuration(newTimespec(minutes * SECONDS_PER_MINUTE, 0))
end

function time.duration.hours(hours: number): Duration
	if (hours < 0) then
		error("duration cannot be negative", 2)
	end
	return newDuration(newTimespec(hours * SECONDS_PER_HOUR, 0))
end

function time.duration.days(days: number): Duration
	if (days < 0) then
		error("duration cannot be negative", 2)
	end
	return newDuration(newTimespec(days * SECONDS_PER_DAY, 0))
end

function time.duration.weeks(weeks: number): Duration
	if (weeks < 0) then
		error("duration cannot be negative", 2)
	end
	return newDuration(newTimespec(weeks * SECONDS_PER_WEEK, 0))
end

function instant.elapsed(self: Instant): number
	return time.since(self)
end

function duration_ops.tonanoseconds(self: Duration): number
	local sec, nsec = readTimespec(self.timestamp)
	return (sec * NANOSECONDS_PER_SECOND) + nsec
end

function duration_ops.tomicroseconds(self: Duration): number
	return timespecToSeconds(self.timestamp) * MICROSECONDS_PER_SECOND
end

function duration_ops.tomilliseconds(self: Duration): number
	return timespecToSeconds(self.timestamp) * MILLISECONDS_PER_SECOND
end

function duration_ops.toseconds(self: Duration): number
	return timespecToSeconds(self.timestamp)
end

function duration_ops.tominutes(self: Duration): number
	return timespecToSeconds(self.timestamp) / SECONDS_PER_MINUTE
end

function duration_ops.tohours(self: Duration): number
	return timespecToSeconds(self.timestamp) / SECONDS_PER_HOUR
end

function duration_ops.todays(self: Duration): number
	return timespecToSeconds(self.timestamp) / SECONDS_PER_DAY
end

function duration_ops.toweeks(self: Duration): number
	return timespecToSeconds(self.timestamp) / SECONDS_PER_WEEK
end

function duration_ops.subsecnanos(self: Duration): number
	return buffer.readu32(self.timestamp, 8)
end

function duration_ops.subsecmicros(self: Duration): number
	return buffer.readu32(self.timestamp, 8) / NANOSECONDS_PER_MICROSECOND
end

function duration_ops.subsecmillis(self: Duration): number
	return buffer.readu32(self.timestamp, 8) / NANOSECONDS_PER_MILLISECOND
end

type Frozen = typeof(table.freeze({}))
export type Duration = setmetatable<Frozen, {
	read __metatable: "The metatable is locked!",
	read __index: typeof(table.freeze(duration_ops)),
	read __add: (Duration, Duration) -> Duration,
	read __sub: (Duration, Duration) -> Duration,
	read __eq: (Duration, Duration) -> boolean,
	read __lt: (Duration, Duration) -> boolean,
	read __le: (Duration, Duration) -> boolean,
}>

export type Instant = setmetatable<Frozen, {
	read __metatable: "The metatable is locked!",
	read __index: typeof(table.freeze(instant)),
	read __sub: (Instant, Instant) -> Duration,
}>

return time