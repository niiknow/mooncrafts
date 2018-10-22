local log = require("mooncrafts.log")
local util = require("mooncrafts.util")
local crypto = require("mooncrafts.crypto")
local url = require("mooncrafts.url")
local string_split, url_escape, query_string_encode, table_sort_keys, url_build
string_split, url_escape, query_string_encode, table_sort_keys, url_build = util.string_split, util.url_escape, util.query_string_encode, util.table_sort_keys, util.url_build
local sort, concat
do
  local _obj_0 = table
  sort, concat = _obj_0.sort, _obj_0.concat
end
local url_parse = url.parse
local url_default_port = url.default_port
local escape_uri = url_escape
local unescape_uri = ngx and ngx.unescape_uri or util.url_unescape
local encode_base64 = ngx and ngx.encode_base64 or crypto.base64_encode
local digest_hmac_sha1 = ngx and ngx.hmac_sha1 or function(key, str)
  return crypto.hmac(key, str, crypto.sha1).digest()
end
local digest_md5 = ngx and ngx.md5 or function(str)
  return crypto.md5(str).hex()
end
local normalizeParameters
normalizeParameters = function(parameters, body, query)
  local items = {
    query_string_encode(parameters, "&")
  }
  if body then
    string_split(body, "&", items)
  end
  if query then
    string_split(query, "&", items)
  end
  sort(items)
  return concat(items, "&")
end
local calculateBaseString
calculateBaseString = function(body, method, query, base_uri, parameters)
  return escape_uri(method) .. "&" .. escape_uri(base_uri) .. "&" .. escape_uri(normalizeParameters(parameters, body, query))
end
local secret
secret = function(oauth)
  return unescape_uri(oauth["consumersecret"]) .. "&" .. unescape_uri(oauth["tokensecret"] or "")
end
local sign
sign = function(body, method, query, base_uri, oauth, parameters)
  oauth.stringToSign = calculateBaseString(body, method, query, base_uri, parameters)
  return encode_base64(digest_hmac_sha1(secret(oauth), oauth.stringToSign))
end
local create_signature
create_signature = function(opts, oauth)
  local parts = url_parse(opts.url)
  if (url_default_port(parts.scheme) == parts.port) then
    parts.port = nil
  end
  local base_uri = url_build(parts, false)
  local timestamp = oauth['timestamp'] or os.time()
  local parameters = {
    oauth_consumer_key = oauth["consumerkey"],
    oauth_signature_method = "HMAC-SHA1",
    oauth_timestamp = timestamp,
    oauth_nonce = digest_md5(timestamp .. ""),
    oauth_version = oauth["version"] or "1.0"
  }
  if oauth["accesstoken"] then
    parameters["oauth_token"] = oauth["accesstoken"]
  end
  if oauth["callback"] then
    parameters["oauth_callback"] = unescape_uri(oauth["callback"])
  end
  parameters["oauth_signature"] = sign(opts["body"], opts["method"] or 'GET', parts.query, base_uri, oauth, parameters)
  return "OAuth " .. query_string_encode(parameters, ",", "\"")
end
return {
  create_signature = create_signature
}
