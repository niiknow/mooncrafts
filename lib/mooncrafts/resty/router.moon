-- router with support of dynamic code execution
-- this router is built for use with openresty
--
-- bucket: 'bucket-name'
-- name: 'the-site-name'
-- base: 'https://<bucket-name>.s3-website-<AWS-region>.amazonaws.com/the-site-name'
--
-- rules: {
--   for: '/path/regex'
--   http_methods: "GET,POST" -- array of http methods, * or empty for all
--   type: 'request/response'
--   dest: 'destination path or url'
--   status: 'response status code to use'
--   headers: {} -- pass custom or override existing headers to request/response
--   template_url: 'use this template instead of default template'
--
-- // these are future headers
--   handler: 'lua compiled function'
--   handler_url: 'url to the handler source file'
--}
--
-- common status:
-- 0/empty - continue processing next rule
-- 200 - return immediately
-- 301,302 - redirect
-- 4xx - client errors
-- 5xx - server error
--
-- syntax for:
-- '/simple' - simple path
-- '/user/:id' - capture id params
-- '/do/*' - capture splat param
-- '/something/else?weird=:p' -- capture url param
--
-- syntax dest:
-- '/relative/path/' - for redirect
-- 'https://yourapi.com/user/:id' - use id in request to proxy
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

crypto   = require "mooncrafts.crypto"
util     = require "mooncrafts.util"
log      = require "mooncrafts.log"
url      = require "mooncrafts.url"
Liquid   = require "mooncrafts.resty.liquid"
Remotefs = require "mooncrafts.remotefs"

local *

url_parse       = url.parse
compile_pattern = url.compile_pattern
match_pattern   = url.match_pattern
build_with_splats = url.build_with_splats
base64_decode   = crypto.base64_decode
strlen          = string.len
string_upper    = string.upper
string_match    = string.match
trim            = util.trim
string_split    = util.string_split
table_extend    = util.table_extend
table_clone     = util.table_clone
table_remove    = table.remove
join            = table.concat
table_insert    = table.insert

compile_rules = (opts) ->
  req_rules = {}
  res_rules = {}

  -- expect list to already been sorted
  if (opts.rules)
    for k, rr in pairs(opts.rules)
      r         = table_clone(rr, true)
      r.pattern = compile_pattern(r.for)
      r.status  = 0 if not r.status
      r.type    = 'request' if not r.type

      if (r.type == 'response')
        table_insert(res_rules, r)
      else
        table_insert(req_rules, r)

      r.dest = if r.dest then trim(r.dest) else ""
      r.headers = {} if not r.headers
      r.http_methods = if r.http_methods then string_upper(r.http_methods) else "*"

      -- make sure status is correct for relative path
      r.status = 302 if (r.status <= 300 or r.status >= 400) and r.dest\find("/") == 1

  opts.req_rules = req_rules
  opts.res_rules = res_rules
  opts

class Router
  new: (opts) =>
    conf      = compile_rules(opts)

    -- set site info
    site      = if opts.site then opts.site else {}
    conf.site = table_clone(site, true)
    conf.base = site.base_url if site.base_url

    fs   = Remotefs({base: conf.base})
    @viewEngine = Liquid(fs)
    @conf = conf

  -- normalize the nginx request object
  parseNginxRequest: (ngx) =>
    return {} if not ngx

    ngx.req.read_body!
    req_headers = ngx.req.get_headers!
    scheme = ngx.var.scheme
    path = trim(ngx.var.request_uri)
    port = ngx.var.server_port or 80
    is_args = ngx.var.is_args or ""
    args = ngx.var.args or ""
    queryStringParameters = ngx.req.get_uri_args!
    host = ngx.var.host or "127.0.0.1"
    url = "#{scheme}://#{host}#{path}#{is_args}#{args}"
    path_parts = string_split(trim(path, "/"))
    {
      body: ngx.req.get_body_data!
      form: ngx.req.get_post_args!
      headers: req_headers
      host: host
      http_method: ngx.var.request_method
      path: path
      path_parts: path_parts
      port: server_port
      args: args
      is_args: is_args
      query_string_parameters: queryStringParameters
      remote_addr: ngx.var.remote_addr
      referer: ngx.var.http_referer or "-"
      scheme: ngx.var.scheme
      server_addr: ngx.var.server_addr
      user_agent: ngx.var.http_user_agent
      url: url
      sign_url: "#{scheme}://#{host}:#{port}#{path}#{is_args}#{args}"
      cb: queryStringParameters.cb
      cookies: ngx.var.http_cookie
      language: ngx.var.http_accept_language
      authorization: ngx.var.http_authorization
    }

  -- this is a before-request/access level event
  parseBasicAuth: (req) =>
    assert(req, "request object is required")
    assert(req.headers, "request headers parameter is required")

    rst   = {code: 0, headers: {}, rules: {}}
    bauth = @conf.basic_auth or ""

    if strlen(bauth) > 0
      -- prevent auth header from reaching downstream requests
      req.headers['authorization'] = nil

      if not req.authorization
        rst.code    = 401
        rst.headers = {["Content-Type"]: "text/plain", ["WWW-Authenticate"]: 'realm="Access to site.", charset="UTF-8"'}
        rst.body    = "Please auth!"
        return rst

      userpass_b64 = string_match(trim(req.authorization), "Basic%s+(.*)")
      unless userpass_b64
        rst.code    = 401
        rst.headers =  {["Content-Type"]: "text/plain"}
        rst.body    = "Your browser sent a bad Authorization HTTP header!"
        return rst

      userpass = base64_decode(userpass_b64)
      unless userpass
        rst.code    = 401
        rst.headers = {["Content-Type"]: "text/plain"}
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

    myRules     = @conf.req_rules
    reqUrl      = req.url
    rst.isRedir = false

    for i=1, #myRules
      r = myRules[i]

      -- parse by specific method
      if (r.http_methods == "*" or r.http_methods\find(req.http_method))
        -- ngx.log(ngx.ERR, util.to_json(r))
        -- then match by path
        match, params = match_pattern(reqUrl, r.pattern)

        -- ngx.log(ngx.ERR, util.to_json(params))
        -- parse dest
        if match
          status = r.status or 0
          table_insert(rst.rules, r)
          rst.pathParameters = params if #params > 0 -- provide downstream with pathParameters

          -- set target if valid dest
          rst.target = build_with_splats(r.dest, params) if (strlen(r.dest) > 0)

          -- a redirect if status is greater than 300
          rst.isRedir      = status > 300
          rst.code         = status
          rst.template_url = r.template_url if r.template_url

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
    -- rst.headers = table_clone(req.headers) if req.headers
    myRules = @conf.res_rules
    reqUrl  = req.url

    for i=1, #myRules
      r = myRules[i]

      -- parse by specific method
      if (r.http_methods == "*" or r.http_methods\find(req.http_method))

        match = match_pattern(reqUrl, r.pattern)
        -- print util.to_json(params)

        if match
          table_insert(rst.rules, r)
          -- print util.to_json(rst.headers)
          -- print util.to_json(r.headers)
          table_extend(rst.headers, r.headers)

    rst

  -- handle page rendering
  handlePage: (ngx, req, rst, proxyPath='/__proxy') =>
    -- only handle pages: no file extension
    path = req.path
    path = "/index" if req.path == "/"
    base = @conf.base
    rst.template = "page" if path != "/index"
    rst.ext = "liquid" if not rst.ext

    urls = {
      {proxyPath, {args: {target: "#{base}/templates/#{rst.template}.#{rst.ext}"}}}
      {proxyPath, {args: {target: "#{base}/contents#{path}.json"}}}
    }

    -- ngx.log(ngx.ERR, util.to_json(urls))

    page, data = ngx.location.capture_multi(urls)

    req.page     = { content: {} }
    req.template = page.body if page.status < 300 and page.status > 199

    if (data and data.status < 300 and data.body and data.body\find("{") != nil)
      req.page      = util.from_json(data.body) -- parse page json

    if (data and data.status == 404)
      -- TODO: handle redirect outside of this function
      return { code: 404, headers: {}, body: "Page not found: #{path}" }

    req.page.site = table_clone(@conf.site, true)

    -- page can override it's own template
    req.template  = req.page.template if req.page.template

    -- push in request
    {
      code: 200
      headers: {}
      body: trim(@viewEngine\render(req.template, req.page))
    }

  handleProxy: (req, rst, proxyPath='/__proxy') =>
    req = {
      url: rst.target,
      method: "GET",
      capture_url: proxyPath,
      headers: rst.headers,
      body: rst.body
    }
    httpc.request(req)

  handleRequest: (ngx, proxyPath='/__proxy') =>
    -- preprocess rule
    req = @parseNginxRequest(ngx)
    rst = @parseRedirects(req)

    rst.template = "index" if req.path == "/"
    rst.template = "page" if not rst.template
    rst.ext      = "liquid" if not rst.ext

    -- redirect
    return ngx.redirect(rst.target, rst.code) if rst.isRedir

    -- append headers based on matching rules
    rules = rst.rules
    for i=1, #rules
      r = rules[i]
      for k, v in pairs(r.headers)
        rst.headers[k] = v unless k == 'content-length'

    page_rst = nil

    -- proxy pass if target
    if (rst.target)
      page_rst = @handleProxy(req, rst, proxyPath)
    else -- handle the current page
      page_rst = @handlePage(ngx, req, rst, proxyPath)


    -- set response headers for valid response
    if (page_rst.code >= 200 or page_rst.code < 300)
      headers     = page_rst.headers
      new_headers = @parseHeaders(req)

      -- override existing response headers
      for k, v in pairs(new_headers)
        headers[k] = v unless k == 'content-length'

      -- now set the response header
      for k, v in pairs(headers) do ngx.header[k] = v

    -- allow template to handle it's own error
    -- and response with appropriate error body
    ngx.status = page_rst.code if (page_rst.code)
    ngx.say(page_rst.body) if (page_rst.body)
    ngx.exit(ngx.status) if ngx.status

Router
