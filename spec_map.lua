spec_map = {
  get =
    function(map_data, sess_addr, skt, cmdline, cmd, itr)
      for key in itr do
        data = map_data[key]
        if data then
          asock.send(sess_addr, skt,
                     "VALUE " .. key .. "\r\n" .. data)
        end
      end
      asock.send(sess_addr, skt, "END\r\n")
      return true
    end,

  set =
    function(map_data, sess_addr, skt, cmdline, cmd, itr)
      local key  = itr()
      local flgs = itr()
      local expt = itr()
      local size = itr()
      if key and flgs and expt and size then
        size = tonumber(size)
        if size >= 0 then
          local data = asock.recv(sess_addr, skt,
                                  tonumber(size) + 2)
          if data then
            map_data[key] = data
            asock.send(sess_addr, skt, "OK\r\n")
            return true
          end
        end
      end
      asock.send(sess_addr, skt, "ERROR\r\n")
      return true
    end,

  delete =
    function(map_data, sess_addr, skt, cmdline, cmd, itr)
      local key = itr()
      if key then
        if map_data[key] then
          map_data[key] = nil
          asock.send(sess_addr, skt, "DELETED\r\n")
        else
          asock.send(sess_addr, skt, "NOT_FOUND\r\n")
        end
      else
        asock.send(sess_addr, skt, "ERROR\r\n")
      end
      return true
    end,

  quit =
    function(map_data, sess_addr, skt, cmdline, cmd, itr)
      return false
    end
}

