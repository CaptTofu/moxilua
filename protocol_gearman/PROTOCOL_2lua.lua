-- Parses gearman PROTOCOL text document into useful lua tables.
--
local lines = {}

local function match(line, ...)
  for i = 1, #arg do
    if string.find(line, "^" .. arg[i]) then
      return true
    end
  end
  return false
end

for line in io.lines("protocol_gearman/PROTOCOL") do
  -- Strip comments, macros defs.
  if line ~= "" and
     match(line,
           "%-%-+$",
           "[%u%_%, ]+$",
           "     %- ",
           "    %- ",
           "[%w%/]+ Requests$",
           "[%w%/]+ Responses$") then
    lines[#lines + 1] = line
  end
end

for i, v in ipairs(lines) do
  lines[i] = string.gsub(lines[i],
                         "^([%u%_, ]+)$",
                         "},\n{ '%1',")
end

local body = table.concat(lines, '\n')

body = string.gsub(body,
  "([%w%/]+) Requests",
  "}}\nrequest['%1'] = {{")

body = string.gsub(body,
  "([%w%/]+) Responses",
  "}}\nresponse['%1'] = {{")

body = string.gsub(body,
  "%-%-+",
  "},\n{")

body = string.gsub(body,
  "     %- None%.",
  "")

body = string.gsub(body,
  "    %- None%.",
  "")

body = string.gsub(body,
  "     %- ([^\n]+)",
  "  {'%1'},")

body = string.gsub(body,
  "    %- ([^\n]+)",
  "  {'%1'},")

print([=[
-- Generated from running 'lua protocol_gearman/PROTOCOL_2lua.lua'
--
PROTOCOL_gearman = {
  request = {},
  response = {}
}

do

local request  = PROTOCOL_gearman.request;
local response = PROTOCOL_gearman.response;
]=])

print('local x = {{')
print(body)
print('}}\n')
print('end')

