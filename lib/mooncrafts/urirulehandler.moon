-- router with support of dynamic code execution
-- this router is built for use with openresty
--
-- bucket: 'bucket-name'
-- sitename: 'the-site-name'
-- basepath: 'http://s3.amazonaws.com/bucket-name/the-site-name'
--
-- rules: {
--   match_uri: '/path/regex'
--   method: 'POST,GET,NULL_IS_ALL'
--   type: 'request/response'
--   dest: 'destination path or url'
--   status: 'status code to use'
--   headers: {} -- pass custom or override existing headers to request/response
--   explicit_headers: "Content-Type,OPTIONS" -- csv format to clear all client headers and pass only these to proxy
--
-- // these are future headers
--   handler: 'lua compiled function'
--   handler_meta: {
--      url: 'the source url'
--      local: 'the local path'
--      modify_at: 'last time it was modified'
--   }
--}
--
-- common status:
-- 0/empty - continue processing next rule
-- 200 - return immediately
-- 301,302 - redirect
-- 4xx - client errors
-- 5xx - server error
--
-- syntax match_uri:
-- '/simple' - simple path
-- '/user/:id' - capture id params
-- '/do/*' - capture splat param
-- '/something/else?weird=:p' -- capture url param
-- 'POST,GET /simple' - match only specific HTTP method instead of all
--
-- syntax dest:
-- 'https://yourapi.com/user/:id' - use id in request to proxy
-- 'POST https://anotherapi.com/user/:id' - translate all methods to post
--
-- syntax headers auth:
-- 'auth_basic': 'user:pass' - provide basic auth to proxy server
-- // use oauth1 in the case of twitter
-- 'auth_oauth1': 'consumerkey=aaa;consumersecret=bbb;accesstoken=ccc;tokensecret=ddd;version=1.0;callback=callbackurl'
-- // use other methods for cloud storage
-- 'auth_azure': 'connection-string'
-- 'auth_aws': 'access_key_id=bbb;secret_access_key=aaa;region=ddd'
-- // other simple headers
-- 'X-Token': 'your api token' - best way to authenticate
--

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
url_parse       = url.parse

compile_list = (opts) ->
  opts.req_rules  = {}
  opts.res_rules = {}

  -- expect list to already been sorted
  for k, r in pairs(opts.rules)
    r.pattern = compile_pattern(r.source)
    r.status  = 0 if r.status == nil
    if (r.type == 'response')
      table_insert(opts.res_rules, r)
    else
      table_insert(opts.req_rules, r)

    r.dest = trim(r.dest or "")

    -- make sure status is correct for relative path
    r.status = 302 if (r.status <= 300 or r.status >= 400) and r.dest\find("/") == 1

  opts

class UriRuleHandler
  new: (opts) =>
    conf = compile_rules(opts)

    @conf = conf

  -- this is a before-request/access level event
  parseBasicAuth: (req) =>
    assert(req, "request object is required")
    assert(req.headers, "request headers parameter is required")

    rst   = {code: 0, headers: {}, rules: {}}
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

    rst = @parseBasicAuth(req)

    -- exit if invalid auth
    return rst if (rst.code > 0)

    myRules = @conf.redirects
    reqUrl  = req.url

    for i=1, #myRules
      r             = myRules[i]
      match, params = url.match_pattern(reqUrl, r.pattern)

      -- parse dest
      if match
        status = r.status or 0
        table_insert(rst.rules, r)

        -- only process if r.dest has a value
        if (strlen(r.dest) > 0)
          rst.target  = url.build_with_splats(r.dest, params)

        -- a redirect if status is greater than 300
        rst.isRedir = status > 300
        rst.params  = params
        rst.code    = status

        -- stop rule processing for valid status
        return rst if (rst.code > 0)

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

    handlePage: (ngx) =>
      -- handle page rendering

    handleProxy: (ngx, rst, proxyPath) =>
      -- change the host to target host
      parsed_target = url_parse rst.target
      ngx.var.host  = parsed_target.host

      -- set appropriate headers before proxy

      -- finally execute proxy
      return ngx.exec(proxyPath or "/proxy")

    handleRequest: (ngx, proxyPath) =>
      -- preprocess rule
      rst = @parseRedirects(ngx.req)
      rst.target = fallbackDest if not (rst.dest)

      -- process result
      if rst.isRedir
        -- redirect
        return ngx.redirect(rst.target, rst.code)

      -- create additional response headers
      page_rst = { code: 0 }

      -- proxy pass if target
      if (rst.target)
        page_rst = @handleProxy(ngx, rst, proxyPath)
      else -- handle the current page
        page_rst = @handlePage(ngx.req)

      -- only set headers if valid result
      if (page_rst.code > 200 or page_rst.code < 300)
        headers     = page_rst.headers
        new_headers = @parseHeaders(ngx.req)

        -- override existing response headers
        for k, v in pairs(new_headers)
            if k ~= 'content-length' then headers(k, v)

        -- now set the response header
        for k, v in pairs(headers) do ngx.header[k] = v

      -- allow template to handle it's own error
      -- and response with appropriate error body
      ngx.say(page_rst.body) if (page_rst.body)
      ngx.exit(page_rst.code) if (pagerst.code)

UriRuleHandler
