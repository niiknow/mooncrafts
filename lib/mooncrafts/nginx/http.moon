
http_handle       = require "resty.http"
util              = require "mooncrafts.util"
log               = require "mooncrafts.log"

local *
request_ngx = (request_uri, opts={}) ->
  capture_url = opts.capture_url or "/__capture"
  capture_variable = opts.capture_variable  or "target"

  method = opts.method
  new_method = ngx["HTTP_" .. method]

  req_t = {
    args: {[capture_variable]: request_uri},
    method: new_method
  }

  -- clear all browser headers
  bh = ngx.req.get_headers()
  for k, v in pairs(bh)
    if k ~= 'content-length' then ngx.req.clear_header(k)

  h = opts.headers or {["Accept"]: "*/*"}

  for k, v in pairs(h) do ngx.req.set_header(k, v)
  req_t.body = opts.body if opts.body

  -- ngx.log(ngx.INFO, util.to_json(opts))

  rsp, err = ngx.location.capture(capture_url, req_t)

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
