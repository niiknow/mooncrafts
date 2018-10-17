crypto        = require "crypto"
crypto_hmac   = require "crypto.hmac"
basexx        = require "basexx"

{ :to_base64, :from_base64 } = basexx

local *

base64_encode = ngx and ngx.encode_base64 or to_base64
base64_decode = ngx and ngx.decode_base64 or from_base64
crypto_wrapper = (dtype, str) ->
  {
    digest: () -> crypto.digest(dtype, str, true)
    hex: () -> crypto.digest(dtype, str, false)
  }

hmac_wrapper = (key, str, algo) ->
  {
    digest: () -> crypto_hmac.digest(algo, str, key, true)
    hex: () -> crypto_hmac.digest(algo, str, key, false)
  }

md5 = (str) -> crypto_wrapper("md5", str)
sha1 = (str) -> crypto_wrapper("sha1", str)
sha256 = (str) -> crypto_wrapper("sha256", str)
hmac = (key, str, algo) ->
  return hmac_wrapper(key, str, "md5") if algo == md5
  return hmac_wrapper(key, str, "sha1") if algo == sha1
  return hmac_wrapper(key, str, "sha256") if algo == sha256
  return hmac_wrapper(key, str, algo) if type(algo) == "string"

{ :base64_encode, :base64_decode, :md5, :sha1, :sha256, :hmac }
