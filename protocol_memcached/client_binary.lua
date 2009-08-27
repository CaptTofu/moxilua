local pru  = protocol_util
local mpb  = memcached_protocol_binary
local pack = memcached_protocol_binary.pack

local network_bytes = pru.network_bytes

memcached_client_binary = {
  get =
    function(conn, recv_callback, args)
      local reqs = {}
      local keys = args.keys

      for i = 1, #keys do
        reqs[#reqs + 1] = pack.create_request('GETKQ', { key = keys[i] })
      end

      reqs[#reqs + 1] = pack.create_request('NOOP')

      local reqs_buf = table.concat(reqs)

      local ok, err = sock_send(conn, reqs_buf)
      if not ok then
        return ok, err
      end

      repeat
        local head, err, rest = pack.recv_response(conn)
        if not head then
          return head, err
        end

        local opcode = pack.opcode(head, 'response')
        if opcode == mpb.command.NOOP then
          return "END"
        end

        if opcode == mpb.command.GETKQ then
          if recv_callback then
            recv_callback(head, rest)
          end
        else
          return false, "unexpected opcode " .. opcode
        end
      until false
    end,

  set =
    function(conn, recv_callback, args)
      local key = args.key
      local flag = args.flag or 0
      local expire = args.expire or 0

      local flag_bytes = string.char(network_bytes(flag, 4))
      local expire_bytes = string.char(network_bytes(expire, 4))
      local ext = flag_bytes .. expire_bytes

      local req =
        pack.create_request('SET', { key = key, ext = ext, data = args.data })

      return pack.send_recv(conn, req,
                            recv_callback, "STORED")
    end,

  delete =
    function(conn, recv_callback, args)
      return pack.send_recv(conn,
                            pack.create_request('DELETE', { key = args.key }),
                            recv_callback, "DELETED")
    end,

  incr = 
    function (conn, recv_callback, args)
      local key = args.key
      local amount = args.amount or "1"
      local req =
        pack.create_request("INCREMENT", { key = key, amount = amount})

      return pack.send_recv(conn, req, recv_callback)
    end,

  decr = 
    function (conn, recv_callback, args)
      local key = args.key
      local amount = args.amount or "1"
      local req =
        pack.create_request("DECREMENT", { key = key, amount = amount})

      return pack.send_recv(conn, req, recv_callback)
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

--------------------------------------------------------

-- Catch all functions for pure-binary clients aware of binary opcodes.
--
local function binary_vocal_cmd(conn, recv_callback, args)
  local req = args.req
  local key = args.key
  local ext = args.ext
  local msg = pack.pack_message(req, key, ext, args.data)

  local ok, err = sock_send(conn, msg)
  if not ok then
    return ok, err
  end

  repeat
    local head, err, rest = pack.recv_response(conn)
    if not head then
      return head, err
    end

    if recv_callback then
      recv_callback(head, rest)
    end

    local o = pack.opcode(head, 'response')
    if o == pack.opcode(req, 'request') then
      if pack.status(head) == mpb.response_status.SUCCESS then
        return true, nil, rest
      end

      return false, data
    end

    if o ~= mpb.command.GETKQ and
       o ~= mpb.command.GETQ then
      return false, "unexpected opcode " .. o
    end
  until false
end

local function binary_quiet_cmd(conn, recv_callback, args)
  local req = args.req
  local key = args.key
  local ext = args.ext
  local msg = pack.pack_message(req, key, ext, args.data)

  return sock_send(conn, msg)
end

--------------------------------------------------------

for name, opcode in pairs(memcached_protocol_binary.command_vocal) do
  memcached_client_binary[opcode] = binary_vocal_cmd
end

for name, opcode in pairs(memcached_protocol_binary.command_quiet) do
  memcached_client_binary[opcode] = binary_quiet_cmd
end

