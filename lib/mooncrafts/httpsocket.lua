local ltn12 = require("ltn12")
local http = require("socket.http")
local https = require("ssl.https")
local string_source, table_sink, table_concat, make_request, request
string_source = ltn12.source.string
table_sink = ltn12.sink.table
table_concat = table.concat
make_request = function(opts)
  if opts.url:find("https:") then
    return https.request(opts)
  end
  return http.request(opts)
end
request = function(opts)
  if type(opts) == 'string' then
    opts = {
      url = opts,
      method = 'GET'
    }
  end
  opts.source = string_source(opts.body)
  local result = { }
  opts.sink = table_sink(result)
  local one, code, headers, status = make_request(opts)
  local body = table_concat(result)
  local message = #body > 0 and body or "unknown error"
  if not (one) then
    return {
      code = code,
      headers = headers,
      status = status,
      err = message
    }
  end
  return {
    code = code,
    headers = headers,
    status = status,
    body = body
  }
end
return {
  request = request
}
