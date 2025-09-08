--!strict
local vm = {}

local internal_vm_adapter = [[
local defined = {}

assert(type(mod) == "table", "Module must return a table")

for key, value in mod do
	defined[key] = type(value)
end

zune.thread.send(defined)

while true do
	local input = {zune.thread.receive()}

	local signature = table.remove(input, 1)
	if signature == vector.zero then
		break
	end
	local fn = mod[signature]

	assert(type(fn) == "function", `function '{signature}' not found in module`)

	zune.thread.send(fn(unpack(input)))
end
]];

local function findLuaurc(from: string): string?
	local path = zune.fs.path.dirname(from)
	while path do
		local candidate = zune.fs.path.join(path, ".luaurc")
		local ok, result = pcall(zune.fs.readFile, candidate)
		if ok then
			return result
		end
		path = zune.fs.path.dirname(path)
	end
	return nil
end

local function findLuau(path: string): string?
	for _, ext in {".luau", ".lua", "/init.luau", "/init.lua"} do
		local candidate = path .. ext
		local ok, result = pcall(zune.fs.readFile, candidate)
		if ok then
			return result
		end
	end
	return nil
end

local __watching = false
local __threads = {}
local function watchLoop()
	while #__threads > 0 do
		zune.task.wait(1/60);

		for i = #__threads, 1, -1 do
			local entry = __threads[i]
			if coroutine.status(entry.owner) ~= "dead" then
				continue
			end
			zune.luau.garbagecollect()
			if entry.ref[1] then
				continue
			end
			entry.thread:send(vector.zero)
			entry.thread:join()
			table.remove(__threads, i)
		end
	end
	__watching = false
end
local function watchThread(thread: any, owner: thread, virtual: any)
	local value: any? = virtual
	local ref = setmetatable({value}, {__mode = "v"})
	value = nil

	table.insert(__threads, {
		thread = thread,
		owner = owner,
		ref = ref,
	});

	if __watching then
		return
	end
	__watching = true
	zune.task.spawn(watchLoop)
end

function vm.create(path: string): { [any]: any }
	local location = `./{debug.info(2, "s")}`
	local config = findLuaurc(location)
	local nav = zune.require.navigate(path, location, config)
	local source = findLuau(nav)
	if not source then
		return error(`could not find module '{path}'`)
	end
	local bytecode = zune.luau.compile(`local mod = (function()\n\n{source}\n\nend)()\n{internal_vm_adapter}`, {})
	local thread = zune.thread.fromBytecode(bytecode, {})

	thread:start()

	local defined = thread:receive();
	local virtual = {};
	for key, valueType in defined do
		if valueType == "function" then
			virtual[key] = function(...)
				thread:send(key, ...)
				return thread:receive()
			end
		else
			error(`vm.create: unsupported type for key {key}: {valueType}`)
		end
	end

	watchThread(thread, coroutine.running(), virtual)

	return virtual;
end

return vm