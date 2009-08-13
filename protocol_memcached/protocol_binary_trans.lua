-- Helper functions to create/process binary protocol
-- transmission packets.
--
local mpb = memcached_protocol_binary

local function network_bytes(x, num_bytes)
  local a = {}
  for i = num_bytes, 1, -1 do
    a[i] = math.mod(x, 0x0100) -- lua has no builtin bit mask/shift operators.
    x = math.floor(x / 0x0100)
  end
  return unpack(a) -- returns array of bytes numbers, highest order first.
end

------------------------------------------------------

local function create_header(type, cmd,
                             key, ext, datatype, statusOrReserved, body,
                             opaque, cas)
  local keylen = 0
  if key then
    keylen = string.len(key)
  end

  local extlen = 0
  if ext then
    extlen = string.len(ext)
  end

  local bodylen = 0
  if body then
    bodylen = string.len(body)
  end

  local a = {}
  local x = mpb[type + '_header_field_index']

  a[x.magic]  = mpb.magic[type]
  a[x.opcode] = mpb.command[cmd]

  a[x.keylen], a[x.keylen + 1] = network_bytes(keylen, 2)

  a[x.extlen]   = extlen or 0
  a[x.datatype] = datatype or 0

  statusOrReserved = statusOrReserved or 0

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
                              key, ext, datatype, statusOrReserved, body,
                              opaque, cas)
  local h = create_header('request', cmd,
                          key, ext, datatype, statusOrReserved, body,
                          opaque, cas)
  return h .. (key or "") .. (ext or "") .. (body or "")
end

local function create_response(cmd,
                               key, ext, datatype, statusOrReserved, body,
                               opaque, cas)
  local h = create_header('response', cmd,
                          key, ext, datatype, statusOrReserved, body,
                          opaque, cas)
  return h .. (key or "") .. (ext or "") .. (body or "")
end

------------------------------------------------------

mpb.trans = {
  network_bytes = network_bytes,
  create_header = create_header,
  create_request = create_request,
  create_response = create_response
}

------------------------------------------------------

function TEST_network_bytes()
  assert(network_bytes(0x0fabc, 4))
  a, b, c, d = network_bytes(0x0faabbcc, 4)
  assert(a == 0x0f)
  assert(b == 0xaa)
  assert(c == 0xbb)
  assert(d == 0xcc)
end
