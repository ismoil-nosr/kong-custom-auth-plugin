local http = require "resty.http"
local cjson = require "cjson"

local kong = kong

local plugin_name = "custom-auth"

local MyAuthPluginHandler = {}

MyAuthPluginHandler.PRIORITY = 999
MyAuthPluginHandler.VERSION = "0.1.0"

local function get_headers(header_names, headers)
  local result = {}
  if not header_names then
    return result
  end
  for _, name in ipairs(header_names) do
    local value = headers[name]
    if value then
      result[name] = value
    end
  end
  return result
end

function MyAuthPluginHandler:access(conf)
  -- Create a new HTTP client instance
  local httpc = http.new()

  -- Set the target URL for the authorization service
  local auth_url = conf.validation_endpoint

  -- Get the request headers from the Kong request object
  local request_headers = kong.request.get_headers()

  -- Filter the request headers to only include those specified in the config
  request_headers = get_headers(conf.request_headers, request_headers)

  -- Add any additional headers specified in the config
  if conf.access_token_header and conf.access_token_value then
    request_headers[conf.access_token_header] = conf.access_token_value
  end

  -- Create a new HTTP request to the authorization service
  local res, err = httpc:request_uri(auth_url, {
    method = "POST",
    ssl_verify = conf.ssl_verify,
    headers = request_headers
  })

  -- Check if the request was successful
  if res and res.status == 202 then
    -- Extract the X-Auth-User header from the response

    -- Get the upstream headers from the HTTP response
    local upstream_headers = get_headers(conf.upstream_headers, res.headers)

    -- Set the upstream headers for the response
    kong.service.request.set_headers(upstream_headers)
  else
    kong.log.err("Authorization service request failed: ", err)
  end
end

return MyAuthPluginHandler