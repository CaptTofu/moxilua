-- More post-processing on memcached_protocol_binary.
--
memcached_protocol_binary.type = {
  REQ = 'request',
  RES = 'response',
  request = 'REQ',
  response = 'RES'
}

memcached_protocol_binary.magic.request =
  memcached_protocol_binary.magic.REQ

memcached_protocol_binary.magic.response =
  memcached_protocol_binary.magic.RES

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

-- Header sizes, fields and field indexes
--
for _, name in ipairs({ 'request', 'response' }) do
  local header_field = {}
  local header_field_index = {}
  memcached_protocol_binary[name .. '_header_field']       = header_field
  memcached_protocol_binary[name .. '_header_field_index'] = header_field_index
  local sum_bytes = 0
  for i, v in ipairs(memcached_protocol_binary[name .. '_header'][name]) do
    v.index = sum_bytes + 1
    header_field[v.name] = v
    header_field_index[v.name] = v.index
    sum_bytes = sum_bytes + v.num_bytes
  end
  memcached_protocol_binary[name .. '_header_num_bytes'] = sum_bytes
end

function TEST_mpb_post()
  local mpb = memcached_protocol_binary
  assert(mpb.pack)
  assert(mpb.response_header_num_bytes == 24)
  assert(mpb.request_header_field_index.magic == 1)
  assert(mpb.response_header_field_index.magic == 1)
  assert(mpb.request_header_field_index.opcode == 2)
  assert(mpb.response_header_field_index.opcode == 2)
end
