-- More post-processing on memcached_protocol_binary.
--
memcached_protocol_binary_lookup = {
  response_status = {},
  command = {}
}

local blook = memcached_protocol_binary_lookup

-- Allow lookup by number.
--
for k, v in pairs(blook) do
  for name, num in pairs(memcached_protocol_binary[k]) do
    blook[k][num] = name
  end

  if false then
    print('----------------------')
    for k, v in pairs(blook[k]) do
      print(k, v)
    end
  end
end

-- Allow lookup by vocal vs quiet commands.
--
memcached_protocol_binary.command_vocal = {}
memcached_protocol_binary.command_quiet = {}

blook.command_vocal = {}
blook.command_quiet = {}

for k, v in pairs(memcached_protocol_binary.command) do
  if string.sub(k, -1) ~= 'Q' then
    memcached_protocol_binary.command_vocal[k] = v
    blook.command_vocal[v] = k
  else
    local x = string.sub(k, 1, -2)
    memcached_protocol_binary.command_quiet[x] = v
    blook.command_quiet[v] = x
  end
end

if false then
  print('----------------------')
  for k, v in pairs(blook.command_vocal) do
    print(k, v)
  end
  print('----------------------')
  for k, v in pairs(blook.command_quiet) do
    print(k, v)
  end
end

-- Header sizes
--
for _, name in ipairs({ 'request', 'response' }) do
  local sum_bytes = 0
  for i, v in ipairs(memcached_protocol_binary[name .. '_header'][name]) do
    sum_bytes = sum_bytes + v.num_bytes
  end
  memcached_protocol_binary[name .. '_header_num_bytes'] = sum_bytes
end

