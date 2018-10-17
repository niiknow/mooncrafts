local util = require("mooncrafts.util")
local insert
insert = table.insert
local url_unescape
url_unescape = util.url_unescape
local re_match, tonumber, setmetatable, string_split, table_insert, ports, HTTPPHRASE, default_port, split, parse, compile_pattern, extract_parameters, match
re_match = string.match
tonumber = tonumber
setmetatable = setmetatable
string_split = util.string_split
table_insert = table.insert
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
HTTPPHRASE = {
  [100] = "Continue",
  [101] = "Switching Protocols",
  [200] = "OK",
  [201] = "Created",
  [202] = "Accepted",
  [203] = "Non-Authoritative Information",
  [204] = "No Content",
  [205] = "Reset Content",
  [206] = "Partial Content",
  [300] = "Multiple Choices",
  [301] = "Moved Permanently",
  [302] = "Moved Temporarily",
  [303] = "See Other",
  [304] = "Not Modified",
  [305] = "Use Proxy",
  [400] = "Bad Request",
  [401] = "Unauthorized",
  [402] = "Payment Required",
  [403] = "Forbidden",
  [404] = "Not Found",
  [405] = "Method Not Allowed",
  [406] = "Not Acceptable",
  [407] = "Proxy Authentication Required",
  [408] = "Request Timeout",
  [409] = "Conflict",
  [410] = "Gone",
  [411] = "Length Required",
  [412] = "Precondition Failed",
  [413] = "Request Entity Too Large",
  [414] = "Request-URI Too Long",
  [415] = "Unsupported Media Type",
  [422] = "Unprocessable Entity",
  [429] = "Too Many Requests",
  [499] = "Client has closed connection - Nginx",
  [500] = "Internal Server Error",
  [501] = "Not Implemented",
  [502] = "Bad Gateway",
  [503] = "Service Unavailable",
  [504] = "Gateway Timeout",
  [505] = "HTTP Version Not Supported"
}
default_port = function(scheme)
  if ports[scheme] then
    return tostring(ports[scheme])
  end
end
split = function(url, protocol)
  if protocol == nil then
    protocol = "https?"
  end
  if not (url) then
    return nil, 'missing url parameter'
  end
  local scheme, hostp, path, queryp = string.match(url, "(%a*)://([^/]*)([^?#]*)?*(.*)")
  local user, pass, port, query, authority, host, fragment = nil, nil, nil, nil, nil, nil, nil
  if not (scheme) then
    return nil, 'missing scheme info'
  end
  if not (hostp) then
    return nil, 'missing host info'
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
  end
  if queryp then
    local m = string_split(queryp, "#")
    query = m[1]
    fragment = m[2]
  end
  if port == nil or port == "" then
    port = default_port(scheme)
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
    authority
  }
end
parse = function(url, protocol)
  if protocol == nil then
    protocol = "https?"
  end
  local parts, err = split(url, protocol)
  if err then
    return parts, err
  end
  return {
    scheme = parts[1] or nil,
    user = parts[2] or nil,
    password = parts[3] or nil,
    host = parts[4] or nil,
    port = parts[5] or nil,
    path = parts[6] or nil,
    query = parts[7] or nil,
    fragment = parts[8] or nil,
    authority = parts[9] or nil
  }
end
compile_pattern = function(pattern)
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
  pattern = pattern:gsub(':([%w_%*]+)(/?)', function(param, slash)
    if param == "*" then
      table_insert(compiled_pattern.params, "splat")
      return "(.-)" .. slash
    end
    table_insert(compiled_pattern.params, param)
    return "([^/?&#]+)" .. slash
  end)
  if pattern:sub(-1) ~= "/" then
    pattern = pattern .. "/"
  end
  compiled_pattern.pattern = "^" .. pattern .. "?$"
  return compiled_pattern
end
extract_parameters = function(pattern, matches)
  local params = { }
  for i, k in ipairs(pattern.params) do
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
match = function(pattern, path)
  local matches = {
    re_match(path, pattern.pattern)
  }
  if #matches > 0 then
    return true, extract_parameters(pattern, matches)
  end
  return false, nil
end
return {
  split = split,
  parse = parse,
  default_port = default_port,
  compile_pattern = compile_pattern,
  match = match,
  extract_parameters = extract_parameters,
  HTTPPHRASE = HTTPPHRASE
}
