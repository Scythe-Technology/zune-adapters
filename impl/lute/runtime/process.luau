export type StdioKind = "default" | "inherit" | "none" | ""

export type ProcessRunOptions = {
	shell: (string | boolean)?,
	cwd: string?,
	stdio: StdioKind?,

	env: { [string]: string }?,
}

export type ProcessResult = {
	stdout: string,
	stderr: string,

	ok: boolean,
	exitcode: number,
	signal: string?,
}

local STDIO_MAP = {
	default = "pipe",
	none = "ignore",
	inherit = "inherit",
	[""] = "pipe",
}

local process = {}

process.env = {} :: { [string]: string }

function process.homedir(): string
	return zune.process.env["HOME"] or zune.process.env["USERPROFILE"] or error("no home directory")
end

function process.cwd(): string
	return zune.process.cwd()
end

function process.run(args: string | { string }, options: ProcessRunOptions?): ProcessResult
	local list = if (type(args) == "string") then { args } else table.clone(args)
	local executable = table.remove(list, 1)
	if not executable then
		error("missing command")
	end
	local result = zune.process.run(executable, list, {
		shell = if (options and options.shell) then options.shell else false,
		cwd = if (options and options.cwd) then options.cwd else nil,
		stdio = if (options and options.stdio) then STDIO_MAP[options.stdio] or "pipe" else nil,
		env = if (options and options.env) then options.env else nil,
	})
	return {
		stdout = result.stdout,
		stderr = result.stderr,
		ok = result.ok,
		exitcode = result.code,
	}
end

return process