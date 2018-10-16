-- hmac auth

util = require "mooncrafts.util"
crypto = require "mooncrafts.crypto"

import string_slit from util
import base64_encode, base64_decode from crypto
import unpack from table

local *
sign = (key, data, algo=crypto.sha256) -> base64_encode(crypto.hmac(key, data, algo).digest())
verify = (key, data, algo=crypto.sha256) -> data == sign(key, data, algo)
sign_custom = (key, data="", ttl=600, ts=os.time(), algo=crypto.sha256) -> "#{ts}:#{ttl}:#{data}:" .. sign("#{ts}:#{ttl}:#{data}")

-- reverse the logic above to hmac verify
verify_custom = (key, payload, algo=crypto.sha256) ->
  ts, ttl, data = unpack string_split(payload, ":")

  -- validate expiration
  return { valid: false, timeout: true } if (ts < (os.time() - tonumber(str[2])))

  -- validate
  { valid: (sign(key, data, ttl, ts) == payload) }

{ :sign, :verify }
