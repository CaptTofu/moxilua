local pru  = protocol_util
local mpb  = memcached_protocol_binary
local pack = memcached_protocol_binary.pack

local network_bytes = pru.network_bytes

memcached_client_binary = {
  create_request = pack.create_request,
  create_response = pack.create_response,

  get =
    function(conn, recv_callback, keys)
      local reqs = {}

      for i = 1, #keys do
        reqs[#reqs + 1] = pack.create_request('GETKQ', keys[i])
      end

      reqs[#reqs + 1] = pack.create_request('NOOP')

      local reqs_buf = table.concat(reqs)

      local ok, err = sock_send(conn, reqs_buf)
      if not ok then
        return ok, err
      end

      repeat
        local head, err, key, ext, data = pack.recv_response(conn)
        if not head then
          return head, err
        end

        local opcode = pack.opcode(head, 'response')
        if opcode == mpb.command.NOOP then
          return "END"
        end

        if opcode == mpb.command.GETKQ then
          if recv_callback then
            recv_callback(head, {key, ext, data})
          end
        else
          return false, "unexpected opcode " .. opcode
        end
      until false
    end,

  set =
    function(conn, recv_callback, args, value)
      local key = args[1]
      local flg = args[2]
      local exp = args[3]

      local flg_bytes = string.char(network_bytes(flg, 4))
      local exp_bytes = string.char(network_bytes(exp, 4))
      local ext = flg_bytes .. exp_bytes

      local req = pack.create_request_simple('SET', key, ext, value)

      return pack.send_recv(conn, req,
                            recv_callback, "STORED")
    end,

  delete =
    function(conn, recv_callback, args)
      return pack.send_recv(conn,
                            pack.create_request('DELETE', args[1]),
                            recv_callback, "DELETED")
    end,

  flush_all =
    function(conn, recv_callback, args)
      return pack.send_recv(conn,
                            pack.create_request('FLUSH'),
                            recv_callback, "OK")
    end
}

--------------------------------------------------------

-- Catch all functions for pure-binary clients aware of binary opcodes.
--
local function binary_vocal_cmd(conn, recv_callback, args, data)
  local req = args[1]
  local key = args[2]
  local ext = args[3]
  local msg = req .. (ext or "") .. (key or "") .. (data or "")

local r = pack.opcode(req, 'request')
  local ok, err = sock_send(conn, msg)
  if not ok then
    return ok, err
  end

  repeat
    local head, err, key, ext, data = pack.recv_response(conn)
    if not head then
      return head, err
    end

    if recv_callback then
      recv_callback(head, {key, ext, data})
    end

    local o = pack.opcode(head, 'response')
    if o == pack.opcode(req, 'request') then
      if pack.status(head) == mpb.response_status.SUCCESS then
        return true, nil, key, ext, data
      end

      return false, data
    end

    if o ~= mpb.command.GETKQ and
       o ~= mpb.command.GETQ then
      return false, "unexpected opcode " .. o
    end
  until false
end

local function binary_quiet_cmd(conn, recv_callback, args, data)
  local req = args[1]
  local key = args[2]
  local ext = args[3]
  local msg = req .. (ext or "") .. (key or "") .. (data or "")

  return sock_send(conn, msg)
end

--------------------------------------------------------

for name, opcode in pairs(memcached_protocol_binary.command_vocal) do
  memcached_client_binary[opcode] = binary_vocal_cmd
end

for name, opcode in pairs(memcached_protocol_binary.command_quiet) do
  memcached_client_binary[opcode] = binary_quiet_cmd
end

