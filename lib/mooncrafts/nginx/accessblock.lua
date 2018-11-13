local util = require("mooncrafts.util")
local is_ip, path_sanitize
is_ip, path_sanitize = util.is_ip, util.path_sanitize
local guard
guard = function(host)
  if host == nil then
    host = ngx.var.host
  end
  host = ngx.var.host
  if is_ip(host) then
    ngx.status = 403
    ngx.say(tostring(host) .. " is invalid")
    ngx.exit(ngx.status)
    return false
  end
  local parts = string_split(host, ".")
  if (#parts < 3) then
    host = "www." .. host
  end
  local answers, err = cname_dns.resolve(host)
  if err then
    ngx.status = 403
    ngx.say(err)
    ngx.exit(ngx.status)
    return false
  end
  if not answers then
    ngx.status = 403
    ngx.say("failed to query the DNS server: ", err)
    ngx.exit(ngx.status)
    return false
  end
  ngx.var.__sitename = nil
  for i, ans in ipairs(answers) do
    if ans.base == base_host then
      local __sitename = path_sanitize(ans.name)
      local router = router_cache.resolve(__sitename)
      if router then
        ngx.var.__sitename = __sitename
        return true
      end
    end
  end
  ngx.status = 403
  ngx.say("failed to query valid CNAME from DNS server")
  ngx.exit(ngx.status)
  return false
end
return {
  guard = guard
}
