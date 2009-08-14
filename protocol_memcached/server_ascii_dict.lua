memcached_server_ascii_dict = {
  get =
    function(dict, skt, itr)
      for key in itr do
        data = dict.tbl[key]
        if data then
          local ok, err = sock_send(skt, "VALUE " ..
                                         key .. "\r\n" ..
                                         data .. "\r\n")
          if not ok then
            return ok, err
          end
        end
      end
      return sock_send(skt, "END\r\n")
    end,

  set =
    function(dict, skt, itr)
      local key  = itr()
      local flgs = itr()
      local expt = itr()
      local size = itr()

      if key and flgs and expt and size then
        size = tonumber(size)
        if size >= 0 then
          local data, err = sock_recv(skt, tonumber(size) + 2)
          if not data then
            return data, err
          end

          dict.tbl[key] = string.sub(data, 1, -3)

          return sock_send(skt, "STORED\r\n")
        end
      end

      return sock_send(skt, "ERROR\r\n")
    end,

  delete =
    function(dict, skt, itr)
      local key = itr()
      if key then
        if dict.tbl[key] then
          dict.tbl[key] = nil
          return sock_send(skt, "DELETED\r\n")
        else
          return sock_send(skt, "NOT_FOUND\r\n")
        end
      end
      return sock_send(skt, "ERROR\r\n")
    end,

  flush_all =
    function(dict, skt, itr)
      dict.tbl = {}
      return sock_send(skt, "OK\r\n")
    end,

  quit =
    function(dict, skt, itr)
      return false
    end
}

