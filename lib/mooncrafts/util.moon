----
-- utility functions
-- @module util

-- this module cannot and should not reference log
url              = require "mooncrafts.url"
cjson_safe       = require "cjson.safe"

import concat, insert, sort from table
import char from string
import random, randomseed from math

charset = {}

-- qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890
for i = 48,  57 do insert(charset, char(i))
for i = 65,  90 do insert(charset, char(i))
for i = 97, 122 do insert(charset, char(i))

-- our utils lib, nothing here should depend on ngx
-- for ngx stuff, put it inside ngin.lua file
local *

string_random = (length) ->
  randomseed(os.time())

  return string_random(length - 1) .. charset[random(1, #charset)] if length > 0

  ""

table_pairsByKeys = (t, f) ->
  a = {}
  for n in pairs(t) do insert(a, n)
  sort(a, f)

  i = 0
  iter = () ->
    i = i + 1
    return nil if a[i] == nil
    a[i], t[a[i]]

  iter

--- trim a string.
-- @param str the string
-- @param pattern trim pattern
-- @return trimed string
trim = (str, pattern="%s*") ->
  str = tostring str

  if #str > 200
    str\gsub("^#{pattern}", "")\reverse()\gsub("^#{pattern}", "")\reverse()
  else
    str\match "^#{pattern}(.-)#{pattern}$"

--- sanitize a path.
-- path should not have double quote, single quote, period <br />
-- purposely left casing alone because paths are case-sensitive <br />
-- finally, remove double period and make single forward slash <br />
-- @param str the path
-- @return a sanitized path
path_sanitize = (str) -> (tostring str)\gsub("[^a-zA-Z0-9.-_/\\]", "")\gsub("%.%.+", "")\gsub("//+", "/")\gsub("\\\\+", "/")

url_unescape = (str) -> str\gsub('+', ' ')\gsub("%%(%x%x)", (c) -> return string.char(tonumber(c, 16)))

-- https://stackoverflow.com/questions/2322764/what-characters-must-be-escaped-in-an-http-query-string
url_escape = (str) -> string.gsub(str, "([ /?:@~!$&'()*+,;=%[%]%c])", (c) -> string.format("%%%02X", string.byte(c)))

url_parse = (myurl) -> url.parse(myurl)

url_default_port = (scheme) -> url.default_port(scheme)

-- {
--     [path] = "/test"
--     [scheme] = "http"
--     [host] = "localhost.com"
--     [port] = "8080"
--     [fragment] = "!hash_bang"
--     [query] = "hello=world"
-- }
url_build = (parts, includeQuery=true) ->
  out = parts.path or ""

  out = path_sanitize(out)

  if host = parts.host
    host = "//#{host}"
    host = "#{host}:#{parts.port}" if parts.port
    host = "#{parts.scheme}:#{host}"  if parts.scheme and trim(parts.scheme) ~= ""
    out = "/#{out}" if parts.path and out\sub(1,1) ~= "/"
    out = "#{host}#{out}"

  if includeQuery
    out = "#{out}?#{parts.query}" if parts.query
    out = "#{out}##{parts.fragment}" if parts.fragment

  out


slugify = (str) -> ((tostring str)\gsub("[%s_]+", "-")\gsub("[^%w%-]+", "")\gsub("-+", "-"))\lower!

string_split = url.string_split

json_encodable = (obj, seen={}) ->
  switch type obj
    when "table"
      unless seen[obj]
        seen[obj] = true
        { k, json_encodable(v, seen) for k,v in pairs(obj) when type(k) == "string" or type(k) == "number" }
    when "function", "userdata", "thread"
      nil
    else
      obj

from_json = (obj) -> cjson_safe.decode obj

to_json = (obj) -> cjson_safe.encode json_encodable obj

query_string_encode = (t, sep="&", quote="", escape=url_escape) ->
  query = {}
  keys = {}
  for k in pairs(t) do keys[#keys+1] = tostring(k)
  sort(keys)

  for _, k in ipairs(keys) do
    v = t[k]

    switch type v
      when "table"
        unless seen[v]
          seen[v] = true
          tv = query_string_encode(v, sep, quote, seen)
          v = tv
      when "function", "userdata", "thread"
        nil
      else
        v = escape(tostring(v))

    k = escape(tostring(k))

    if v ~= "" then
      query[#query+1] = string.format('%s=%s', k, quote .. v .. quote)
    else
      query[#query+1] = name

  concat(query, sep)

applyDefaults = (opts, defOpts) ->
  for k, v in pairs(defOpts) do
    if "__" ~= string.sub(k,1,2) then   -- don't clone meta
      opts[k] = v unless opts[k]

  opts

table_extend = (table1, table2) ->
  for k, v in pairs(table2) do
    if (type(table1[k]) == 'table' and type(v) == 'table') then
      table_extend(table1[k], v)
    else
      table1[k] = v

  table1

table_clone = (t, deep=false) ->
  return nil unless ("table"==type(t) or "userdata"==type(t))

  ret = {}
  for k,v in pairs(t) do
    if "__" ~= string.sub(k,1,2) then   -- don't clone meta
      if "table,userdata"\find(type(v)) then
        ret[k] = if deep then v else table_clone(v, deep)
      else
        ret[k] = v

  ret

-- parse connection string into table
string_connection_parse = (str, fieldSep=";", valSep="=") ->
  fields = string_split(str or "", ";")
  rst = {}
  for _, d in ipairs(fields) do
    firstEq = d\find(valSep)
    if (firstEq)
      k = d\sub(1, firstEq - 1)
      v = d\sub(firstEq + 1)
      rst[k] = v

  rst

{ :url_escape, :url_unescape, :url_parse, :url_build, :url_default_port,
  :trim, :path_sanitize, :slugify, :table_sort_keys,
  :json_encodable, :from_json, :to_json, :table_clone, :table_extend,
  :table_pairsByKeys, :query_string_encode, :applyDefaults,
  :string_split, :string_connection_parse, :string_random,
}
