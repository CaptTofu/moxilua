spec_client = {
  get =
    function(self_addr, conn, cmd, keys, value_callback)
      local head
      local body
      local line = "get " .. array_join(keys) .. "\r\n"

      local ok = asock.send(self_addr, conn, line)
      if not ok then
        return false
      end

      repeat
        head = asock.recv(self_addr, conn)
        if head and head ~= "END" then
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
        else
          return false
        end
      until head == "END"

      return true
    end,

  set =
    function(pool, sess_addr, skt, cmdline, cmd, itr)
      local key  = itr()
      local flgs = itr()
      local expt = itr()
      local size = itr()
      if key and flgs and expt and size then
        size = tonumber(size)
        if size >= 0 then
          local data = skt:receive(tonumber(size) + 2)
          if data then
            pool[key] = data
            skt:send("OK\r\n")
            return true
          end
        end
      end
      skt:send("ERROR\r\n")
      return true
    end,

  delete =
    function(pool, sess_addr, skt, cmdline, cmd, itr)
      local key = itr()
      if key then
        if pool[key] then
          pool[key] = nil
          skt:send("DELETED\r\n")
        else
          skt:send("NOT_FOUND\r\n")
        end
      else
        skt:send("ERROR\r\n")
      end
      return true
    end
}

