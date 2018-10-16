-- build request plugins based on options
sandbox = require "mooncrafts.sandbox"
util    = require "mooncrafts.util"

class RequestBuilder
  new: (opts={}) =>
    @req = opts

  build: (opts) =>
    req_wrapper = {}
    if ngx
      ngx.req.read_body()
      req_wrapper = {
        body: ngx.req.get_body_data(),
        form: ngx.req.get_post_args(),
        headers: ngx.req.get_headers(),
        host: ngx.var.host,
        method: ngx.req.get_method(),
        path: ngx.var.uri,
        port: ngx.var.server_port,
        query: ngx.req.get_uri_args(),
        querystring: ngx.req.args,
        remote_addr: ngx.var.remote_addr,
        referer: ngx.var.http_referer or "-",
        scheme: ngx.var.scheme,
        server_addr: ngx.var.server_addr,
        user_agent: "",
      }
      req_wrapper.cb = req_wrapper.query.cb
      req_wrapper.user_agent = req_wrapper.headers["User-Agent"]
      @req = req_wrapper

    @req.logs = {}
    @req

  set: (req) =>
    @req = req

  log: (obj) =>
    if (type obj == "table")
      @req.logs[#@req.logs + 1] = util.to_json(obj)
    else
      @req.logs[#@req.logs + 1] = tostring(t)

RequestBuilder
