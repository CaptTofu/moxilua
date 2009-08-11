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
          local data = asock.recv(sess_addr, skt,
                                  tonumber(size) + 2)
          if data then
            local downstream_addr = pool.choose(key)
            if downstream_addr then
              apo.send(downstream_addr, sess_addr, skt, cmd, {key},
                       string.sub(data, 1, -3))
              apo.recv()
              return true
            end
          end
        end
      end

      asock.send(sess_addr, skt, "ERROR\r\n")
      return true
    end,

  delete =
    function(pool, sess_addr, skt, cmdline, cmd, itr)
      local key = itr()
      if key then
        local downstream_addr = pool.choose(key)
        if downstream_addr then
          apo.send(downstream_addr, sess_addr, skt, cmd, {key})
          apo.recv()
          return true
        end
      end

      asock.send(sess_addr, skt, "ERROR\r\n")
      return true
    end,

  flush_all =
    function(pool, sess_addr, skt, cmdline, cmd, itr)
      local n = 0
      pool.each(
        function(downstream_addr)
          apo.send(downstream_addr, sess_addr, skt, cmd, {key})
          n = n + 1
        end)

      for i = 1, n do
        apo.recv()
      end

      asock.send(sess_addr, skt, "OK\r\n")
      return true
    end,

  quit =
    function(pool, sess_addr, skt, cmdline, cmd, itr)
      return false
    end
}

