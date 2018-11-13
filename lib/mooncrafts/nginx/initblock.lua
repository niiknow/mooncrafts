auto_ssl = (require("resty.auto-ssl")).new()
cname_dns = require("mooncrafts.resty.cname")
router_cache = require("mooncrafts.resty.routercache")
local bh = os.getenv("BASE_HOST")
local lu = os.getenv("LETSENCRYPT_URL")
local dir = "/usr/local/openresty/nginx/conf/ssl"
local init
init = function(base_host, letsencrypt_url, dir)
  if base_host == nil then
    base_host = bh
  end
  if letsencrypt_url == nil then
    letsencrypt_url = lu
  end
  if dir == nil then
    dir = "/usr/local/openresty/nginx/conf/ssl"
  end
  auto_ssl:set("ca", lu)
  auto_ssl:set("allow_domain", function(domain)
    local host = domain
    local parts = string_split(domain, ".")
    if (#parts < 3) then
      host = "www." .. domain
    end
    local answers, err = cname_dns.resolve(host)
    if err then
      ngx.status = 500
      ngx.say(err)
      ngx.exit(ngx.status)
      return false
    end
    if not answers then
      ngx.status = 500
      ngx.say("failed to query the DNS server: ", err)
      ngx.exit(ngx.status)
      return false
    end
    for i, ans in ipairs(answers) do
      if ans.base == base_host then
        return true
      end
    end
    ngx.status = 500
    ngx.say("failed to query valid CNAME from DNS server")
    ngx.exit(ngx.status)
    return false
  end)
  auto_ssl:set("dir", dir)
  return auto_ssl:init()
end
return {
  init = init
}
