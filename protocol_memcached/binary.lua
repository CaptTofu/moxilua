local binary_lookup = {
  response_status = {},
  command = {}
}

for k, v in pairs(binary_lookup) do
  for name, num in pairs(memcached_protocol_binary[k]) do
    binary_lookup[k][num] = name
  end

  if false then
    print('----------------------')
    for k, v in pairs(binary_lookup[k]) do
      print(k, v)
    end
  end
end

memcached_protocol_binary.command_vocal = {}
memcached_protocol_binary.command_quiet = {}

binary_lookup.command_vocal = {}
binary_lookup.command_quiet = {}

for k, v in pairs(memcached_protocol_binary.command) do
  if string.sub(k, -1) ~= 'Q' then
    memcached_protocol_binary.command_vocal[k] = v
    binary_lookup.command_vocal[v] = k
  else
    local x = string.sub(k, 1, -2)
    memcached_protocol_binary.command_quiet[x] = v
    binary_lookup.command_quiet[v] = x
  end
end

if false then
  print('----------------------')
  for k, v in pairs(binary_lookup.command_vocal) do
    print(k, v)
  end
  print('----------------------')
  for k, v in pairs(binary_lookup.command_quiet) do
    print(k, v)
  end
end
