local http_handle = require("resty.http")
local util = require("mooncrafts.util")
local log = require("mooncrafts.log")
local request_ngx, request
request_ngx = function(request_uri, opts)
  if opts == nil then
    opts = { }
  end
  local capture_url = opts.capture_url or "/__capture"
  local capture_variable = opts.capture_variable or "target"
  local method = opts.method
  local new_method = ngx["HTTP_" .. method]
  local req_t = {
    args = {
      [capture_variable] = request_uri
    },
    method = new_method
  }
  local bh = ngx.req.get_headers()
  for k, v in pairs(bh) do
    ngx.req.clear_header(k)
  end
  local h = opts.headers or {
    ["Accept"] = "*/*"
  }
  for k, v in pairs(h) do
    ngx.req.set_header(k, v)
  end
  if opts.body then
    req_t.body = opts.body
  end
  local rsp, err = ngx.location.capture(capture_url, req_t)
  if err then
    return {
      code = 0,
      err = err
    }
  end
  return {
    body = rsp.body,
    status = tostring(rsp.status),
    code = rsp.status,
    headers = rsp.headers,
    err = err
  }
end
request = function(opts)
  if type(opts) == 'string' then
    opts = {
      url = opts,
      method = 'GET'
    }
  end
  local options = {
    method = opts.method,
    body = opts.body,
    headers = opts.headers,
    ssl_verify = false,
    capture_url = opts.capture_url,
    capture_variable = opts.capture_variable
  }
  if (opts.capture_url) then
    return request_ngx(opts.url, options)
  end
  local rsp, err = http_handle:request_uri(opts.url, options)
  if err then
    return {
      code = 0,
      err = err
    }
  end
  return {
    body = rsp.body,
    status = rsp.reason,
    code = rsp.status,
    headers = rsp.headers,
    err = err
  }
end
return {
  request = request,
  request_ngx = request_ngx
}
