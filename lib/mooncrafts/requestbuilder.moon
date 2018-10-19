-- build request plugins based on options
sandbox = require "mooncrafts.sandbox"
util    = require "mooncrafts.util"

class RequestBuilder
  new: (opts={}) =>
    @req = opts

  build: (opts) =>
    req = {}
    if ngx
      ngx.req.read_body!
      req_headers = ngx.req.get_headers!
      scheme = ngx.var.scheme
      path = ngx.var.request_uri
      port = ngx.var.server_port
      is_args = ngx.var.is_args
      args = ngx.var.args
      queryStringParameters = ngx.req.get_uri_args!
      req = {
        body: ngx.req.get_body_data!
        form: ngx.req.get_post_args!
        headers: req_headers
        host: host
        http_method: ngx.req.get_method!
        path: path
        port: server_port
        args: args
        is_args: is_args
        query_string_parameters: queryStringParameters
        remote_addr: ngx.var.remote_addr
        referer: ngx.var.http_referer or "-"
        scheme: ngx.var.scheme
        server_addr: ngx.var.server_addr
        user_agent: req_headers["User-Agent"]
        full_uri: "#{scheme}://$host$path$is_args$args"
        sign_uri: "#{scheme}://$host:$port$path$is_args$args"
        cb: queryStringParameters.cb
        language: req_headers["Accept-Language"]
      }
      @req           = req

    @req.logs = {}
    @

  set: (req) =>
    @req = req
    @

  log: (obj) =>
    logs = @req.logs
    @req.logs[#logs + 1] = if (type obj == "table") then util.to_json(obj) else tostring(t)
    @

RequestBuilder
