spec_client = {
  get =
    function(self_addr, conn, cmd, value_callback, keys)
      local head
      local body
      local line = "get " .. array_join(keys) .. "\r\n"

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
              value_callback(line, body)
            else
              return false
            end
          else
            value_callback(line, nil)
          end
        else
          return false
        end
      until false
    end,

  set =
    function(self_addr, conn, cmd, value_callback, args, value)
      return sock_send_recv(conn,
                            "set " .. args[1] ..
                            " 0 0 " .. string.len(value) .. "\r\n" ..
                            value .. "\r\n",
                            value_callback)
    end,

  delete =
    function(self_addr, conn, cmd, value_callback, args)
      return sock_send_recv(conn,
                            "delete " .. args[1] .. "\r\n",
                            value_callback)
    end,

  flush_all =
    function(self_addr, conn, cmd, value_callback, args)
      return sock_send_recv(conn,
                            "flush_all\r\n",
                            value_callback)
    end
}
