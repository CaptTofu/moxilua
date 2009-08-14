memcached_client_ascii = {
  get =
    function(conn, value_callback, keys)
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

        value_callback(line, body)
      until false
    end,

  set =
    function(conn, value_callback, args, value)
      return sock_send_recv(conn,
                            "set " ..
                            (args[1])      .. " " ..
                            (args[2] or 0) .. " " ..
                            (args[3] or 0) .. " " ..
                            string.len(value) .. "\r\n" ..
                            value .. "\r\n",
                            value_callback)
    end,

  delete =
    function(conn, value_callback, args)
      return sock_send_recv(conn,
                            "delete " .. args[1] .. "\r\n",
                            value_callback)
    end,

  flush_all =
    function(conn, value_callback, args)
      return sock_send_recv(conn,
                            "flush_all\r\n",
                            value_callback)
    end
}

