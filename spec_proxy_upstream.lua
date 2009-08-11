spec_proxy = {
  get =
    function(pool, sess_addr, skt, cmdline, cmd, itr)
      local groups = group_by(itr, pool.choose)

      local n = 0
      for downstream_addr, keys in pairs(groups) do
        apo.send(downstream_addr, sess_addr, skt, cmd, keys)
        n = n + 1
      end

      for i = 1, n do
        apo.recv()
      end

      asock.send(sess_addr, skt, "END\r\n")
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
    end,

  quit =
    function(pool, sess_addr, skt, cmdline, cmd, itr)
      return false
    end
}

