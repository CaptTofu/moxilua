spec_client = {
  get =
    function(self_addr, conn, cmd, value_callback, keys)
      local head
      local body
      local line = "get " .. array_join(keys) .. "\r\n"

      local ok = asock.send(self_addr, conn, line)
      if not ok then
        return false
      end

      repeat
        head = asock.recv(self_addr, conn)
        if head then
          if head ~= "END" then
            if string.find(head, "^VALUE ") then
              body = asock.recv(self_addr, conn)
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
      return asock.send_recv(self_addr, conn,
                             "set " .. args[1] ..
                             " 0 0 " .. string.len(value) .. "\r\n" ..
                             value .. "\r\n",
                             value_callback)
    end,

  delete =
    function(self_addr, conn, cmd, value_callback, args)
      return asock.send_recv(self_addr, conn,
                             "delete " .. args[1] .. "\r\n",
                             value_callback)
    end
}

