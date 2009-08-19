-- Create a closure that does an ascii update.
--
local function update_create(cmd)
  return function(conn, recv_callback, args, value)
           return sock_send_recv(conn,
                                 cmd .. " " ..
                                 (args.key) .. " " ..
                                 (args.flag or 0) .. " " ..
                                 (args.expire or 0) .. " " ..
                                 string.len(args.data) .. "\r\n" ..
                                 args.data .. "\r\n",
                                 recv_callback)
         end
end

----------------------------------------------------

memcached_client_ascii = {
  get =
    function(conn, recv_callback, args)
      local line = "get " .. table.concat(args.keys, ' ') .. "\r\n"

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

        local data = nil

        if string.find(line, "^VALUE ") then
          data, err = sock_recv(conn)
          if not data then
            return data, err
          end
        end

        if recv_callback then
          recv_callback(line, { data = data })
        end
      until false
    end,

  set     = update_create("set"),
  add     = update_create("add"),
  replace = update_create("replace"),
  append  = update_create("append"),
  prepend = update_create("prepend"),

  delete =
    function(conn, recv_callback, args)
      return sock_send_recv(conn,
                            "delete " .. args.key .. "\r\n",
                            recv_callback)
    end,

  flush_all =
    function(conn, recv_callback, args)
      return sock_send_recv(conn,
                            "flush_all\r\n",
                            recv_callback)
    end
}

