--!nocheck

local DateTime = require("@lune/datetime")
type DateTime = DateTime.DateTime

export type MetadataKind = "file" | "dir" | "symlink"
local METADATA_KIND_MAP = {
	file = "file",
	directory = "dir",
	sym_link = "symlink",
}

--[=[
	@interface MetadataPermissions
	@within FS

	Permissions for the given file or directory.

	This is a dictionary that will contain the following values:

	* `readOnly` - If the target path is read-only or not
]=]
export type MetadataPermissions = {
	readOnly: boolean,
}

-- FIXME: We lose doc comments here below in Metadata because of the union type

--[=[
	@interface Metadata
	@within FS

	Metadata for the given file or directory.

	This is a dictionary that will contain the following values:

	* `kind` - If the target path is a `file`, `dir` or `symlink`
	* `exists` - If the target path exists
	* `createdAt` - The timestamp represented as a `DateTime` object at which the file or directory was created
	* `modifiedAt` - The timestamp represented as a `DateTime` object at which the file or directory was last modified
	* `accessedAt` - The timestamp represented as a `DateTime` object at which the file or directory was last accessed
	* `permissions` - Current permissions for the file or directory

	Note that timestamps are relative to the unix epoch, and
	may not be accurate if the system clock is not accurate.
]=]
export type Metadata = {
	kind: MetadataKind,
	exists: true,
	createdAt: DateTime,
	modifiedAt: DateTime,
	accessedAt: DateTime,
	permissions: MetadataPermissions,
} | {
	kind: nil,
	exists: false,
	createdAt: nil,
	modifiedAt: nil,
	accessedAt: nil,
	permissions: nil,
}

--[=[
	@interface WriteOptions
	@within FS

	Options for filesystem APIs what write to files and/or directories.

	This is a dictionary that may contain one or more of the following values:

	* `overwrite` - If the target path should be overwritten or not, in the case that it already exists
]=]
export type WriteOptions = {
	overwrite: boolean?,
}

--[=[
	@class FS

	Built-in library for filesystem access

	### Example usage

	```lua
	local fs = require("@lune/fs")

	-- Reading a file
	local myTextFile: string = fs.readFile("myFileName.txt")

	-- Reading entries (files & dirs) in a directory
	for _, entryName in fs.readDir("myDirName") do
		if fs.isFile("myDirName/" .. entryName) then
			print("Found file " .. entryName)
		elseif fs.isDir("myDirName/" .. entryName) then
			print("Found subdirectory " .. entryName)
		end
	end
	```
]=]
local fs = {}

--[=[
	@within FS
	@tag must_use

	Reads a file at `path`.

	An error will be thrown in the following situations:

	* `path` does not point to an existing file.
	* The current process lacks permissions to read the file.
	* Some other I/O error occurred.

	@param path The path to the file to read
	@return The contents of the file
]=]
function fs.readFile(path: string): string
	local ok, result = pcall(zune.fs.readFile, path)
	if not ok then
		if result == "FileNotFound" then
			error("No such file or directory (os error 2)", 0)
		end
		error(result)
	end
	return result
end

--[=[
	@within FS
	@tag must_use

	Reads entries in a directory at `path`.

	An error will be thrown in the following situations:

	* `path` does not point to an existing directory.
	* The current process lacks permissions to read the contents of the directory.
	* Some other I/O error occurred.

	@param path The directory path to search in
	@return A list of files & directories found
]=]
function fs.readDir(path: string): { string }
	local ok, result = pcall(zune.fs.entries, path)
	if not ok then
		if result == "FileNotFound" then
			error("No such file or directory (os error 2)", 0)
		end
		error(result)
	end
	local copy = table.create(#result)
	for i, entry in result do
		copy[i] = entry.name
	end
	return copy
end

--[=[
	@within FS

	Writes to a file at `path`.

	An error will be thrown in the following situations:

	* The file's parent directory does not exist.
	* The current process lacks permissions to write to the file.
	* Some other I/O error occurred.

	@param path The path of the file
	@param contents The contents of the file
]=]
function fs.writeFile(path: string, contents: buffer | string)
	zune.fs.writeFile(path, contents)
end

--[=[
	@within FS

	Creates a directory and its parent directories if they are missing.

	An error will be thrown in the following situations:

	* `path` already points to an existing file or directory.
	* The current process lacks permissions to create the directory or its missing parents.
	* Some other I/O error occurred.

	@param path The directory to create
]=]
function fs.writeDir(path: string)
	zune.fs.makeDir(path, true)
end

--[=[
	@within FS

	Removes a file.

	An error will be thrown in the following situations:

	* `path` does not point to an existing file.
	* The current process lacks permissions to remove the file.
	* Some other I/O error occurred.

	@param path The file to remove
]=]
function fs.removeFile(path: string)
	local ok, err = pcall(zune.fs.deleteFile, path)
	if not ok then
		if err == "FileNotFound" then
			error("No such file or directory (os error 2)", 0)
		end
		error(err)
	end
end

--[=[
	@within FS

	Removes a directory and all of its contents.

	An error will be thrown in the following situations:

	* `path` is not an existing and empty directory.
	* The current process lacks permissions to remove the directory.
	* Some other I/O error occurred.

	@param path The directory to remove
]=]
function fs.removeDir(path: string)
	local ok, err = pcall(zune.fs.deleteDir, path, true)
	if not ok then
		if err == "FileNotFound" then
			error("No such file or directory (os error 2)", 0)
		end
		error(err)
	end
end

--[=[
	@within FS
	@tag must_use

	Gets metadata for the given path.

	An error will be thrown in the following situations:

	* The current process lacks permissions to read at `path`.
	* Some other I/O error occurred.

	@param path The path to get metadata for
	@return Metadata for the path
]=]
function fs.metadata(path: string): Metadata
	local ok, meta = pcall(zune.fs.metadata, path)
	if not ok then
		return {
			exists = false,
		}
	end
	local mapped = METADATA_KIND_MAP[meta.kind]
	if not mapped then
		return {
			exists = false,
		}
	end
	return {
		kind = mapped,
		exists = true,
		createdAt = DateTime.fromUnixTimestamp(meta.created_at),
		modifiedAt = DateTime.fromUnixTimestamp(meta.modified_at),
		accessedAt = DateTime.fromUnixTimestamp(meta.accessed_at),
		permissions = {
			readOnly = meta.permissions.read_only,
		},
	}
end

--[=[
	@within FS
	@tag must_use

	Checks if a given path is a file.

	An error will be thrown in the following situations:

	* The current process lacks permissions to read at `path`.
	* Some other I/O error occurred.

	@param path The file path to check
	@return If the path is a file or not
]=]
function fs.isFile(path: string): boolean
	return zune.fs.stat(path).kind == "file"
end

--[=[
	@within FS
	@tag must_use

	Checks if a given path is a directory.

	An error will be thrown in the following situations:

	* The current process lacks permissions to read at `path`.
	* Some other I/O error occurred.

	@param path The directory path to check
	@return If the path is a directory or not
]=]
function fs.isDir(path: string): boolean
	return zune.fs.stat(path).kind == "directory"
end

--[=[
	@within FS

	Moves a file or directory to a new path.

	Throws an error if a file or directory already exists at the target path.
	This can be bypassed by passing `true` as the third argument, or a dictionary of options.
	Refer to the documentation for `WriteOptions` for specific option keys and their values.

	An error will be thrown in the following situations:

	* The current process lacks permissions to read at `from` or write at `to`.
	* The new path exists on a different mount point.
	* Some other I/O error occurred.

	@param from The path to move from
	@param to The path to move to
	@param overwriteOrOptions Options for the target path, such as if should be overwritten if it already exists
]=]
function fs.move(from: string, to: string, overwriteOrOptions: (boolean | WriteOptions)?)
	zune.fs.move(
		from, to,
		if (type(overwriteOrOptions) == "boolean") then
			overwriteOrOptions
		else
			if (overwriteOrOptions and overwriteOrOptions.overwrite) then
				true
			else
				false
	)
end

--[=[
	@within FS

	Copies a file or directory recursively to a new path.

	Throws an error if a file or directory already exists at the target path.
	This can be bypassed by passing `true` as the third argument, or a dictionary of options.
	Refer to the documentation for `WriteOptions` for specific option keys and their values.

	An error will be thrown in the following situations:

	* The current process lacks permissions to read at `from` or write at `to`.
	* Some other I/O error occurred.

	@param from The path to copy from
	@param to The path to copy to
	@param overwriteOrOptions Options for the target path, such as if should be overwritten if it already exists
]=]
function fs.copy(from: string, to: string, overwriteOrOptions: (boolean | WriteOptions)?)
	zune.fs.copy(
		from, to,
		if (type(overwriteOrOptions) == "boolean") then
			overwriteOrOptions
		else
			if (overwriteOrOptions and overwriteOrOptions.overwrite) then
				true
			else
				false
	)
end

return fs