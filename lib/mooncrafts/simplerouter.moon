-- this is a simple router similar to netlify logic to
-- handle _redirects and _headers configuration table

util   = require "mooncrafts.util"
log    = require "mooncrafts.log"
url    = require "mooncrafts.url"
crypto = require "mooncrafts.crypto"

table_sort      = table.sort
compile_pattern = url.compile_pattern
base64_decode   = crypto.base64_decode
trim            = util.trim
strlen          = string.len
table_extend    = util.table_extend
table_insert    = table.insert

compile_list = (myList) =>
  return {} if myList == nil

  -- expect list in order of highest priority first
  for i=1, #myList
    r         = myList[i]
    r.pattern = compile_pattern(v.source)
    r.status  = 0 if r.status == nil

class SimpleRouter
  new: (name, conf={}) =>
    myConf = conf or {}
    myConf.redirects  = compile_list(myConf.redirects)
    myConf.headers    = compile_list(myConf.headers)
    myConf.basic_auth = trim(myConf.basic_auth or "")
    @conf = myConf

  -- this is a before-request/access level event
  parseBasicAuth: (req) =>
    assert(req, "request object is required")
    assert(req.headers, "request headers parameter is required")

    rst   = {code: 0, headers: {}}
    bauth = @conf.basic_auth

    if strlen(bauth) > 0
      authorization = trim(req.headers.authorization or "")

      if strlen(authorization) < 0
        rst.code    = 401
        rst.headers = {["Content-Type"]: "text/plain", ["WWW-Authenticate"]: 'realm="Access to site.", charset="UTF-8"'}
        rst.body    = "Please auth!"
        return rst

      userpass_b64 = authorization.match("Basic%s+(.*)")
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
  -- is is a before-request event
  parseRedirects: (req) =>
    assert(req, "request object is required")
    assert(req.url, "request url is required")

    rst = { }

    myRules = @conf.redirects
    for i=1, #myRules
      r             = myRules[i]
      match, params = url.match(r.pattern, req.url)

      -- parse dest
      if match
        rst.rule    = r
        rst.target  = url.build_with_splats(r.dest, params)
        -- a redirect if status is greater than 300
        rst.isRedir = r.status > 300
        -- otherwise, it could be a rewrite or proxy
        return rst

    rst

  -- parse header and return result
  -- this is an after-request event
  parseHeaders: (req) =>
    assert(req, "request object is required")
    assert(req.url, "request url is required")

    matches = { }
    myRules = @conf.redirects
    for i=1, #myRules
      r     = myRules[i]
      match = url.match(r.pattern, req.url)

      if match
        table_insert(matches, r)

    matches

SimpleRouter
