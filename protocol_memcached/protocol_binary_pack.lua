-- Helper functions to create/process memcached binary protocol packets.
--
local pru = protocol_util
local mpb = memcached_protocol_binary

local network_bytes                  = pru.network_bytes
local network_bytes_string_to_number = pru.network_bytes_string_to_number

------------------------------------------------------

local function create_header(kind, opcode, args)
  args = args or {}

  local keylen = 0
  if args.key then
    keylen = string.len(args.key)
  end

  local extlen = 0
  if args.ext then
    extlen = string.len(args.ext)
  end

  local datalen = 0
  if args.data then
    datalen = string.len(args.data)
  end

  bodylen = keylen + extlen + datalen

  local statusOrReserved =
    args.statusOrReserved or
    args.status or args.reserved or 0

  local a = {}
  local x = mpb[kind .. '_header_field_index']

  a[x.magic] = mpb.magic[kind]

  if type(opcode) == 'number' then
    a[x.opcode] = opcode
  else
    a[x.opcode] = mpb.command[opcode]
  end

  a[x.keylen], a[x.keylen + 1] = network_bytes(keylen, 2)

  a[x.extlen]   = extlen or 0
  a[x.datatype] = datatype or 0

  if kind == 'request' then
    a[x.reserved], a[x.reserved + 1] = network_bytes(statusOrReserved, 2)
  else
    a[x.status], a[x.status + 1] = network_bytes(statusOrReserved, 2)
  end

  a[x.bodylen], a[x.bodylen + 1], a[x.bodylen + 2], a[x.bodylen + 3] =
    network_bytes(bodylen, 4)

  local opaque = args.opaque
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

  local cas = args.cas
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

local function create_request(opcode, args)
  args = args or {}
  local h = create_header('request', opcode, args)
  return h .. (args.ext or "") .. (args.key or "") .. (args.data or "")
end

local function create_response(opcode, args)
  args = args or {}
  local h = create_header('response', opcode, args)
  return h .. (args.ext or "") .. (args.key or "") .. (args.data or "")
end

------------------------------------------------------

local function recv_message(conn, kind)
  local hdr, err = sock_recv(conn, mpb[kind .. "_header_num_bytes"])
  if not hdr then
    return hdr, err
  end

  local fh = mpb[kind .. "_header_field"]
  local fx = mpb[kind .. "_header_field_index"]

  if string.byte(hdr, fx.magic) ~= mpb.magic[kind] then
    return false, "unexpected magic " .. string.byte(hdr, fx.magic)
  end

  local keylen =
    network_bytes_string_to_number(hdr,
                                   fx.keylen,
                                   fh.keylen.num_bytes)
  local extlen =
    network_bytes_string_to_number(hdr,
                                   fx.extlen,
                                   fh.extlen.num_bytes)
  local bodylen =
    network_bytes_string_to_number(hdr,
                                   fx.bodylen,
                                   fh.bodylen.num_bytes)

  local datalen = bodylen - (keylen + extlen)
  if datalen < 0 then
    return false, "unexpected datalen " .. datalen
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

  return hdr, err, { key = key, ext = ext, data = data }
end

------------------------------------------------------

local function recv_request(conn)
  return recv_message(conn, 'request')
end

local function recv_response(conn)
  return recv_message(conn, 'response')
end

------------------------------------------------------

local function opcode(hdr, kind)
  local fx = mpb[kind .. '_header_field_index']
  return string.byte(hdr, fx.opcode)
end

local function opaque(hdr, kind)
  local fo = mpb[kind .. '_header_field'].opaque
  return string.sub(hdr, fo.index, fo.index + fo.num_bytes - 1)
end

local function field_to_number(hdr, kind, field)
  local fo = mpb[kind .. '_header_field'][field]
  return network_bytes_string_to_number(hdr, fo.index, fo.num_bytes)
end

local function keylen(hdr, kind)
  return field_to_number(hdr, kind, 'keylen')
end

local function extlen(hdr, kind)
  return field_to_number(hdr, kind, 'extlen')
end

local function bodylen(hdr, kind)
  return field_to_number(hdr, kind, 'bodylen')
end

local function status(hdr)
  return field_to_number(hdr, 'response', 'status')
end

------------------------------------------------------

-- Sends a single request and receives a single response.
--
local function send_recv(conn, req, recv_callback, success_value)
  success_value = success_value or true

  local ok, err = sock_send(conn, req)
  if not ok then
    return ok, err
  end

  local head, err, rest = recv_response(conn)
  if not head then
    return head, err
  end

  if recv_callback then
    recv_callback(head, rest)
  end

  if opcode(head, 'response') == opcode(req, 'request') then
    if status(head) == mpb.response_status.SUCCESS then
      return success_value, nil, rest
    end

    return false, data
  end

  return false, "unexpected opcode " .. opcode(head, 'response')
end

------------------------------------------------------

mpb.pack = {
  create_header   = create_header,
  create_request  = create_request,
  create_response = create_response,

  recv_message  = recv_message,
  recv_request  = recv_request,
  recv_response = recv_response,

  send_recv = send_recv,

  opcode  = opcode,
  status  = status,
  opaque  = opaque,
  keylen  = keylen,
  extlen  = extlen,
  bodylen = bodylen
}

------------------------------------------------------

function TEST_pack()
  fx = mpb.request_header_field
  assert(fx)

  x = create_request(111)
  assert(x)
  assert(string.len(x) == 24)
  assert(opcode(x, 'request') == 111)
  assert(status(x) == 0)
  o = opaque(x, 'request')
  assert(string.char(0, 0, 0, 0) == o)
  assert(keylen(x, 'request') == 0)
  assert(extlen(x, 'request') == 0)
  assert(bodylen(x, 'request') == 0)

  x = create_request(123, {
        key = "hello", ext = "goodbye", data = "you" })
  assert(x)
  assert(string.len(x) == 24 + 15)
  assert(opcode(x, 'request') == 123)
  assert(status(x) == 0)
  o = opaque(x, 'request')
  assert(string.char(0, 0, 0, 0) == o)
  o = string.sub(x, fx.keylen.index, fx.keylen.index + fx.keylen.num_bytes - 1)
  assert(keylen(x, 'request') == 5)
  assert(extlen(x, 'request') == 7)
  assert(bodylen(x, 'request') == 15)
end
