# kong-custom-auth-plugin
Kong custom authorization plugin that forwards requests to your own authorization service with header.

# Installation steps
### 1. Install plugin

Mount plugin to your docker container or place plugin contents in `/usr/local/share/lua/5.1/kong/plugins/custom-auth`

Docker example:
```Dockerfile
FROM kong/kong-gateway:3.1.1.3-alpine
USER root

COPY ./ /usr/local/share/lua/5.1/kong/plugins/custom-auth

RUN kong prepare

USER kong
```

### 2. Enable plugin
```
KONG_PLUGINS: "bundled,custom-auth" 
KONG_LUA_PATH: "/usr/local/share/lua/5.1/kong/?.lua;;" 
KONG_PLUGIN_PATH: "/usr/local/share/lua/5.1/kong/plugins?.lua;;"
```

### 3. Register plugin 
After you enabled plugin need to be registered in kong plugins database. After that it will start to operate. 
Otherwise it won't.

HTTP request:
```bash 
curl --location 'http://kong-api-domain:8001/plugins/' \
--header 'Accept: application/json' \
--header 'Content-Type: application/json' \
--data '{
    "name": "custom-auth",
    "config": {
        "validation_endpoint": "http://your-auth-service.com/add/your/path",
    }
}'
```

**Attention: be sure to edit `validation_endpoint`**  

---

# Documentation

| Name                | Type          | Required | Default | Description                                                                                                                                            |
| ------------------- | ------------- | -------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| validation_endpoint | string        | True     |         | URI of the authorization service.                                                                                                                      |
| ssl_verify          | boolean       | False    | True    | When set to true, verifies the SSL certificate.                                                                                                        |
| request_method      | string        | False    | POST    | HTTP method for a client to send requests to the authorization service. When set to POST the request body is send to the authorization service.        |
| access_token_header | string        | False    |         | Specify header If authorization service requires token to access it access                                                                             |
| access_token_value  | string        | False    |         | Value for access_token_header                                                                                                                          |
| request_headers     | array[string] | False    |         | Client request headers to be sent to the authorization service. If not set, only the headers provided by Kong are sent (for example, X-Forwarded-XXX). |
| upstream_headers    | array[string] | False    |         | Authorization service response headers to be forwarded to the Upstream service. If not set, no headers are forwarded to the Upstream service.          |
