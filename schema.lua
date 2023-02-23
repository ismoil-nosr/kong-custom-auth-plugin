local typedefs = require "kong.db.schema.typedefs"

return {
    name = "custom-auth",
    fields = {
		{ protocols = typedefs.protocols_http },
		{ 
			config = {
				type = "record",
				fields = {
					{ validation_endpoint = typedefs.url({ required = true }) },
					{ request_method = { type = "string", default = "POST", required = true } },
					{ ssl_verify = { type = "boolean", default = true, required = false } },
					{ access_token_header = { type = "string", required = false }, },
					{ access_token_value = { type = "string", required = false }, },
					{ request_headers = { type = "array", elements = { type = "string" }, required = false }, },
					{ upstream_headers = { type = "array", elements = { type = "string" }, required = false }, },
				}
			}
		}
	}
}
