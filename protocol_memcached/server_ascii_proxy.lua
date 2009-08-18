memcached_server_ascii_proxy = {
  get =
    function(pool, skt, arr)
      local groups = group_by(arr, pool.choose)

      local n = 0
      for downstream_addr, keys in pairs(groups) do
        apo.send(downstream_addr, apo.self_address(),
                 skt, "get", { keys = keys })
        n = n + 1
      end

      for i = 1, n do
        apo.recv()
      end

      return sock_send(skt, "END\r\n")
    end,

  set =
    function(pool, skt, arr)
      local key    = arr[1]
      local flag   = arr[2]
      local expire = arr[3]
      local size   = arr[4]

      if key and flag and expire and size then
        size = tonumber(size)
        if size >= 0 then
          local data, err = sock_recv(skt, tonumber(size) + 2)
          if not data then
            return data, err
          end

          local downstream_addr = pool.choose(key)
          if downstream_addr then
            apo.send(downstream_addr, apo.self_address(),
                     skt, "set", {
                       key    = key,
                       flag   = flag,
                       expire = expire,
                       data   = string.sub(data, 1, -3)
                     })
            apo.recv()

            return true
          end
        end
      end

      return sock_send(skt, "ERROR\r\n")
    end,

  delete =
    function(pool, skt, arr)
      local key = arr[1]
      if key then
        local downstream_addr = pool.choose(key)
        if downstream_addr then
          apo.send(downstream_addr, apo.self_address(),
                   skt, "delete", { key = key })
          apo.recv()
          return true
        end
      end

      return sock_send(skt, "ERROR\r\n")
    end,

  flush_all =
    function(pool, skt, arr)
      local n = 0
      pool.each(
        function(downstream_addr)
          apo.send(downstream_addr, apo.self_address(),
                   false, "flush_all", {})
          n = n + 1
        end)

      for i = 1, n do
        apo.recv()
      end

      return sock_send(skt, "OK\r\n")
    end,

  quit =
    function(pool, skt, arr)
      return false
    end
}

