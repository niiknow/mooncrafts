local lrucache = require("resty.lrucache")
local util = require("mooncrafts.util")
local Router = require("mooncrafts.resty.router")
local Config = require("mooncrafts.resty.config")
local aws_auth = require("mooncrafts.awsauth")
local httpc = require("mooncrafts.http")
local string_split
string_split = util.string_split
local CACHE_SIZE = 10000
local ROUTER_TTL = 3600
local cache, err = lrucache.new(CACHE_SIZE)
if (not cache) then
  return nil, error("failed to create the cache: " .. (err or "unknown"))
end
local resolve
resolve = function(name)
  local router = cache:get(name)
  if router then
    return router
  end
  local opts = Config():get()
  opts.aws.aws_host = "s3." .. tostring(opts.aws.aws_region) .. ".amazonaws.com"
  opts.aws.request_path = "/" .. tostring(opts.aws.aws_s3_path) .. "/" .. tostring(name) .. "/private/web.json"
  local aws = aws_auth(opts.aws)
  local full_path = "https://" .. tostring(aws.options.aws_host) .. tostring(opts.aws.request_path)
  local authHeaders = aws:get_auth_headers()
  local req = {
    url = full_path,
    method = "GET",
    headers = { }
  }
  for k, v in pairs(authHeaders) do
    req.headers[k] = v
  end
  local res
  res, err = httpc.request(req)
  if err then
    ngx.status = 500
    ngx.say("failed to query website configuration file ", err)
    return ngx.exit(ngx.status)
  end
  if res.code > 299 then
    ngx.status = 500
    ngx.say("failed to fetch website configuration file, status: ", res.code)
    return ngx.exit(ngx.status)
  end
  if (res.body:find('{') == nil) then
    ngx.status = 500
    ngx.say("invalid website configuration file, status: ", res.code)
    return ngx.exit(ngx.status)
  end
  local config = util.from_json(res.body)
  local base = "https://" .. tostring(aws.options.aws_host) .. "/" .. tostring(opts.aws.aws_s3_path) .. "/" .. tostring(name) .. "/public"
  if not config.base then
    config.base = base
  end
  router = Router(config)
  cache:set(name, router, ROUTER_TTL)
  return router
end
return {
  resolve = resolve
}
