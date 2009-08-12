memcached_client_ascii = {
  get =
    function(conn, value_callback, keys)
      local head
      local body
      local line = "get " .. table.concat(keys, ' ') .. "\r\n"

      local ok = sock_send(conn, line)
      if not ok then
        return false
      end

      repeat
        line = sock_recv(conn)
        if line then
          if line == "END" then
            return true
          end

          if string.find(line, "^VALUE ") then
            body = sock_recv(conn)
            if body then
              if value_callback then
                value_callback(line, body)
              end
            else
              return false
            end
          else
            if value_callback then
              value_callback(line, nil)
            end
          end
        else
          return false
        end
      until false
    end,

  set =
    function(conn, value_callback, args, value)
      return sock_send_recv(conn,
                            "set " .. args[1] ..
                            " 0 0 " .. string.len(value) .. "\r\n" ..
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

