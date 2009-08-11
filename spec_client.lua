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
        head = sock_recv(conn)
        if head then
          if head ~= "END" then
            if string.find(head, "^VALUE ") then
              body = sock_recv(conn)
              if body then
                value_callback(head, body)
              else
                return false
              end
            else
              value_callback(head, nil)
            end
          end
        else
          return false
        end
      until head == "END"

      return true
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
    end
}

