-- Helper functions to create/process memcached binary protocol packets.
--
local pru = protocol_util
local mpb = memcached_protocol_binary

local network_bytes                  = pru.network_bytes
local network_bytes_string_to_number = pru.network_bytes_string_to_number

------------------------------------------------------

local function create_header(kind, cmd,
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
  local x = mpb[kind .. '_header_field_index']

  a[x.magic] = mpb.magic[kind]

  if type(cmd) == 'number' then
    a[x.opcode] = cmd
  else
    a[x.opcode] = mpb.command[cmd]
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

  return hdr, err, key, ext, data
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

local function status(hdr)
  local fh = mpb.response_header_field
  local fx = mpb.response_header_field_index

  return network_bytes_string_to_number(hdr,
                                        fx.status,
                                        fh.status.num_bytes)
end

------------------------------------------------------

-- Sends a single request and receives a single response.
--
local function send_recv(conn, req, recv_callback, success_value)
  local ok, err = sock_send(conn, req)
  if not ok then
    return ok, err
  end

  local head, err, key, ext, data = recv_response(conn)
  if not head then
    return head, err
  end

  if recv_callback then
    recv_callback(head, err, key, ext, data)
  end

  if opcode(head, 'response') == opcode(req, 'request') then
    if status(head) == mpb.response_status.SUCCESS then
      return success_value
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

  create_request_simple = create_request_simple,

  recv_message  = recv_message,
  recv_request  = recv_request,
  recv_response = recv_response,

  send_recv = send_recv,

  opcode = opcode,
  status = status
}

