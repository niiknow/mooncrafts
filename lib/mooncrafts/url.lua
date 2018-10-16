local insert
insert = table.insert
local re_match, tonumber, setmetatable, string_split, ports, default_port, split, parse
re_match = string.match
tonumber = tonumber
setmetatable = setmetatable
string_split = function(str, sep, dest)
  if dest == nil then
    dest = { }
  end
  str = tostring(str)
  for str in string.gmatch(str, "([^" .. (sep or "%s") .. "]+)") do
    insert(dest, str)
  end
  return dest
end
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
return {
  split = split,
  parse = parse,
  default_port = default_port,
  string_split = string_split
}
