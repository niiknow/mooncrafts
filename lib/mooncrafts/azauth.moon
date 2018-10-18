hmacauth  = require "mooncrafts.hmacauth"
crypto    = require "mooncrafts.crypto"
util      = require "mooncrafts.util"
log       = require "mooncrafts.log"
url       = require "mooncrafts.url"
url_parse = url.parse

import string_split, query_string_encode from util
import concat, sort from table
import base64_decode, base64_encode from crypto

local *

date_utc = (date=os.time()) -> os.date("!%a, %d %b %Y %H:%M:%S GMT", date)

getHeader = (headers, name, additionalHeaders={}) -> headers[name] or additionalHeaders[name] or ""

sharedkeylite = (opts={ :account_name, :account_key, :table_name }) ->
  opts.time = opts.time or os.time()
  opts.date = opts.date or date_utc(opts.time)
  opts.sig  = hmacauth.sign(base64_decode(opts.account_key), "#{opts.date}\n/#{opts.account_name}/#{opts.table_name}")
  opts

canonicalizedResource = (opts) ->
  parsedUrl = opts.parsedUrl
  query     = string_split(opts.query, "&")
  qs        = query_string_encode(query, "\n", "", (v) -> v)
  params    = {
    "/#{opts.account_name}#{parsedUrl.path}",
    qs
  }

  concat(params, "\n")

canonicalizedHeaders = (headers) ->
  rst  = {}
  keys = {}

  -- sort
  for k in pairs(headers) do keys[#keys+1] = tostring(k)
  sort(keys)

  for i=1, #keys
    k = keys[i]
    v = headers[k]
    if (k\find("x-ms-") == 1) then rst[#rst + 1] = "#{k}:#{v}"

  concat(rst, "\n")


stringForTable = (opts, additionalHeaders) ->
  additionalHeaders["DataServiceVersion"] = "3.0;NetFx"
  additionalHeaders["MaxDataServiceVersion"] = "3.0;NetFx"

  params = {
    opts.method,
    getHeader(opts.headers, "content-md5"),
    getHeader(opts.headers, "content-type"),
    getHeader(opts.headers, "x-ms-date", additionalHeaders),
    getHeader(opts.headers, "content-md5"),
    getHeader(opts.headers, "content-type"),
    getHeader(opts.headers, "x-ms-date", additionalHeaders),
    canonicalizedResource(parsedUrl)
  }

  concat(params, "\n")


stringForBlobOrQueue = (req, additionalHeaders) ->
  headers = {}
  table_extend(headers, opts.headers)
  table_extend(headers, additionalHeaders)

  params = {
    req.method,
    getHeader(headers, "content-encoding"),
    getHeader(headers, "content-language"),
    getHeader(headers, "content-length"),
    getHeader(headers, "content-md5"),
    getHeader(headers, "content-type"),
    getHeader(headers, "date"),
    getHeader(headers, "if-modified-since"),
    getHeader(headers, "if-match"),
    getHeader(headers, "if-none-match"),
    getHeader(headers, "if-unmodified-since"),
    getHeader(headers, "range"),
    canonicalizedHeaders(headers),
    canonicalizedResource(opts)
  }

  concat(params, "\n")

sharedkey = (opts, stringGenerator=stringForTable) ->
  opts.time      = opts.time or os.time()
  opts.date      = opts.date or date_utc(opts.time)
  opts.parsedUrl = url_parse(opts.url)

  additionalHeaders                 = {}
  additionalHeaders["x-ms-version"] = "2018-03-28"
  additionalHeaders["x-ms-date"]    = date_utc(opts.time)

  stringToSign = stringGenerator(opts, additionalHeaders)
  opts.sig      = hmacauth.sign(base64_decode(opts.account_key), stringToSign)
  additionalHeaders["Authorization"] = "SharedKey #{opts.account_name}:#{sig}"
  opts.additionalHeaders
  opts

{ :date_utc, :sharedkeylite, :sharedkey }
