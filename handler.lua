local http = require "resty.http"
local cjson = require "cjson"

local kong = kong

local plugin_name = "custom-auth"

-- Gets the specified headers from the request object and returns them in a table
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

-- Compares two tables of headers and returns true if they match, false otherwise
local function compareHeaders(request_headers, auth_request_headers)
  if not auth_request_headers then
    return false
  end

  for k, v in ipairs(auth_request_headers) do
    if request_headers[k] ~= v then
      return false
    end
  end
  return true
end

-- Sends a request to the authorization service using the provided URL and headers
local function send_auth_request(auth_url, request_headers, conf)
  -- Create a new HTTP client instance
  local httpc = http.new()

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

-- Handles the request by getting the necessary headers, filtering them, and sending them to the auth service
local function handle_request(conf)
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

  -- Log the headers being sent to the authorization service
  -- kong.log.info("Sending headers to authorization service: ", cjson.encode(request_headers))

  -- Check if all necessary headers are present before sending the request
  if compareHeaders(request_headers, conf.auth_request_headers) ~= true then 
    return -- If not all headers are specified in auth_request_headers then we don't make a request to the auth service
  end  

  -- Send the request to the authorization service
  send_auth_request(auth_url, request_headers, conf)
end

-- Handler for the custom authentication plugin
local MyAuthPluginHandler = {
  PRIORITY = 999,
  VERSION = "0.1.0"
}

-- Access phase function called by Kong for each request
function MyAuthPluginHandler:access(conf)
  handle_request(conf)
end

return MyAuthPluginHandler