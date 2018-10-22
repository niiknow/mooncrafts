local crypto = require("crypto")
local crypto_hmac = require("crypto.hmac")
local basexx = require("basexx")
local to_base64, from_base64
to_base64, from_base64 = basexx.to_base64, basexx.from_base64
local base64_encode, base64_decode, crypto_wrapper, hmac_wrapper, md5, sha1, sha256, hmac
base64_encode = ngx and ngx.encode_base64 or to_base64
base64_decode = ngx and ngx.decode_base64 or from_base64
crypto_wrapper = function(dtype, str)
  return {
    digest = function()
      return crypto.digest(dtype, str, true)
    end,
    hex = function()
      return crypto.digest(dtype, str, false)
    end
  }
end
hmac_wrapper = function(key, str, algo)
  return {
    digest = function()
      return crypto_hmac.digest(algo, str, key, true)
    end,
    hex = function()
      return crypto_hmac.digest(algo, str, key, false)
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
