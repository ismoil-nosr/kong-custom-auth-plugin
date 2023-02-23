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

local function compareHeaders(kong_request_header, auth_request_headers)
  for k, v in pairs(auth_request_headers) do
    if kong_request_header[k] ~= v then
      return false
    end
  end
  return true
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

  if compareHeaders(kong_request_header, auth_request_headers) ~= true then 
    return -- if not all headers are specified in kong_request_header then it means we dont make request to auth service
  end

  -- Create a new HTTP request to the authorization service
  local res, err = httpc:request_uri(auth_url, {
    method = "POST",
    ssl_verify = conf.ssl_verify,
    headers = request_headers
  })

  -- Check if the request was successful
  if res then
    if res.status >= 200 and res.status < 300 then
      -- Get the upstream headers from the HTTP response
      local upstream_headers = get_headers(conf.upstream_headers, res.headers)

      -- Set the upstream headers for the response
      kong.service.request.set_headers(upstream_headers)
    end
  else
    kong.log.err("Authorization service request failed: ", err)
  end
end

return MyAuthPluginHandler