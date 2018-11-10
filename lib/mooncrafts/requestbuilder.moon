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
      path = trim(ngx.var.request_uri)
      port = ngx.var.server_port or 80
      is_args = ngx.var.is_args or ""
      args = ngx.var.args or ""
      queryStringParameters = ngx.req.get_uri_args!
      host = ngx.var.host or "127.0.0.1"
      url = "#{scheme}://#{host}#{path}#{is_args}#{args}"
      path_parts = string_split(trim(path, "/"))
      {
        body: ngx.req.get_body_data!
        form: ngx.req.get_post_args!
        headers: req_headers
        host: host
        http_method: ngx.var.request_method
        path: path
        path_parts: split
        port: server_port
        args: args
        is_args: is_args
        query_string_parameters: queryStringParameters
        remote_addr: ngx.var.remote_addr
        referer: ngx.var.http_referer or "-"
        scheme: ngx.var.scheme
        server_addr: ngx.var.server_addr
        user_agent: ngx.var.http_user_agent
        url: url
        sign_url: "#{scheme}://#{host}:#{port}#{path}#{is_args}#{args}"
        cb: queryStringParameters.cb
        cookies: ngx.var.http_cookie
        language: ngx.var.http_accept_language
        authorization: ngx.var.http_authorization
      }
      @req = req

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
