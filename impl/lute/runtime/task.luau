local time = require("./time")

local task = {}

function task.defer()
	zune.task.wait()
end

function task.wait(dur: (number | time.Duration)?)
	return zune.task.wait(dur)
end

function task.spawn<T..., U...>(routine: ((T...) -> U...) | thread, ...: T...)
	return zune.task.spawn(routine, ...)
end

function task.resume(thread: thread)
	if type(thread) ~= "thread" then
		error("argument 1 is not a thread")
	end
	task.spawn(thread)
end

return task