local util = require("mooncrafts.util")
local crypto = require("mooncrafts.crypto")
local string_slit
string_slit = util.string_slit
local base64_encode, base64_decode
base64_encode, base64_decode = crypto.base64_encode, crypto.base64_decode
local unpack
unpack = table.unpack
local sign, verify, sign_custom, verify_custom
sign = function(key, data, algo)
  if algo == nil then
    algo = crypto.sha256
  end
  return base64_encode(crypto.hmac(key, data, algo).digest())
end
verify = function(key, data, algo)
  if algo == nil then
    algo = crypto.sha256
  end
  return data == sign(key, data, algo)
end
sign_custom = function(key, data, ttl, ts, algo)
  if data == nil then
    data = ""
  end
  if ttl == nil then
    ttl = 600
  end
  if ts == nil then
    ts = os.time()
  end
  if algo == nil then
    algo = crypto.sha256
  end
  return tostring(ts) .. ":" .. tostring(ttl) .. ":" .. tostring(data) .. ":" .. sign(tostring(ts) .. ":" .. tostring(ttl) .. ":" .. tostring(data))
end
verify_custom = function(key, payload, algo)
  if algo == nil then
    algo = crypto.sha256
  end
  local ts, ttl, data = unpack(string_split(payload, ":"))
  if (ts < (os.time() - tonumber(str[2]))) then
    return {
      valid = false,
      timeout = true
    }
  end
  return {
    valid = (sign(key, data, ttl, ts) == payload)
  }
end
return {
  sign = sign,
  verify = verify
}
