local util = require("mooncrafts.util")
local oauth1 = require("mooncrafts.oauth1")
local log = require("mooncrafts.log")
local http_socket = require("mooncrafts.httpsocket")
local http_ngx
if ngx then
  http_ngx = require("mooncrafts.resty.http")
end
local concat
concat = table.concat
local query_string_encode, string_connection_parse
query_string_encode, string_connection_parse = util.query_string_encode, util.string_connection_parse
local string_upper = string.upper
local doRequest
doRequest = function(opts)
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
      err = "url is required"
    }
  end
  local headers = opts["headers"] or {
    ["Accept"] = "*/*"
  }
  headers["User-Agent"] = headers["User-Agent"] or "Mozilla/5.0"
  opts["method"] = string_upper(opts["method"] or 'GET')
  opts["headers"] = headers
  local body = opts["body"]
  if body then
    body = (type(body) == "table") and query_string_encode(body) or body
    opts.body = body
    opts.headers["content-length"] = #body
  end
  if (headers.auth_basic) then
    local basic_auth = encode_base64(headers.auth_basic)
    opts.headers["Authorization"] = "Basic " .. tostring(basic_auth)
    headers["auth_basic"] = nil
  end
  if (headers.auth_oauth1) then
    local auth_oauth1 = string_connection_parse(headers.auth_oauth1)
    opts.headers["Authorization"] = oauth1.create_signature(opts, oauth1)
    headers["auth_oauth1"] = nil
  end
  return doRequest(opts)
end
return {
  request = request
}
