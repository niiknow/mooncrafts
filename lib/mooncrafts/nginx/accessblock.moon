-- validate host by dns
util = require "mooncrafts.util"

import is_ip, path_sanitize from util

guard = (host=ngx.var.host) ->
  host = ngx.var.host

  if is_ip(host)
    ngx.status = 403
    ngx.say("#{host} is invalid")
    ngx.exit(ngx.status)
    return false

  parts = string_split(host, ".")
  host  = "www." .. host if (#parts < 3)
  answers, err = cname_dns.resolve(host)

  if err
    ngx.status = 403
    ngx.say(err)
    ngx.exit(ngx.status)
    return false

  if not answers
    ngx.status = 403
    ngx.say("failed to query the DNS server: ", err)
    ngx.exit(ngx.status)
    return false

  -- empty sitename to prevent downstream issue
  ngx.var.__sitename = nil

  -- at least one cname must match base host
  for i, ans in ipairs(answers) do
    if ans.base == base_host
      __sitename = path_sanitize(ans.name)
      -- capture the config
      router = router_cache.resolve(__sitename)
      if router
        ngx.var.__sitename = __sitename
        return true

  ngx.status = 403
  ngx.say("failed to query valid CNAME from DNS server")
  ngx.exit(ngx.status)
  return false

{ :guard }
