memcached_client_ascii = {
  get =
    function(conn, recv_callback, keys)
      local line = "get " .. table.concat(keys, ' ') .. "\r\n"

      local ok, err = sock_send(conn, line)
      if not ok then
        return ok, err
      end

      repeat
        local line, err = sock_recv(conn)
        if not line then
          return line, err
        end

        if line == "END" then
          return line
        end

        local body = nil

        if string.find(line, "^VALUE ") then
          body, err = sock_recv(conn)
          if not body then
            return body, err
          end
        end

        if recv_callback then
          recv_callback(line, body)
        end
      until false
    end,

  set =
    function(conn, recv_callback, args, value)
      return sock_send_recv(conn,
                            "set " ..
                            (args[1])      .. " " ..
                            (args[2] or 0) .. " " ..
                            (args[3] or 0) .. " " ..
                            string.len(value) .. "\r\n" ..
                            value .. "\r\n",
                            recv_callback)
    end,

  delete =
    function(conn, recv_callback, args)
      return sock_send_recv(conn,
                            "delete " .. args[1] .. "\r\n",
                            recv_callback)
    end,

  flush_all =
    function(conn, recv_callback, args)
      return sock_send_recv(conn,
                            "flush_all\r\n",
                            recv_callback)
    end
}

