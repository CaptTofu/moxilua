-- Parses protocol_binary.h into useful lua tables.
--
local lines = {}

local function match(line, ...)
  for i = 1, #arg do
    if string.find(line, "^ *" .. arg[i]) then
      return true
    end
  end
  return false
end

for line in io.lines("protocol_binary.h") do
  -- Strip comments, macros defs.
  if line ~= "" and
     not match(line,
               "/%*",
               " %*",
               " %*/",
               "#ifdef ",
               "#ifndef ",
               "#endif",
               "#define ",
               "#include ",
               'extern "C"',
               "{") then
    lines[#lines + 1] = line
  end
end

local body = table.concat(lines, '\n')

body = string.gsub(body,
                   "(typedef enum)( {[^}]+}) ([^;]+);",
                   "%3 =%2,")

body = string.gsub(body, "PROTOCOL_BINARY_", "")
body = string.gsub(body, "protocol_binary_", "")
body = string.gsub(body, "RESPONSE_", "")
body = string.gsub(body, "CMD_", "")

-- Replaces "uint8_t magic;" with "uint_t(8, 'magic'),"
--
body = string.gsub(body, "uint(%d+)_t ([^;]+);", "uint_t(%1, '%2'),")

body = string.gsub(body,
                   "struct {(.-)(\n    }) ([%w_]-);",
                   "%3 = {%1%2,")

body = string.gsub(body,
                   "struct {(.-)(\n      }) ([%w_]-);",
                   "%3 = {%1%2,")

body = string.gsub(body,
                   "typedef union {(.-)(\n  }) ([%w_]-);",
                   "%3 = {%1%2,")

body = string.gsub(body,
                   "typedef ([%w_]-) ([%w_]-);",
                   "%2 = '%1',")

body = string.gsub(body,
                   "([%w_]-) header;",
                   "header = '%1',")

print([=[
-- generated from 'lua protocol_binary_h2lua.lua'
--
local function uint_t(size, name)
  return { name = name, size = n }
end
]=])

print("memcached_protocol_binary = {")
print(body)

