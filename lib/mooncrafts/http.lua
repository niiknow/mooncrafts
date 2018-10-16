local util = require("mooncrafts.util")
local oauth1 = require("mooncrafts.oauth1")
local log = require("mooncrafts.log")
local string_upper = string.upper
local http_socket = require("mooncrafts.httpsocket")
local http_ngx
if ngx then
  http_ngx = require("mooncrafts.nginx.http")
end
local concat
concat = table.concat
local query_string_encode
query_string_encode = util.query_string_encode
string_upper = string.upper
local dorequest
dorequest = function(opts)
  if ngx and not opts.useSocket then
    return http_ngx.request(opts)
  end
  return http_socket.request(opts)
end
local request
request = function(opts)
  if type(opts) == 'string' then
    opts = {
      url = opts,
      method = 'GET'
    }
  end
  if not (opts.url) then
    return {
      code = 0,
      err = "url is required"
    }
  end
  opts["method"] = string_upper(opts["method"] or 'GET')
  opts["headers"] = opts["headers"] or {
    ["Accept"] = "*/*"
  }
  opts["headers"]["User-Agent"] = opts["headers"]["User-Agent"] or "Mozilla/5.0"
  local body = opts["body"]
  if body then
    body = (type(body) == "table") and query_string_encode(body) or body
    opts.body = body
    opts.headers["content-length"] = #body
  end
  if opts["auth"] then
    opts.headers["Authorization"] = "Basic " .. tostring(encode_base64(concat(opts.auth, ':')))
  end
  if opts["oauth"] then
    opts.headers["Authorization"] = oauth1.create_signature(opts, opts["oauth"])
  end
  return dorequest(opts)
end
return {
  request = request
}
