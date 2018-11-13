local crypto_hmac = require("openssl.hmac")
local crypto_digest = require("openssl.digest")
local basexx = require("basexx")
local to_base64, from_base64
to_base64, from_base64 = basexx.to_base64, basexx.from_base64
local string_format, string_byte, base64_encode, base64_decode, to_hex, crypto_wrapper, hmac_wrapper, md5, sha1, sha256, hmac
string_format = string.format
string_byte = string.byte
base64_encode = ngx and ngx.encode_base64 or to_base64
base64_decode = ngx and ngx.decode_base64 or from_base64
to_hex = function(str)
  return (str:gsub(".", function(c)
    return string_format("%02x", string_byte(c))
  end))
end
crypto_wrapper = function(algo, str)
  return {
    digest = function()
      return (crypto_digest.new(algo)):final(str)
    end,
    hex = function()
      return to_hex((crypto_digest.new(algo)):final(str))
    end
  }
end
hmac_wrapper = function(key, str, algo)
  return {
    digest = function()
      return (crypto_hmac.new(key, algo)):final(str)
    end,
    hex = function()
      return to_hex((crypto_hmac.new(key, algo)):final(str))
    end
  }
end
md5 = function(str)
  return crypto_wrapper("md5", str)
end
sha1 = function(str)
  return crypto_wrapper("sha1", str)
end
sha256 = function(str)
  return crypto_wrapper("sha256", str)
end
hmac = function(key, str, algo)
  if algo == md5 then
    return hmac_wrapper(key, str, "md5")
  end
  if algo == sha1 then
    return hmac_wrapper(key, str, "sha1")
  end
  if algo == sha256 then
    return hmac_wrapper(key, str, "sha256")
  end
  if type(algo) == "string" then
    return hmac_wrapper(key, str, algo)
  end
end
return {
  base64_encode = base64_encode,
  base64_decode = base64_decode,
  md5 = md5,
  sha1 = sha1,
  sha256 = sha256,
  hmac = hmac
}
