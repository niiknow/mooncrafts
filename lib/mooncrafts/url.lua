local util = require("mooncrafts.util")
local log = require("mooncrafts.log")
local insert
insert = table.insert
local url_unescape
url_unescape = util.url_unescape
local re_match, tonumber, setmetatable, string_split, table_insert, string_sub, trim, url_escape, string_join, string_gsub, strlen, ports, default_port, split, parse, compile_pattern, extract_parameters, match_pattern, build_with_splats
re_match = string.match
tonumber = tonumber
setmetatable = setmetatable
string_split = util.string_split
table_insert = table.insert
string_sub = string.sub
trim = util.trim
url_escape = util.url_escape
string_join = table.concat
string_gsub = string.gsub
strlen = string.len
ports = {
  acap = 674,
  cap = 1026,
  dict = 2628,
  ftp = 21,
  gopher = 70,
  http = 80,
  https = 443,
  iax = 4569,
  icap = 1344,
  imap = 143,
  ipp = 631,
  ldap = 389,
  mtqp = 1038,
  mupdate = 3905,
  news = 2009,
  nfs = 2049,
  nntp = 119,
  rtsp = 554,
  sip = 5060,
  snmp = 161,
  telnet = 23,
  tftp = 69,
  vemmi = 575,
  afs = 1483,
  jms = 5673,
  rsync = 873,
  prospero = 191,
  videotex = 516
}
default_port = function(scheme)
  if ports[scheme] then
    return tostring(ports[scheme])
  end
end
split = function(url, pathOnly)
  if pathOnly == nil then
    pathOnly = false
  end
  assert(url, "url parameter is required")
  url = trim(url)
  local scheme, hostp, path, queryp = string.match(url, "(%a*)://([^/]*)([^?#]*)?*(.*)")
  local user, pass, port, query, authority, host, fragment = nil, nil, nil, nil, nil, nil, nil
  if scheme == nil and pathOnly then
    assert(string_sub(url, 1, 1) == "/", "path must starts with /")
  else
    assert(scheme, "parsing of url must have scheme")
    assert(hostp, "parsing of url must have host and/or authority")
  end
  if hostp then
    local m = string_split(hostp, "@")
    if m[2] then
      local n = string_split(m[1], ":")
      user = n[1]
      pass = n[2]
      hostp = m[2]
    end
    authority = hostp
    m = string_split(hostp, ":")
    host = m[1]
    port = m[2]
  else
    path, queryp = string.match(url, "([^?#]*)?*(.*)")
  end
  local pathAndQuery = path
  if queryp and strlen(queryp) > 0 then
    local m = string_split(queryp, "#")
    query = m[1]
    fragment = m[2]
    pathAndQuery = path .. "?" .. queryp
  end
  if port == nil or port == "" then
    port = default_port(scheme or "https")
  end
  if (host and port) then
    authority = tostring(host) .. ":" .. tostring(port)
  end
  return {
    scheme,
    user or false,
    pass or false,
    host,
    port,
    path or nil,
    query or nil,
    fragment or nil,
    authority or nil,
    pathAndQuery
  }
end
parse = function(url, pathOnly)
  if pathOnly == nil then
    pathOnly = false
  end
  local parts, err = split(url, pathOnly)
  if err then
    return parts, err
  end
  local rst = {
    scheme = parts[1] or nil,
    user = parts[2] or nil,
    password = parts[3] or nil,
    host = parts[4] or nil,
    port = parts[5] or nil,
    path = parts[6] or nil,
    query = parts[7] or nil,
    fragment = parts[8] or nil,
    authority = parts[9] or nil,
    pathAndQuery = parts[10] or nil
  }
  rst.original = url
  if (rst.scheme and rst.authority) then
    rst.authorativeUrl = tostring(rst.scheme) .. "://" .. tostring(rst.authority) .. tostring(rst.pathAndQuery)
    rst.fullUrl = tostring(rst.scheme) .. "://" .. tostring(rst.host) .. tostring(rst.pathAndQuery)
  end
  return rst
end
compile_pattern = function(pattern)
  local uri = parse(pattern, true)
  local compiled_pattern = {
    original = pattern,
    params = { }
  }
  pattern = pattern:gsub("[%(%)%.%%%+%-%%?%[%^%$%*]", function(char)
    if not (char == "*") then
      return "%" .. char
    end
    return ":*"
  end)
  pattern = pattern:gsub(':([a-z_%*]+)(/?)', function(param, slash)
    if param == "*" then
      table_insert(compiled_pattern.params, "splat")
      return "(.-)" .. slash
    end
    table_insert(compiled_pattern.params, param)
    return "([^/?&#]+)" .. slash
  end)
  if pattern:sub(-1) ~= "/" then
    do
      pattern = pattern .. "/"
    end
  end
  if compiled_pattern.original:sub(-1) ~= "/" then
    pattern = pattern:sub(1, -2)
  end
  if compiled_pattern.original:sub(-1) ~= "*" then
    pattern = pattern .. "$"
  end
  compiled_pattern.pattern = pattern
  return compiled_pattern
end
extract_parameters = function(pattern, matches)
  local params = { }
  local t = pattern.params
  for i = 1, #t do
    local k = t[i]
    if (k == 'splat') then
      if not params.splat then
        params.splat = { }
      end
      table_insert(params.splat, url_unescape(matches[i]))
    else
      params[k] = url_unescape(matches[i])
      params[k] = matches[i]
    end
  end
  return params
end
match_pattern = function(reqUrl, pattern)
  if pattern.original:find('https?') == nil then
    if reqUrl:find('https?') ~= nil then
      reqUrl = parse(reqUrl, true).pathAndQuery
    end
  end
  local matches = {
    re_match(reqUrl, pattern.pattern)
  }
  if #matches > 0 then
    return true, extract_parameters(pattern, matches)
  end
  return false, nil
end
build_with_splats = function(dest, splats)
  assert(dest, "dest url is required")
  assert(splats, "splats are required")
  local url = dest
  for k, v in pairs(splats) do
    url = string_gsub(url, ":" .. k, v)
  end
  return url
end
return {
  split = split,
  parse = parse,
  default_port = default_port,
  compile_pattern = compile_pattern,
  match_pattern = match_pattern,
  extract_parameters = extract_parameters,
  build_with_splats = build_with_splats
}
