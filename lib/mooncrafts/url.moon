-- custom url parsing implementation
-- since there are so many that does not meet requirements - wtf?
util = require "mooncrafts.util"
log  = require "mooncrafts.log"

import insert from table
import url_unescape from util


local *

re_match     = string.match
tonumber     = tonumber
setmetatable = setmetatable
string_split = util.string_split
table_insert = table.insert
string_sub   = string.sub
trim         = util.trim
url_escape   = util.url_escape
string_join  = table.concat
string_gsub  = string.gsub
strlen       = string.len

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

split = (url, pathOnly=false) ->
  assert(url, "url parameter is required")
  url = trim(url)

  scheme, hostp, path, queryp = string.match(url, "(%a*)://([^/]*)([^?#]*)?*(.*)")
  user, pass, port, query, authority, host, fragment = nil, nil, nil, nil, nil, nil, nil


  if scheme == nil and pathOnly
    assert(string_sub(url, 1, 1) == "/", "path must starts with /")
  else
    assert(scheme, "parsing of url must have scheme")
    assert(hostp, "parsing of url must have host and/or authority")

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
  else
    path, queryp = string.match(url, "([^?#]*)?*(.*)")

  pathAndQuery = path

  if queryp
    m = string_split(queryp, "#")
    query = m[1]
    fragment = m[2]
    pathAndQuery = path .. "?" .. queryp

  port = default_port(scheme)  if port == nil or port == ""

  return { scheme, user or false, pass or false, host, port, path or nil, query or nil, fragment or nil, authority or nil, pathAndQuery }

parse = (url, pathOnly=false) ->
  parts, err = split(url, pathOnly)

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
    authority: parts[9] or nil,
    pathAndQuery: parts[10] or nil
  }

compile_pattern = (pattern) ->
  uri     = parse(pattern, true)

  compiled_pattern = {
    original: pattern,
    params: { }
  }

  pattern = pattern\gsub("[%(%)%.%%%+%-%%?%[%^%$%*]", (char) ->
    return "%" .. char unless char == "*"
    ":*"
  )

  pattern = pattern\gsub(':([a-z_%*]+)(/?)', (param, slash) ->
    if param == "*"
      table_insert(compiled_pattern.params, "splat")
      return "(.-)" .. slash

    table_insert(compiled_pattern.params, param)
    "([^/?&#]+)" .. slash
  )

  if pattern\sub(-1) ~= "/" do pattern = pattern .. "/"

  -- if original url does not ends with forward slash, remove
  if compiled_pattern.original\sub(-1) ~= "/"
    pattern = pattern\sub(1, -2)

  compiled_pattern.pattern = pattern
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

match_pattern = (path, pattern) ->

  -- if pattern is not full url
  if pattern.original\find('https?') == nil
    -- and path is full, then just use path and query
    if path\find('https?')
      path = parse(path, true).pathAndQuery

  matches = { re_match(path, pattern.pattern) }

  return true, extract_parameters(pattern, matches) if #matches > 0

  false, nil

build_with_splats = (dest, splats) ->
  assert(dest, "dest url is required")
  assert(splats, "splats are required")

  -- add spaces so we can do split and join
  url = dest

  -- split url by each params
  for k, v in pairs(splats)
    url = string_gsub(url, ":" .. k, v)

  url

{ :HTTPPHRASE, :split, :parse, :default_port,
  :compile_pattern, :match_pattern, :extract_parameters,
  :build_with_splats
}
