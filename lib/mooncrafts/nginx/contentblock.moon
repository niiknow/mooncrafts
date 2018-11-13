-- get the app content
util = require "mooncrafts.util"

import path_sanitize from util

engage = (__sitename=ngx.var.__sitename) ->
  -- ensure sitename is saniized
  __sitename         = path_sanitize(__sitename)
  ngx.var.__sitename = __sitename

  router = router_cache.resolve(__sitename)

  ngx.log(ngx.ERR, __sitename) if router == nil
  return router\handleRequest(ngx) if router

  ngx.status = 500
  ngx.say("Unexpected error while handling request, this should be a 404")
  ngx.exit(ngx.status)

{ :engage }
