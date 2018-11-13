
util         = require "mooncrafts.util"
oauth1       = require "mooncrafts.oauth1"
log          = require "mooncrafts.log"
http_socket  = require "mooncrafts.httpsocket"
http_ngx     = require "mooncrafts.resty.http" if ngx

import concat from table
import query_string_encode, string_connection_parse from util

string_upper = string.upper
doRequest    = (opts) ->
  -- only use ngx capture if capture_url is provided
  return http_ngx.request(opts) if ngx and opts.capture_url

  http_socket.request(opts)

--{
--  body = <response body>,
--  code = <http status code>,
--  headers = <table of headers>,
--  status = <the http status message>,
--  err = <nil or error message>
-- }
local *

request = (opts) ->

  opts = { url: opts, method: 'GET' } if type(opts) == 'string'

  return { err: "url is required" } unless opts.url

  headers                 = opts["headers"] or {["Accept"]: "*/*"}
  headers["User-Agent"] or= "Mozilla/5.0"

  opts["method"]  = string_upper(opts["method"] or 'GET')
  opts["headers"] = headers

  -- auto add content length
  body = opts["body"]
  if body
    body = (type(body) == "table") and query_string_encode(body) or body
    opts.body = body
    opts.headers["content-length"] = #body

  if (headers.auth_basic)
    basic_auth = encode_base64(headers.auth_basic)
    opts.headers["Authorization"] = "Basic #{basic_auth}"
    headers["auth_basic"] = nil

  if (headers.auth_oauth1)
    auth_oauth1 = string_connection_parse(headers.auth_oauth1)
    opts.headers["Authorization"] = oauth1.create_signature opts, oauth1
    headers["auth_oauth1"] = nil

  doRequest(opts)

{ :request }
