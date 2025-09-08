local fs = {}

export type FileHandle = any;

export type FileType = "file" | "dir" | "link" | "fifo" | "socket" | "char" | "block" | "unknown"
local TYPE_MAP = {
	file = "file",
	directory = "dir",
	sym_link = "link",
	named_pipe = "fifo",
	socket = "socket",
	character_device = "char",
	block_device = "block",
	unknown = "unknown",
}
export type HandleMode = "r" | "w" | "x" | "a" | "r+" | "w+" | "x+" | "a+"

export type FileMetadata = {
	type: FileType,
	permissions: { readonly: boolean },
	size: number,
	created_at: any,
	accessed_at: any,
	modified_at: any,
}

export type DirectoryEntry = {
	name: string,
	type: FileType,
}

export type WatchHandle = {
	close: (self: WatchHandle) -> (),
}

export type WatchEvent = {
	change: boolean,
	rename: boolean,
}

function fs.open(path: string, mode: HandleMode): FileHandle
	local truncate = mode == "w" or mode == "w+"
	local read = mode == "r" or mode == "w+" or mode == "r+" or mode == "x+" or mode == "a+"
	local write = mode == "w" or mode == "w+" or mode == "r+" or mode == "x+" or mode == "a+"
	local exclusive = mode == "x" or mode == "x+"
	local append = mode == "a" or mode == "a+"
	if not truncate and not read and not write and not exclusive and not append then
		error(`invalid file mode '{mode}'`, 2)
	end
	assert(truncate ~= append, "cannot open file in both truncate and append mode")
	if (truncate or exclusive) then
		return zune.fs.createFile(path, {
			exclusive = exclusive,
			truncate = truncate,
			read = read,
		})
	else
		local f_mode = if (read and write) then "rw" else if (read) then "r" else "w"
		return zune.fs.openFile(path, {
			mode = f_mode
		})
	end
end

function fs.read(handle: FileHandle): string
	return handle:read()
end

function fs.write(handle: FileHandle, contents: string): ()
	handle:write(contents)
end

function fs.close(handle: FileHandle): ()
	handle:close()
end

function fs.remove(path: string): ()
	zune.fs.deleteFile(path)
end

function fs.stat(path: string): FileMetadata
	local meta = zune.fs.metadata(path)
	return {
		type = TYPE_MAP[meta.kind] or "unknown",
		permissions = {
			readonly = meta.permissions.read_only,
		},
		size = meta.size,
		created_at = meta.created_at,
		accessed_at = meta.accessed_at,
		modified_at = meta.modified_at,
	}
end

function fs.type(path: string): FileType
	local stat = zune.fs.stat(path)
	if stat.kind == "none" then
		return error(`path '{path}' does not exist`)
	end
	return TYPE_MAP[stat.kind] or "unknown"
end

function fs.mkdir(path: string): ()
	zune.fs.makeDir(path)
end

function fs.link(src: string, dest: string): ()
	zune.fs.symlink(src, dest)
end

function fs.symlink(src: string, dest: string): ()
	zune.fs.symlink(src, dest)
end

function fs.watch(path: string, callback: (filename: string, event: WatchEvent) -> ()): WatchHandle
	local handle = zune.fs.watch(path, function(sub_path: string, events)
		local change = table.find(events, "metadata")
			or table.find(events, "modified")
		local rename = table.find(events, "renamed")
			or table.find(events, "moved")
		if not change and not rename then
			return
		end
		local event: WatchEvent = {
			change = events.change,
			rename = events.rename,
		}
		callback(sub_path, event)
	end)
	return {
		close = function(self: WatchHandle)
			handle:close()
		end,
	}
end

function fs.exists(path: string): boolean
	return zune.fs.stat(path).kind ~= "none"
end

function fs.copy(src: string, dest: string): ()
	zune.fs.copy(src, dest)
end

function fs.listdir(path: string): { DirectoryEntry }
	local entries = zune.fs.entries(path)
	local copy = table.create(#entries)
	for i, entry in entries do
		copy[i] = {
			name = entry.name,
			type = TYPE_MAP[entry.kind] or "unknown",
		}
	end
	return copy
end

function fs.rmdir(path: string): ()
	zune.fs.deleteDir(path)
end

function fs.readfiletostring(filepath: string): string
	return zune.fs.readFileSync(filepath)
end

function fs.writestringtofile(filepath: string, contents: string): ()
	zune.fs.writeFileSync(filepath, contents)
end

function fs.readasync(filepath: string): string
	return zune.fs.readFile(filepath)
end

return fs