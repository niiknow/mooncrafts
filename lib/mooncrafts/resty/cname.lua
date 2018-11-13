local resolver = require("resty.dns.resolver")
local lrucache = require("resty.lrucache")
local util = require("mooncrafts.util")
local string_split
string_split = util.string_split
local CACHE_SIZE = 10000
local cache, err = lrucache.new(CACHE_SIZE)
if (not cache) then
  return nil, error("failed to create the cache: " .. (err or "unknown"))
end
local cname_records_and_max_ttl, resolve
cname_records_and_max_ttl = function(answers)
  local addresses = { }
  local ttl = 3600
  for _, ans in ipairs(answers) do
    if ans.cname then
      local parts = string_split(ans.cname)
      if (#parts == 3) then
        if ans.ttl then
          ttl = ans.ttl
        end
        ans.name = parts[0]
        ans.base = parts[1] .. "." .. parts[2]
        table.insert(addresses, ans)
      end
    end
  end
  return addresses, ttl
end
resolve = function(host, nameservers)
  if nameservers == nil then
    nameservers = nil
  end
  if (nameservers == nil) then
    nameservers = {
      "127.0.0.1"
    }
  end
  local cached_addresses = cache:get(host)
  if cached_addresses then
    return cached_addresses
  end
  local r
  r, err = resolver:new({
    nameservers = nameservers
  }, {
    retrans = 5
  }, {
    timeout = 2000
  })
  if not r then
    ngx.log(ngx.ERR, "failed to instantiate the resolver: " .. tostring(err))
    return nil, {
      host
    }
  end
  local answers
  answers, err = r:query(host, {
    qtype = r.TYPE_CNAME
  }, { })
  if not answers then
    ngx.log(ngx.ERR, "failed to query the DNS server: " .. tostring(err))
    return nil, {
      host
    }
  end
  if answers.errcode then
    ngx.log(ngx.ERR, string.format("server returned error code: %s: %s", answers.errcode, answers.errstr))
    return nil, {
      host
    }
  end
  local addresses, ttl = cname_records_and_max_ttl(answers)
  if #addresses == 0 then
    ngx.log(ngx.ERR, "no CNAME record resolved")
    return nil, {
      host
    }
  end
  cache:set(host, addresses, ttl)
  return addresses
end
return {
  resolve = resolve
}
