local cjson_safe = require("cjson.safe")
local concat, insert, sort
do
  local _obj_0 = table
  concat, insert, sort = _obj_0.concat, _obj_0.insert, _obj_0.sort
end
local char
char = string.char
local random, randomseed
do
  local _obj_0 = math
  random, randomseed = _obj_0.random, _obj_0.randomseed
end
local charset = { }
for i = 48, 57 do
  insert(charset, char(i))
end
for i = 65, 90 do
  insert(charset, char(i))
end
for i = 97, 122 do
  insert(charset, char(i))
end
local string_sub, string_gmatch, string_random, trim, starts_with, ends_with, path_sanitize, url_unescape, url_escape, url_build, slugify, string_split, json_encodable, from_json, to_json, query_string_encode, applyDefaults, table_extend, table_clone, string_connection_parse
string_sub = string.sub
string_gmatch = string.gmatch
string_random = function(length)
  randomseed(os.time())
  if length > 0 then
    return string_random(length - 1) .. charset[random(1, #charset)]
  end
  return ""
end
trim = function(str, pattern)
  if pattern == nil then
    pattern = "%s*"
  end
  str = tostring(str)
  if #str > 200 then
    return str:gsub("^" .. tostring(pattern), ""):reverse():gsub("^" .. tostring(pattern), ""):reverse()
  else
    return str:match("^" .. tostring(pattern) .. "(.-)" .. tostring(pattern) .. "$")
  end
end
starts_with = function(str, start)
  return {
    str = sub(1, #start) == start
  }
end
ends_with = function(str, ending)
  return ending == "" or {
    str = sub(-#ending) == ending
  }
end
path_sanitize = function(str)
  return (tostring(str)):gsub("[^a-zA-Z0-9.-_/\\]", ""):gsub("%.%.+", ""):gsub("//+", "/"):gsub("\\\\+", "/")
end
url_unescape = function(str)
  return str:gsub('+', ' '):gsub("%%(%x%x)", function(c)
    return string.char(tonumber(c, 16))
  end)
end
url_escape = function(str)
  return string.gsub(str, "([ /?:@~!$&'()*+,;=%[%]%c])", function(c)
    return string.format("%%%02X", string.byte(c))
  end)
end
url_build = function(parts, includeQuery)
  if includeQuery == nil then
    includeQuery = true
  end
  local out = parts.path or ""
  out = path_sanitize(out)
  do
    local host = parts.host
    if host then
      host = "//" .. tostring(host)
      if parts.port then
        host = tostring(host) .. ":" .. tostring(parts.port)
      end
      if parts.scheme and trim(parts.scheme) ~= "" then
        host = tostring(parts.scheme) .. ":" .. tostring(host)
      end
      if parts.path and out:sub(1, 1) ~= "/" then
        out = "/" .. tostring(out)
      end
      out = tostring(host) .. tostring(out)
    end
  end
  if includeQuery then
    if parts.query then
      out = tostring(out) .. "?" .. tostring(parts.query)
    end
    if parts.fragment then
      out = tostring(out) .. tostring(parts.fragment)
    end
  end
  return out
end
slugify = function(str)
  return ((tostring(str)):gsub("[%s_]+", "-"):gsub("[^%w%-]+", ""):gsub("-+", "-")):lower()
end
string_split = function(str, sep, dest)
  if dest == nil then
    dest = { }
  end
  str = tostring(str)
  for str in string_gmatch(str, "([^" .. (sep or "%s") .. "]+)") do
    insert(dest, str)
  end
  return dest
end
json_encodable = function(obj, seen)
  if seen == nil then
    seen = { }
  end
  local _exp_0 = type(obj)
  if "table" == _exp_0 then
    if not (seen[obj]) then
      seen[obj] = true
      local _tbl_0 = { }
      for k, v in pairs(obj) do
        if type(k) == "string" or type(k) == "number" then
          _tbl_0[k] = json_encodable(v, seen)
        end
      end
      return _tbl_0
    end
  elseif "function" == _exp_0 or "userdata" == _exp_0 or "thread" == _exp_0 then
    return nil
  else
    return obj
  end
end
from_json = function(obj)
  return cjson_safe.decode(obj)
end
to_json = function(obj)
  return cjson_safe.encode(json_encodable(obj))
end
query_string_encode = function(t, sep, quote, escape)
  if sep == nil then
    sep = "&"
  end
  if quote == nil then
    quote = ""
  end
  if escape == nil then
    escape = url_escape
  end
  local query = { }
  local keys = { }
  for k in pairs(t) do
    keys[#keys + 1] = tostring(k)
  end
  sort(keys)
  for i = 1, #keys do
    local k = keys[i]
    local v = t[k]
    local _exp_0 = type(v)
    if "table" == _exp_0 then
      if not (seen[v]) then
        seen[v] = true
        local tv = query_string_encode(v, sep, quote, seen)
        v = tv
      end
    elseif "function" == _exp_0 or "userdata" == _exp_0 or "thread" == _exp_0 then
      local _ = nil
    else
      v = escape(tostring(v))
    end
    k = escape(tostring(k))
    if v == "" then
      query[#query + 1] = name
    else
      query[#query + 1] = string.format('%s=%s', k, quote .. v .. quote)
    end
  end
  return concat(query, sep)
end
applyDefaults = function(opts, defOpts)
  for k, v in pairs(defOpts) do
    if "__" ~= string_sub(k, 1, 2) then
      if not (opts[k]) then
        opts[k] = v
      end
    end
  end
  return opts
end
table_extend = function(table1, table2)
  for k, v in pairs(table2) do
    if (type(table1[k]) == 'table' and type(v) == 'table') then
      table_extend(table1[k], v)
    else
      table1[k] = v
    end
  end
  return table1
end
table_clone = function(t, deep)
  if deep == nil then
    deep = false
  end
  if not (("table" == type(t) or "userdata" == type(t))) then
    return nil
  end
  local ret = { }
  for k, v in pairs(t) do
    if "__" ~= string_sub(k, 1, 2) then
      if (type(v) == "userdata" or type(v) == "table") then
        if deep then
          ret[k] = v
        else
          ret[k] = table_clone(v, deep)
        end
      else
        ret[k] = v
      end
    end
  end
  return ret
end
string_connection_parse = function(str, fieldSep, valSep)
  if fieldSep == nil then
    fieldSep = ";"
  end
  if valSep == nil then
    valSep = "="
  end
  local rst = { }
  local fields = string_split(str or "", ";")
  for i = 1, #fields do
    local d = fields[i]
    local firstEq = d:find(valSep)
    if (firstEq) then
      local k = d:sub(1, firstEq - 1)
      local v = d:sub(firstEq + 1)
      rst[k] = v
    end
  end
  return rst
end
return {
  url_escape = url_escape,
  url_unescape = url_unescape,
  url_build = url_build,
  trim = trim,
  path_sanitize = path_sanitize,
  slugify = slugify,
  table_sort_keys = table_sort_keys,
  json_encodable = json_encodable,
  from_json = from_json,
  to_json = to_json,
  table_clone = table_clone,
  table_extend = table_extend,
  query_string_encode = query_string_encode,
  applyDefaults = applyDefaults,
  string_split = string_split,
  string_connection_parse = string_connection_parse,
  string_random = string_random,
  starts_with = starts_with,
  ends_with
}
