local util = require("mooncrafts.util")
local path_sanitize
path_sanitize = util.path_sanitize
local engage
engage = function(__sitename)
  if __sitename == nil then
    __sitename = ngx.var.__sitename
  end
  __sitename = path_sanitize(__sitename)
  ngx.var.__sitename = __sitename
  local router = router_cache.resolve(__sitename)
  if router == nil then
    ngx.log(ngx.ERR, __sitename)
  end
  if router then
    return router:handleRequest(ngx)
  end
  ngx.status = 500
  ngx.say("Unexpected error while handling request, this should be a 404")
  return ngx.exit(ngx.status)
end
return {
  engage = engage
}
