-- This deserialiser is from:
-- https://gist.github.com/tylerneylon/59f4bcf316be525b30ab

-- Internal functions.
local function kind_of(obj)
  if type(obj) ~= 'table' then return type(obj) end
  local i = 1
  for _ in pairs(obj) do
    if obj[i] ~= nil then i = i + 1 else return 'table' end
  end
  if i == 1 then return 'table' else return 'array' end
end

local function escape_str(s)
  local in_char  = {'\\', '"', '/', '\b', '\f', '\n', '\r', '\t'}
  local out_char = {'\\', '"', '/',  'b',  'f',  'n',  'r',  't'}
  for i, c in ipairs(in_char) do
    s = string.gsub(s, c, '\\' .. out_char[i])
  end
  return s
end

local function skip_delim(str, pos, delim, err_if_missing)
  pos = pos + string.len(string.match(string.sub(str, pos), '^%s*') or "")
  if string.sub(str, pos, pos) ~= delim then
    if err_if_missing then
      error('Expected ' .. delim .. ' near position ' .. pos)
    end
    return pos, false
  end
  return pos + 1, true
end

local function parse_str_val(str, pos, val)
  val = val or ''
  local early_end_error = 'End of input found while parsing string.'
  if pos > string.len(str) then error(early_end_error) end
  local c = string.sub(str, pos, pos)
  if c == '"'  then return val, pos + 1 end
  if c ~= '\\' then return parse_str_val(str, pos + 1, val .. c) end
  local esc_map = {b = '\b', f = '\f', n = '\n', r = '\r', t = '\t'}
  local nextc = string.sub(str, pos + 1, pos + 1)
  if not nextc then error(early_end_error) end
  return parse_str_val(str, pos + 2, val .. (esc_map[nextc] or nextc))
end

local function parse_num_val(str, pos)
  local num_str = string.match(string.sub(str, pos), '^-?%d+%.?%d*[eE]?[+-]?%d*')
  local val = tonumber(num_str)
  if not val then error('Error parsing number at position ' .. pos .. '.') end
  return val, pos + string.len(num_str)
end

-- Public values and functions.

function stringify(obj, as_key)
  local s = {}
  local kind = kind_of(obj)
  if kind == 'array' then
    if as_key then error('Can\'t encode array as key.') end
    table.insert(s, '[')
    for i, val in ipairs(obj) do
      if i > 1 then table.insert(s, ', ') end
      table.insert(s, stringify(val))
    end
    table.insert(s, ']')
  elseif kind == 'table' then
    if as_key then error('Can\'t encode table as key.') end
    table.insert(s, '{')
    for k, v in pairs(obj) do
      if table.getn(s) > 1 then table.insert(s, ', ') end
      table.insert(s, stringify(k, true))
      table.insert(s, ':')
      table.insert(s, stringify(v))
    end
    table.insert(s, '}')
  elseif kind == 'string' then
    return '"' .. escape_str(obj) .. '"'
  elseif kind == 'number' then
    if as_key then return '"' .. tostring(obj) .. '"' end
    return tostring(obj)
  elseif kind == 'boolean' then
    return tostring(obj)
  elseif kind == 'nil' then
    return 'null'
  else
    error('Unjsonifiable type: ' .. kind .. '.')
  end
  return table.concat(s)
end

null = {}

function parse(str, pos, end_delim)
  pos = pos or 1
  if pos > string.len(str) then error('Reached unexpected end of input.') end
  pos = pos + string.len(string.match(string.sub(str, pos), '^%s*') or "")
  local first = string.sub(str, pos, pos)
  if first == '{' then
    local obj, key, delim_found = {}, true, true
    pos = pos + 1
    while true do
      key, pos = parse(str, pos, '}')
      if key == nil then return obj, pos end
      if not delim_found then error('Comma missing between object items.') end
      pos = skip_delim(str, pos, ':', true)
      obj[key], pos = parse(str, pos)
      pos, delim_found = skip_delim(str, pos, ',')
    end
  elseif first == '[' then
    local arr, val, delim_found = {}, true, true
    pos = pos + 1
    while true do
      val, pos = parse(str, pos, ']')
      if val == nil then return arr, pos end
      if not delim_found then error('Comma missing between array items.') end
      table.insert(arr, val)
      pos, delim_found = skip_delim(str, pos, ',')
    end
  elseif first == '"' then
    return parse_str_val(str, pos + 1)
  elseif first == '-' or string.match(first, '%d') then
    return parse_num_val(str, pos)
  elseif first == end_delim then
    return nil, pos + 1
  else
    local literals = {['true'] = true, ['false'] = false, ['null'] = null}
    for lit_str, lit_val in pairs(literals) do
      local lit_end = pos + string.len(lit_str) - 1
      if string.sub(str, pos, lit_end) == lit_str then return lit_val, lit_end + 1 end
    end
    local pos_info_str = 'position ' .. pos .. ': ' .. string.sub(str, pos, pos + 10)
    error('Invalid json syntax starting at ' .. pos_info_str)
  end
end