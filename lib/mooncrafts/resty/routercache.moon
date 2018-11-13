-- cache route to dns host
lrucache = require "resty.lrucache"
util     = require "mooncrafts.util"
Router   = require "mooncrafts.resty.router"
Config   = require "mooncrafts.resty.config"
aws_auth = require "mooncrafts.awsauth"
httpc    = require "mooncrafts.http"

import string_split from util

CACHE_SIZE = 10000
ROUTER_TTL = 3600

cache, err = lrucache.new(CACHE_SIZE)

return nil, error("failed to create the cache: " .. (err or "unknown")) if (not cache)

resolve = (name) ->
  router = cache\get(name)
  return router if router

  opts = Config()\get()
  -- ngx.log(ngx.ERR, tostring(opts))

  opts.aws.aws_host = "s3.#{opts.aws.aws_region}.amazonaws.com"

  -- attempt to resolve router web.json
  opts.aws.request_path = "/#{opts.aws.aws_s3_path}/#{name}/private/web.json"
  aws = aws_auth(opts.aws)
  full_path = "https://#{aws.options.aws_host}#{opts.aws.request_path}"
  authHeaders = aws\get_auth_headers()

  req = { url: full_path, method: "GET", headers: {} }

  for k, v in pairs(authHeaders) do
    req.headers[k] = v

  -- ngx.log(ngx.ERR, 'req' .. util.to_json(req))
  res, err = httpc.request(req)

  if err
    ngx.status = 500
    ngx.say("failed to query website configuration file ", err)
    return ngx.exit(ngx.status)


  if res.code > 299
    ngx.status = 500
    ngx.say("failed to fetch website configuration file, status: ", res.code)
    return ngx.exit(ngx.status)

  -- check valid json
  if (res.body\find('{') == nil)
    ngx.status = 500
    ngx.say("invalid website configuration file, status: ", res.code)
    return ngx.exit(ngx.status)

  -- parse json
  config = util.from_json(res.body)
  base   = "https://#{aws.options.aws_host}/#{opts.aws.aws_s3_path}/#{name}/public"
  config.base = base if not config.base
  router = Router(config)

  cache\set(name, router, ROUTER_TTL)
  router

{ :resolve }
