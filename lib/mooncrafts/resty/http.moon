
http_handle = require "resty.http"
util        = require "mooncrafts.util"
log         = require "mooncrafts.log"

starts_with = util.starts_with

local *
request_ngx = (request_uri, opts={}) ->
  capture_url = opts.capture_url or "/__mooncrafts"
  capture_variable = opts.capture_variable  or "target"

  method = opts.method
  new_method = ngx["HTTP_" .. method]

  req_t = {
    args: {[capture_variable]: request_uri},
    method: new_method
  }

  headers = opts.headers or {["Accept"]: "*/*"}

  -- clear all browser headers, remove after extra_headers
  bh = ngx.req.get_headers()
  for k, v in pairs(bh)
    ngx.req.clear_header(k) if k ~= 'content-length'

  -- apply new headers
  for k, v in pairs(headers)
    ngx.req.set_header(k, v) if not starts_with(k, "auth_")

  req_t.body          = opts.body if opts.body
  -- req_t.extra_headers = headers

  -- ngx.say(util.to_json(headers))
  -- ngx.log(ngx.INFO, util.to_json(opts))

  rsp, err = ngx.location.capture(capture_url, req_t)

  -- make sure to clear all remaining
  for k, v in pairs(headers)
    ngx.req.clear_header(k) if k ~= 'content-length'

  --ngx.say(request_uri)
  --ngx.say(util.to_json(rsp))
  return { err: err } if err

  { body: rsp.body, status: "#{rsp.status}", code: rsp.status, headers: rsp.headers, err: err }

-- simulate socket.http
--request {
--  method = string,
--  url = string,
--  headers = header-table,
--  body = string
--}
--response {
--  body = <response body>,
--  code = <http status code>,
--  headers = <table of headers>,
--  status = <the http status message>,
--  err = <nil or error message>
--}
request = (opts) ->
  opts = { url: opts, method: 'GET' } if type(opts) == 'string'

  -- clean args
  options = {
    method: opts.method,
    body: opts.body,
    headers: opts.headers,
    ssl_verify: false,
    capture_url: opts.capture_url,
    capture_variable: opts.capture_variable
  }

  return request_ngx(opts.url, options) if (opts.capture_url)

  rsp, err = http_handle\request_uri(opts.url, options)

  return { err: err } if err

  { body: rsp.body, status: rsp.reason, code: rsp.status, headers: rsp.headers, err: err }

{ :request, :request_ngx }
