-- Helper functions to create/process memcached binary protocol packets.
--
local mpb = memcached_protocol_binary

------------------------------------------------------

-- Creates array of bytes from an input integer x.
-- Highest order bytes comes first (network byte ordering).
--
local function network_bytes_array(x, num_bytes)
  local a = {}
  for i = num_bytes, 1, -1 do
    a[i] = math.mod(x, 0x0100) -- lua has no bitmask/shift operators.
    x = math.floor(x / 0x0100)
  end
  return a -- returns array of bytes numbers, highest order first.
end

-- Multiple return values of network ordered bytes from an input integer x.
-- Highest order bytes comes first (network byte ordering).
--
-- For example, you can: string.char(network_bytes(0x123, 4))
--
local function network_bytes(x, num_bytes)
  return unpack(network_bytes_array(x, num_bytes))
end

-- Converts array of network ordered bytes to a number.
--
local function network_bytes_to_number(arr, from, num_bytes)
  assert(num_bytes >= 1 and num_bytes <= 4)

  local x = 0

  for i = 1, num_bytes do
    x = x * 0x0100
    x = x + math.mod(arr[i + from - 1] or 0, 0x0100)
  end

  return x
end

------------------------------------------------------

local function print_bytes(s)
  local n = string.len(s)
  local i = 1
  while i < n do
    print("  " ..
          string.format('x%2x ', string.byte(s, i + 0)) ..
          string.format('x%2x ', string.byte(s, i + 1)) ..
          string.format('x%2x ', string.byte(s, i + 2)) ..
          string.format('x%2x ', string.byte(s, i + 3)))
    i = i + 4
  end
end

------------------------------------------------------

local function create_header(type, cmd,
                             key, ext, datatype, statusOrReserved, data,
                             opaque, cas)
  local keylen = 0
  if key then
    keylen = string.len(key)
  end

  local extlen = 0
  if ext then
    extlen = string.len(ext)
  end

  local datalen = 0
  if data then
    datalen = string.len(data)
  end

  bodylen = keylen + extlen + datalen

  statusOrReserved = statusOrReserved or 0

  local a = {}
  local x = mpb[type .. '_header_field_index']

  a[x.magic]  = mpb.magic[type]
  a[x.opcode] = mpb.command[cmd]

  a[x.keylen], a[x.keylen + 1] = network_bytes(keylen, 2)

  a[x.extlen]   = extlen or 0
  a[x.datatype] = datatype or 0

  if type == 'request' then
    a[x.reserved], a[x.reserved + 1] = network_bytes(statusOrReserved, 2)
  else
    a[x.status], a[x.status + 1] = network_bytes(statusOrReserved, 2)
  end

  a[x.bodylen], a[x.bodylen + 1], a[x.bodylen + 2], a[x.bodylen + 3] =
    network_bytes(bodylen, 4)

  if opaque then
    a[x.opaque + 0] = string.byte(opaque, 1)
    a[x.opaque + 1] = string.byte(opaque, 2)
    a[x.opaque + 2] = string.byte(opaque, 3)
    a[x.opaque + 3] = string.byte(opaque, 4)
  else
    a[x.opaque + 0] = 0
    a[x.opaque + 1] = 0
    a[x.opaque + 2] = 0
    a[x.opaque + 3] = 0
  end

  if cas then
    a[x.cas + 0] = string.byte(cas, 1)
    a[x.cas + 1] = string.byte(cas, 2)
    a[x.cas + 2] = string.byte(cas, 3)
    a[x.cas + 3] = string.byte(cas, 4)
    a[x.cas + 4] = string.byte(cas, 5)
    a[x.cas + 5] = string.byte(cas, 6)
    a[x.cas + 6] = string.byte(cas, 7)
    a[x.cas + 7] = string.byte(cas, 8)
  else
    a[x.cas + 0] = 0
    a[x.cas + 1] = 0
    a[x.cas + 2] = 0
    a[x.cas + 3] = 0
    a[x.cas + 4] = 0
    a[x.cas + 5] = 0
    a[x.cas + 6] = 0
    a[x.cas + 7] = 0
  end

  return string.char(unpack(a))
end

------------------------------------------------------

local function create_request(cmd,
                              key, ext, datatype, statusOrReserved, data,
                              opaque, cas)
  local h = create_header('request', cmd,
                          key, ext, datatype, statusOrReserved, data,
                          opaque, cas)
  return h .. (ext or "") .. (key or "") .. (data or "")
end

local function create_response(cmd,
                               key, ext, datatype, statusOrReserved, data,
                               opaque, cas)
  local h = create_header('response', cmd,
                          key, ext, datatype, statusOrReserved, data,
                          opaque, cas)
  return h .. (ext or "") .. (key or "") .. (data or "")
end

------------------------------------------------------

local function create_request_simple(cmd, key, ext, data, cas)
   return create_request(cmd, key, ext, 0, 0, data, nil, cas)
end

------------------------------------------------------

local function recv_message(conn, type)
  local hdr, err = sock_recv(conn, mpb[type .. "_header_num_bytes"])
  if not hdr then
    return hdr, err
  end

  local fh = mpb[type .. "_header_field"]
  local fx = mpb[type .. "_header_field_index"]

  if string.byte(hdr, fx.magic) ~= mpb.magic[type] then
    return nil
  end

  local opcode = string.byte(hdr, fx.opcode)

  local keylen = network_bytes_to_number(hdr,
                                         fx.keylen,
                                         fh.keylen.num_bytes)
  local extlen = network_bytes_to_number(hdr,
                                         fx.extlen,
                                         fh.extlen.num_bytes)
  local bodylen = network_bytes_to_number(hdr,
                                          fx.bodylen,
                                          fh.bodylen.num_bytes)

  local datalen = bodylen - (keylen + extlen)
  if datalen < 0 then
    return nil
  end

  local ext = nil
  if extlen > 0 then
    ext, err = sock_recv(conn, extlen)
    if not ext then
      return ext, err
    end
  end

  local key = nil
  if keylen > 0 then
    key, err = sock_recv(conn, keylen)
    if not key then
      return key, err
    end
  end

  local data = nil
  if datalen > 0 then
    data, err = sock_recv(conn, datalen)
    if not data then
      return data, err
    end
  end

  return hdr, err, key, ext, data
end

------------------------------------------------------

local function recv_request(conn)
  return recv_request(conn, 'request')
end

local function recv_response(conn)
  return recv_message(conn, 'response')
end

------------------------------------------------------

local function opcode(hdr, type)
  local fx = mpb[type .. '_header_field_index']

  return string.byte(hdr, fx.opcode)
end

local function status(hdr)
  local fh = mpb.response_header_field
  local fx = mpb.response_header_field_index

  return network_bytes_to_number(hdr,
                                 fx.status,
                                 fh.status.num_bytes)
end

------------------------------------------------------

mpb.pack = {
  network_bytes           = network_bytes,
  network_bytes_array     = network_bytes_array,
  network_bytes_to_number = network_bytes_to_number,

  print_bytes = print_bytes,

  create_header   = create_header,
  create_request  = create_request,
  create_response = create_response,

  create_request_simple = create_request_simple,

  recv_message  = recv_message,
  recv_request  = recv_request,
  recv_response = recv_response,

  opcode = opcode,
  status = status
}

------------------------------------------------------

function TEST_network_bytes()
  a, b, c, d = network_bytes(0x0faabbcc, 4)
  assert(a == 0x0f)
  assert(b == 0xaa)
  assert(c == 0xbb)
  assert(d == 0xcc)

  a, b, c, d = network_bytes(0x8faabbcc, 4) -- Test high bit.
  assert(a == 0x8f)
  assert(b == 0xaa)
  assert(c == 0xbb)
  assert(d == 0xcc)

  a = network_bytes_array(0, 4)
  assert(#a == 4)
  s = string.char(unpack(a))
  assert(string.len(s) == 4)

  x = 0
  assert(network_bytes_to_number(network_bytes_array(x, 4), 1, 4) == x)

  x = 0x01
  assert(network_bytes_to_number(network_bytes_array(x, 4), 1, 4) == x)

  x = 0x111
  assert(network_bytes_to_number(network_bytes_array(x, 4), 1, 4) == x)

  x = 0x0faabbcc
  assert(network_bytes_to_number(network_bytes_array(x, 4), 1, 4) == x)

  x = 0x8faabbcc
  assert(network_bytes_to_number(network_bytes_array(x, 4), 1, 4) == x)

  x = 0x8faabbcc
  assert(network_bytes_to_number(network_bytes_array(x, 2), 1, 2) == 0xbbcc)
end
