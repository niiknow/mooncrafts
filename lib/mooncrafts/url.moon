-- custom url parsing implementation
-- since there are so many that does not meet requirements - wtf?
util = require "mooncrafts.util"

import insert from table
import url_unescape from util

local *

re_match     = string.match
tonumber     = tonumber
setmetatable = setmetatable
string_split = util.string_split
table_insert = table.insert

HTTPPHRASE = {
  [100]: "Continue",
  [101]: "Switching Protocols",
  [200]: "OK",
  [201]: "Created",
  [202]: "Accepted",
  [203]: "Non-Authoritative Information",
  [204]: "No Content",
  [205]: "Reset Content",
  [206]: "Partial Content",
  [300]: "Multiple Choices",
  [301]: "Moved Permanently",
  [302]: "Moved Temporarily",
  [303]: "See Other",
  [304]: "Not Modified",
  [305]: "Use Proxy",
  [400]: "Bad Request",
  [401]: "Unauthorized",
  [402]: "Payment Required",
  [403]: "Forbidden",
  [404]: "Not Found",
  [405]: "Method Not Allowed",
  [406]: "Not Acceptable",
  [407]: "Proxy Authentication Required",
  [408]: "Request Timeout",
  [409]: "Conflict",
  [410]: "Gone",
  [411]: "Length Required",
  [412]: "Precondition Failed",
  [413]: "Request Entity Too Large",
  [414]: "Request-URI Too Long",
  [415]: "Unsupported Media Type",
  [422]: "Unprocessable Entity",
  [429]: "Too Many Requests",
  [499]: "Client has closed connection - Nginx",
  [500]: "Internal Server Error",
  [501]: "Not Implemented",
  [502]: "Bad Gateway",
  [503]: "Service Unavailable",
  [504]: "Gateway Timeout",
  [505]: "HTTP Version Not Supported"
}

ports = {
  acap: 674,
  cap: 1026,
  dict: 2628,
  ftp: 21,
  gopher: 70,
  http: 80,
  https: 443,
  iax: 4569,
  icap: 1344,
  imap: 143,
  ipp: 631,
  ldap: 389,
  mtqp: 1038,
  mupdate: 3905,
  news: 2009,
  nfs: 2049,
  nntp: 119,
  rtsp: 554,
  sip: 5060,
  snmp: 161,
  telnet: 23,
  tftp: 69,
  vemmi: 575,
  afs: 1483,
  jms: 5673,
  rsync: 873,
  prospero: 191,
  videotex: 516
}

default_port = (scheme) -> tostring(ports[scheme]) if ports[scheme]

split = (url, protocol="https?") ->
  return nil, 'missing url parameter' unless url

  scheme, hostp, path, queryp = string.match(url, "(%a*)://([^/]*)([^?#]*)?*(.*)")
  user, pass, port, query, authority, host, fragment = nil, nil, nil, nil, nil, nil, nil

  return nil, 'missing scheme info' unless scheme
  return nil, 'missing host info' unless hostp

  -- parse user pass
  if hostp
    m = string_split(hostp, "@")
    if m[2]
      n = string_split(m[1], ":")
      user = n[1]
      pass = n[2]
      hostp = m[2]

    -- parse port
    authority = hostp
    m = string_split(hostp, ":")
    host = m[1]
    port = m[2]

  if queryp
    m = string_split(queryp, "#")
    query = m[1]
    fragment = m[2]

  if port == nil or port == ""
    port = default_port(scheme)

  return { scheme, user or false, pass or false, host, port, path or nil, query or nil, fragment or nil, authority }

parse = (url, protocol="https?") ->
  parts, err = split(url, protocol)

  return parts, err if err

  {
    scheme: parts[1] or nil,
    user: parts[2] or nil,
    password: parts[3] or nil,
    host: parts[4] or nil,
    port: parts[5] or nil,
    path: parts[6] or nil,
    query: parts[7] or nil,
    fragment: parts[8] or nil,
    authority: parts[9] or nil
  }

compile_pattern = (pattern) ->
  compiled_pattern = {
    original: pattern,
    params: { }
  }

  pattern = pattern\gsub("[%(%)%.%%%+%-%%?%[%^%$%*]", (char) ->
    return "%" .. char unless char == "*"
    ":*"
  )

  pattern = pattern\gsub(':([%w_%*]+)(/?)', (param, slash) ->
    if param == "*"
      table_insert(compiled_pattern.params, "splat")
      return "(.-)" .. slash

    table_insert(compiled_pattern.params, param)
    "([^/?&#]+)" .. slash
  )

  if pattern\sub(-1) ~= "/" do pattern = pattern .. "/"
  compiled_pattern.pattern = "^" .. pattern .. "?$"

  compiled_pattern

extract_parameters = (pattern, matches) ->
  params = { }
  t = pattern.params
  for i=1, #t
    k = t[i]
    if (k == 'splat')
      if not params.splat
        params.splat = {}

      table_insert(params.splat, url_unescape(matches[i]))
    else
      params[k] = url_unescape(matches[i])
      params[k] = matches[i]

  params

match = (pattern, path) ->
  matches = { re_match(path, pattern.pattern) }

  return true, extract_parameters(pattern, matches) if #matches > 0

  false, nil

{ :HTTPPHRASE, :split, :parse, :default_port,
  :compile_pattern, :match, :extract_parameters
}
