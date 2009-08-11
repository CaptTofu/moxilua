spec_proxy = {
  get =
    function(pool, skt, itr)
      local groups = group_by(itr, pool.choose)

      local n = 0
      for downstream_addr, keys in pairs(groups) do
        apo.send(downstream_addr, apo.self_address(),
                 skt, "get", keys)
        n = n + 1
      end

      for i = 1, n do
        apo.recv()
      end

      return sock_send(skt, "END\r\n") ~= nil
    end,

  set =
    function(pool, skt, itr)
      local key  = itr()
      local flgs = itr()
      local expt = itr()
      local size = itr()

      if key and flgs and expt and size then
        size = tonumber(size)
        if size >= 0 then
          local data = sock_recv(skt, tonumber(size) + 2)
          if data then
            local downstream_addr = pool.choose(key)
            if downstream_addr then
              apo.send(downstream_addr, apo.self_address(),
                       skt, "set", {key},
                       string.sub(data, 1, -3))
              apo.recv()
              return true
            end
          end
        end
      end

      return sock_send(skt, "ERROR\r\n") ~= nil
    end,

  delete =
    function(pool, skt, itr)
      local key = itr()
      if key then
        local downstream_addr = pool.choose(key)
        if downstream_addr then
          apo.send(downstream_addr, apo.self_address(),
                   skt, "delete", {key})
          apo.recv()
          return true
        end
      end

      return sock_send(skt, "ERROR\r\n") ~= nil
    end,

  flush_all =
    function(pool, skt, itr)
      local n = 0
      pool.each(
        function(downstream_addr)
          apo.send(downstream_addr, apo.self_address(),
                   skt, "flush_all", {key})
          n = n + 1
        end)

      for i = 1, n do
        apo.recv()
      end

      return sock_send(skt, "OK\r\n") ~= nil
    end,

  quit =
    function(pool, skt, itr)
      return false
    end
}

