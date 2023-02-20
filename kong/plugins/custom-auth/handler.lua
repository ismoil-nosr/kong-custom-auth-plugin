local http = require "resty.http"

local kong = kong
local ngx = ngx
local pairs = pairs
local type = type

local plugin_name = "custom-auth"

local MyAuthPluginHandler = {}

MyAuthPluginHandler.PRIORITY = 999
MyAuthPluginHandler.VERSION = "1.0.0"

function MyAuthPluginHandler:access(conf)
  -- Create a new HTTP client instance
  local httpc = http.new()

  -- Set the target URL for the authorization service
  local auth_url = "http://service-auth.alif.loc/api/gate/authorize"

  -- Extract the Authorization header from the incoming request
  local auth_header = kong.request.get_header("Authorization")

  -- Make sure the header is not empty
  if auth_header then
    -- Create a new HTTP POST request to the authorization service
    local res, err = httpc:request_uri(auth_url, {
      method = "POST",
      headers = {
        ["Authorization"] = auth_header
      }
    })

    -- Check if the request was successful
    if res and res.status == 200 then
      -- Extract the X-Auth-User header from the response
      local x_auth_user = res.headers["X-Auth-User"]

      -- Make sure the header is not empty
      if x_auth_user then
        -- Set the X-Auth-User header for the upstream service
        kong.service.request.set_header("X-Auth-User", x_auth_user)
      end
    else
      kong.log.err("Authorization service request failed: ", err)
    end
  else
    kong.log.err("Authorization header not found in request")
  end
end

return MyAuthPluginHandler