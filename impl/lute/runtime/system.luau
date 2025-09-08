export type CpuInfo = {
	model: string,
	speed: number,

	times: {
		sys: number,
		idle: number,
		irq: number,
		nice: number,
		user: number,
	},
}

local system = {}

function system.threadcount(): number
	return zune.thread.getCpuCount()
end

function system.hostname(): string
	return zune.platform.getHostName()
end

function system.totalmemory(): number
	return zune.platform.getTotalMemory()
end

function system.freememory(): number
	return zune.platform.getFreeMemory()
end

function system.uptime(): number
	local spec = zune.time.instant.now()
	local seconds = buffer.readf64(spec, 0)
	local nanos = buffer.readu32(spec, 8)
	return seconds + (nanos / 1_000_000_000)
end

function system.cpus(): { CpuInfo }
	error("not implemented")
end

system.os = zune.platform.os :: string
system.arch = zune.platform.cpu.arch :: string

return system