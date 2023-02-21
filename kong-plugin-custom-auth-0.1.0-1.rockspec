local plugin_name = "custom-auth"
local package_name = "kong-plugin-" .. plugin_name
local package_version = "0.1.0"
local rockspec_revision = "1"
local github_account_name = "ismoil-nosr"
local github_repo_name = "kong-custom-auth-plugin"


package = package_name
version = package_version .. "-" .. rockspec_revision
supported_platforms = { "linux", "macosx" }
source = {
  url = "git://github.com/ismoil-nosr/kong-custom-auth-plugin.git",
  branch = "main",
  tag = "v0.1.0",
}


description = {
  summary = "Custom auth",
  homepage = "https://"..github_account_name..".github.io/"..github_repo_name,
  license = "MIT",
}


dependencies = {
}


build = {
  type = "builtin",
  modules = {
    -- TODO: add any additional code files added to the plugin
    ["kong.plugins."..plugin_name..".handler"] = "kong/plugins/"..plugin_name.."/handler.lua",
    ["kong.plugins."..plugin_name..".schema"] = "kong/plugins/"..plugin_name.."/schema.lua",
  }
}