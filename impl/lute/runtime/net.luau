local net = {}

export type Metadata = {
	method: string?,
	body: string?,
	headers: { [string]: string }?,
}

export type Request = {
	body: string,
	headers: { [string]: string },
	status: number,
	ok: boolean,
}

function net.request(url: string, metadata: Metadata?): Request
	local result = zune.net.http.request(url, {
		method = if (metadata) then metadata.method else "GET",
		body = if (metadata) then metadata.body else nil,
		headers = if (metadata) then metadata.headers else nil,
	})
	return {
		body = result.body,
		headers = result.headers,
		status = result.status_code,
		ok = result.ok,
	}
end

export type ReceivedRequest = {
	method: string,
	path: string,
	body: string,
	query: { [string]: string },
	headers: { [string]: string },
}

export type ServerResponse = string | {
	status: number?,
	body: string?,
	headers: { [string]: string }?,
}

export type Handler = (request: ReceivedRequest) -> ServerResponse

export type Configuration = {
	hostname: string?,
	port: number?,
	reuseport: boolean?,
	tls: { certfilename: string, keyfilename: string, passphrase: string?, cafilename: string? }?,
	handler: Handler,
}

function net.serve(config: Handler | Configuration)
	local config: Configuration = 
		if type(config) == "function" then
			{
				handler = config,
				port = 3000,
			}
		else
			config
	if (config.tls) then
		error("TLS is not implemented")
	end
	zune.net.http.serve({
		port = config.port or 3000,
		address = config.hostname or "0.0.0.0",
		reuse_address = config.reuseport,
		request = function(req)
			local response = config.handler({
				method = req.method,
				path = req.path,
				body = req.body or "",
				query = req.query,
				headers = req.headers,
			})
			if type(response) == "string" then
				return response
			end
			return {
				status_code = response.status or 200,
				headers = response.headers,
				body = response.body,
			}
		end,
	})
end

return net