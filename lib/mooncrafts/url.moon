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
  user, pass, port, query, authority, host, fragment = nil, nil, nil, nil, nil, nil, ""

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

  if queryp and strlen(queryp) > 0
    m = string_split(queryp, "#")
    query = m[1]
    fragment = if m[2] then "#" .. m[2] else ""
    pathAndQuery = path .. "?" .. queryp

  port      = default_port(scheme or "https") if port == nil or port == ""
  authority = "#{host}:#{port}" if (host and port)

  return { scheme, user or false, pass or false, host, port, path or nil, query or nil, fragment, authority or nil, pathAndQuery }

parse = (url, pathOnly=false) ->
  parts, err = split(url, pathOnly)

  return parts, err if err

  rst = {
    scheme: parts[1] or nil,
    user: parts[2] or nil,
    password: parts[3] or nil,
    host: parts[4] or nil,
    port: parts[5] or nil,
    path: parts[6] or nil,
    query: parts[7] or nil,
    fragment: parts[8],
    authority: parts[9] or nil,
    path_and_query: parts[10]
  }

  rst.original = url

  if (rst.scheme and rst.authority)
    rst.sign_url = "#{rst.scheme}://#{rst.authority}#{rst.path_and_query}"
    rst.full_url = "#{rst.scheme}://#{rst.host}#{rst.path_and_query}"

  rst

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

  if compiled_pattern.original\sub(-1) ~= "*"
    pattern = pattern .. "$"

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

match_pattern = (reqUrl, pattern) ->

  -- if pattern is not full url
  if pattern.original\find('https?') == nil
    -- and path is full, then just use path and query
    if reqUrl\find('https?') ~= nil
      reqUrl = parse(reqUrl, true).path_and_query

  matches = { re_match(reqUrl, pattern.pattern) }

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

{ :split, :parse, :default_port, :compile_pattern, :match_pattern,
  :extract_parameters, :build_with_splats
}
