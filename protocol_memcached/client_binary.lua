local mpb  = memcached_protocol_binary
local pack = memcached_protocol_binary.pack

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
            recv_callback(head, err, key, ext, data)
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

      local flg_bytes = string.char(pack.network_bytes(flg, 4))
      local exp_bytes = string.char(pack.network_bytes(exp, 4))
      local ext = flg_bytes .. exp_bytes

      local req = pack.create_request_simple('SET', key, ext, value)

      local ok, err = sock_send(conn, req)
      if not ok then
        return ok, err
      end

      local head, err, key, ext, data = pack.recv_response(conn)
      if not head then
        return head, err
      end

      if recv_callback then
        recv_callback(head, err, key, ext, data)
      end

      if pack.opcode(head, 'response') == pack.opcode(req, 'request') then
        if pack.status(head) == mpb.response_status.SUCCESS then
          return "STORED"
        end

        return false, data
      end

      return nil, "unexpected opcode"
    end,

  delete =
    function(conn, recv_callback, args)
      local req = pack.create_request('DELETE', args[1])

      local ok, err = sock_send(conn, req)
      if not ok then
        return ok, err
      end

      local head, err, key, ext, data = pack.recv_response(conn)
      if not head then
        return head, err
      end

      if recv_callback then
        recv_callback(head, err, key, ext, data)
      end

      if pack.opcode(head, 'response') == pack.opcode(req, 'request') and
         pack.status(head) == mpb.response_status.SUCCESS then
        return "DELETED"
      end

      return false
    end,

  flush_all =
    function(conn, recv_callback, args)
      local req = pack.create_request('FLUSH')

      local ok, err = sock_send(conn, req)
      if not ok then
        return ok, err
      end

      local head, err, key, ext, data = pack.recv_response(conn)
      if not head then
        return head, err
      end

      if recv_callback then
        recv_callback(head, err, key, ext, data)
      end

      if pack.opcode(head, 'response') == pack.opcode(req, 'request') and
         pack.status(head) == mpb.response_status.SUCCESS then
        return "OK"
      end

      return false
    end
}

