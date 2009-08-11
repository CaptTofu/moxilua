local function send_recv(self_addr, conn, msg, value_callback)
  local ok = asock.send(self_addr, conn, msg, value_callback)
  if not ok then
    return nil
  end

  local rv = asock.recv(self_addr, conn)
  if rv then
    value_callback(rv)
  end

  return rv
end

--------------------------------------------------------

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
    function(self_addr, conn, cmd, value_callback, keys, value)
      return send_recv(self_addr, conn,
                       "set " .. keys[1] ..
                       " 0 0 " .. string.len(value) .. "\r\n" ..
                       value .. "\r\n",
                       value_callback)
    end,

  delete =
    function(self_addr, conn, cmd, value_callback, keys)
      return send_recv(self_addr, conn, value_callback,
                       "delete " .. keys[1] .. "\r\n",
                       value_callback)
    end
}

