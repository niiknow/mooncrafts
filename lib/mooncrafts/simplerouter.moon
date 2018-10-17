-- this is a simple router similar to netlify logic to
-- handle _redirects and _headers configuration table

crypto = require "mooncrafts.crypto"
util   = require "mooncrafts.util"
log    = require "mooncrafts.log"
url    = require "mooncrafts.url"

compile_pattern = url.compile_pattern
base64_decode   = crypto.base64_decode
trim            = util.trim
strlen          = string.len
table_insert    = table.insert
table_extend    = util.table_extend
string_match    = string.match

compile_list = (myList) ->
  -- expect list to already been sorted
  for k, r in pairs(myList)
    r.pattern = compile_pattern(r.source)
    r.status  = 0 if r.status == nil

  myList

class SimpleRouter
  new: (conf) =>
    assert(conf, "config object is required")
    myConf = {}
    myConf.redirects  = compile_list(conf.redirects or {})
    myConf.headers    = compile_list(conf.headers or {})
    myConf.basic_auth = trim(conf.basic_auth or "")
    -- print util.to_json(myConf)
    @conf = myConf

  -- this is a before-request/access level event
  parseBasicAuth: (req) =>
    assert(req, "request object is required")
    assert(req.headers, "request headers parameter is required")

    rst   = {code: 0, headers: {}}
    bauth = @conf.basic_auth

    if strlen(bauth) > 0
      authorization = req.headers.authorization

      if not authorization
        rst.code    = 401
        rst.headers = {["Content-Type"]: "text/plain", ["WWW-Authenticate"]: 'realm="Access to site.", charset="UTF-8"'}
        rst.body    = "Please auth!"
        return rst

      userpass_b64 = string_match(trim(authorization), "Basic%s+(.*)")
      unless userpass_b64
        rst.code    = 401
        rst.headers =  {["Content-Type"]: "text/plain"}
        rst.body    = "Your browser sent a bad Authorization HTTP header!"
        return rst

      userpass = base64_decode(userpass_b64)
      unless userpass
        rst.code    = 401
        rst.headers =  {["Content-Type"]: "text/plain"}
        rst.body    = "Your browser sent a bad Authorization HTTP header!"
        return rst

      unless bauth == userpass
        rst.code    = 403
        rst.headers =  {["Content-Type"]: "text/plain", ["WWW-Authenticate"]: 'realm="Access to site.", charset="UTF-8"'}
        rst.body    = "Auth failed!"
        return rst

    rst


  -- parse request and return result
  -- this is a before-request event
  parseRedirects: (req) =>
    assert(req, "request object is required")
    assert(req.url, "request url is required")

    rst = { }

    myRules = @conf.redirects
    reqUrl  = req.url

    for i=1, #myRules
      r             = myRules[i]
      match, params = url.match_pattern(reqUrl, r.pattern)

      -- parse dest
      if match
        rst.rule    = r
        rst.target  = url.build_with_splats(r.dest, params)
        -- a redirect if status is greater than 300
        rst.isRedir = r.status > 300
        rst.params  = params
        -- otherwise, it could be a rewrite or proxy
        return rst

    rst

  -- parse header and return result
  -- this is an after-request event
  parseHeaders: (req) =>
    -- print util.to_json(req)
    assert(req, "request object is required")
    assert(req.url, "request url is required")

    rst = { rules: {}, headers: {} }
    myRules = @conf.headers
    reqUrl  = req.url

    for i=1, #myRules
      r     = myRules[i]
      match = url.match_pattern(reqUrl, r.pattern)
      -- print util.to_json(params)

      if match
        table_insert(rst.rules, r)
        -- print util.to_json(rst.headers)
        -- print util.to_json(r.headers)
        table_extend(rst.headers, r.headers)

    rst

SimpleRouter
