local crypto = {}

export type Hash<T> = { __hash: T }

crypto.hash = {
	md5 = {} :: Hash<"md5">,
	sha1 = {} :: Hash<"sha1">,
	sha256 = {} :: Hash<"sha256">,
	sha512 = {} :: Hash<"sha512">,
	blake2b256 = {} :: Hash<"blake2b256">,
}
crypto.password = {}

function crypto.digest(hash: Hash<any>, message: string | buffer): buffer
	local h = zune.crypto.createHash(hash.__hash)
	h:update(message)
	return h:digest("binary")
end

function crypto.password.hash(password: string): buffer
	return buffer.fromstring(zune.crypto.password.hash(password, {
		algorithm = "argon2id",
		memory_cost = 1048576,
		time_cost = 4,
		threads = 1,
	}))
end

function crypto.password.verify(hash: buffer, password: string): boolean
	return zune.crypto.password.verify(password, hash)
end

return crypto