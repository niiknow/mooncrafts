
ltn12        = require "ltn12"
http         = require "socket.http"
https        = require "ssl.https"

local *

string_source = ltn12.source.string
table_sink    = ltn12.sink.table
table_concat  = table.concat

make_request  = (opts) ->
  return https.request(opts) if opts.url\find "https:"

  http.request(opts)

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
  opts        = { url: opts, method: 'GET' } if type(opts) == 'string'
  opts.source = string_source(opts.body)
  result      = {}
  opts.sink   = table_sink(result)

  one, code, headers, status = make_request opts

  body    = table_concat(result)
  message = #body > 0 and body or "unknown error"

  return {:code, :headers, :status, err: message} unless one

  { :code, :headers, :status, :body }

{ :request }
