local ltn12 = require("ltn12")
local http = require("socket.http")
local https = require("ssl.https")
local stringsource, tablesink, make_request, request
stringsource = ltn12.source.string
tablesink = ltn12.sink.table
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
  opts.source = stringsource(opts.body)
  local result = { }
  opts.sink = tablesink(result)
  local one, code, headers, status = make_request(opts)
  local body = table.concat(result)
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
