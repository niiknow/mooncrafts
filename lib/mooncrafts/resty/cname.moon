resolver = require "resty.dns.resolver"
lrucache = require "resty.lrucache"
util     = require "mooncrafts.util"

import string_split from util

CACHE_SIZE = 10000
cache, err = lrucache.new(CACHE_SIZE)

return nil, error("failed to create the cache: " .. (err or "unknown")) if (not cache)

local *

cname_records_and_max_ttl = (answers) ->
  addresses = {}
  ttl       = 3600

  for _, ans in ipairs(answers)
    if ans.cname
      parts = string_split(ans.cname)
      if (#parts == 3)
        ttl = ans.ttl if ans.ttl
        parts_count = #parts
        ans.name = parts[1]
        ans.base = parts[parts_count - 1] .. "." .. parts[parts_count]
        table.insert(addresses, ans)

  addresses, ttl

resolve = (host, nameservers = nil) ->
  nameservers = {"127.0.0.1"} if (nameservers == nil)

  cached_addresses = cache\get(host)
  return cached_addresses if cached_addresses

  r, err = resolver\new(
    nameservers: nameservers,
    retrans: 5
    timeout: 2000  -- 2 sec
  )

  if not r
    ngx.log(ngx.ERR, "failed to instantiate the resolver: " .. tostring(err))
    return nil, { host }

  answers, err = r\query(host, { qtype: r.TYPE_CNAME }, {})
  if not answers
    ngx.log(ngx.ERR, "failed to query the DNS server: " .. tostring(err))
    return nil, { host }

  if answers.errcode
    ngx.log(ngx.ERR, string.format("server returned error code: %s: %s", answers.errcode, answers.errstr))
    return nil, { host }

  addresses, ttl = cname_records_and_max_ttl(answers)
  if #addresses == 0
    ngx.log(ngx.ERR, "no CNAME record resolved")
    return nil, { host }

  cache\set(host, addresses, ttl)
  addresses

{ :resolve }
