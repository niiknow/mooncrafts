-- custom url parsing implementation
-- since there are so many that does not meet requirements - wtf?

import insert from table

local *

re_match = string.match
tonumber = tonumber
setmetatable = setmetatable

string_split = (str, sep, dest={}) ->
  str = tostring str
  for str in string.gmatch(str, "([^" .. (sep or "%s") .. "]+)") do
    insert(dest, str)

  dest

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

{ :split, :parse, :default_port, :string_split }
