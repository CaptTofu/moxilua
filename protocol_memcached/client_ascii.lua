local pru  = protocol_util
local mpb  = memcached_protocol_binary
local pack = memcached_protocol_binary.pack

local network_bytes = pru.network_bytes

----------------------------------------------------

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

----------------------------------------------------

local cmd = mpb.command
local mca = memcached_client_ascii
local mcb = memcached_client_binary

-- For binary upstream talking to downstream ascii server.
-- The recv_callback functions will receive ascii-oriented parameters.
--
mca[cmd.GET] =
  function(conn, recv_callback, args)
  end

mca[cmd.SET] = mca.set

mca[cmd.ADD] =
  function(conn, recv_callback, args)
  end

mca[cmd.REPLACE] =
  function(conn, recv_callback, args)
  end

mca[cmd.DELETE] = mca.delete

mca[cmd.INCREMENT] =
  function(conn, recv_callback, args)
  end

mca[cmd.DECREMENT] =
  function(conn, recv_callback, args)
  end

mca[cmd.QUIT] =
  function(conn, recv_callback, args)
  end

mca[cmd.FLUSH] = mca.flush_all

mca[cmd.GETQ] =
  function(conn, recv_callback, args)
  end

mca[cmd.NOOP] =
  function(conn, recv_callback, args)
    if recv_callback then
      recv_callback("END", nil) -- Assuming NOOP used to uncork GETKQ's.
    end
    return true
  end

mca[cmd.VERSION] =
  function(conn, recv_callback, args)
  end

mca[cmd.GETK] =
  function(conn, recv_callback, args)
  end

mca[cmd.GETKQ] =
  function(conn, recv_callback, args)
    return mca.get(conn, recv_callback, { keys = { args.key } })
  end

mca[cmd.APPEND] =
  function(conn, recv_callback, args)
  end

mca[cmd.PREPEND] =
  function(conn, recv_callback, args)
  end

mca[cmd.STAT] =
  function(conn, recv_callback, args)
  end

mca[cmd.SETQ] =
  function(conn, recv_callback, args)
  end

mca[cmd.ADDQ] =
  function(conn, recv_callback, args)
  end

mca[cmd.REPLACEQ] =
  function(conn, recv_callback, args)
  end

mca[cmd.DELETEQ] =
  function(conn, recv_callback, args)
  end

mca[cmd.INCREMENTQ] =
  function(conn, recv_callback, args)
  end

mca[cmd.DECREMENTQ] =
  function(conn, recv_callback, args)
  end

mca[cmd.QUITQ] =
  function(conn, recv_callback, args)
  end

mca[cmd.FLUSHQ] =
  function(conn, recv_callback, args)
  end

mca[cmd.APPENDQ] =
  function(conn, recv_callback, args)
  end

mca[cmd.PREPENDQ] =
  function(conn, recv_callback, args)
  end

mca[cmd.SASL_LIST_MECHS] =
  function(conn, recv_callback, args)
  end

mca[cmd.SASL_AUTH] =
  function(conn, recv_callback, args)
  end

mca[cmd.SASL_STEP] =
  function(conn, recv_callback, args)
  end

mca[cmd.BUCKET] =
  function(conn, recv_callback, args)
  end
