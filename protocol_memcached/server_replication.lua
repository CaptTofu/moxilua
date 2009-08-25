local mpb  = memcached_protocol_binary
local msa  = memcached_server.ascii
local pack = mpb.pack

local SUCCESS = mpb.response_stats.SUCCESS

local function response_filter_all(head, body)
  return false
end

local function simple_replicate(success)
  return function(pools, skt, cmd, arr)
    local key = arr[1]
    if key then
      local msg = { key = key }
      local err
      local flag   = arr[2]
      local expire = arr[3]
      local size   = arr[4]
      local data   = nil

      if size then
        size = tonumber(size)
        if size >= 0 then
          data, err = sock_recv(skt, size + 2)
          if not data then
            return data, err
          end

          msg.flag   = flag
          msg.expire = expire
          msg.data   = string.sub(data, 1, -3)
        end
      end

      local n = 0

      for i = 1, #pools do
        local pool = pools[i]

        local downstream = pool.choose(key)
        if downstream and
           downstream.addr then
          if msa.proxy_a2x[downstream.kind](downstream, skt,
                                            cmd, msg,
                                            response_filter_all) then
            n = n + 1
          end
        end
      end

      local oks = 0
      for i = 1, n do
        if apo.recv() then
          oks = oks + 1
        end
      end

      if oks > 0 then
        return sock_send(skt, success)
      end
    end

    return sock_send(skt, "ERROR\r\n")
  end
end

memcached_server_replication = {
  get =
    function(pools, skt, cmd, arr)
      local seen = {}

      for i = 1, #pools do
        local pool = pools[i]

        local groups = group_by(arr, pool.choose)

        local n = 0
        for downstream, keys in pairs(groups) do
          if msa.proxy_a2x[downstream.kind](downstream, skt,
                                            "get", { keys = keys }) then
            n = n + 1
          end
        end

        local oks = 0
        for i = 1, n do
          if apo.recv() then
            oks = oks + 1
          end
        end
      end

      return sock_send(skt, "END\r\n")
    end,

  set =
    simple_replicate("STORED\r\n"),
  add =
    simple_replicate("STORED\r\n"),
  replace =
    simple_replicate("STORED\r\n"),
  append =
    simple_replicate("STORED\r\n"),
  prepend =
    simple_replicate("STORED\r\n"),
  delete =
    simple_replicate("DELETED\r\n"),

  flush_all =
    function(pools, skt, cmd, arr)
      local n = 0
      for i = 1, #pools do
        local pool = pools[i]

        pool.each(function(downstream)
                    if msa.proxy_a2x[downstream.kind](downstream, false,
                                                      "flush_all", {}) then
                      n = n + 1
                    end
                  end)
      end

      local oks = 0
      for i = 1, n do
        if apo.recv() then
          oks = oks + 1
        end
      end

      return sock_send(skt, "OK\r\n")
    end,

  quit =
    function(pools, skt, cmd, arr)
      return false
    end
}

------------------------------------------------------

local msr = memcached_server_replication

local c = mpb.command
local a = {
  c.GET,
  c.SET,
  c.ADD,
  c.REPLACE,
  c.DELETE,
  c.INCREMENT,
  c.DECREMENT,
  c.GETQ,
  c.GETK,
  c.GETKQ,
  c.APPEND,
  c.PREPEND,
  c.STAT,
  c.SETQ,
  c.ADDQ,
  c.REPLACEQ,
  c.DELETEQ,
  c.INCREMENTQ,
  c.DECREMENTQ,
  c.FLUSHQ,
  c.APPENDQ,
  c.PREPENDQ
}

for i = 1, #a do
  msr[a[i]] = forward_simple
end

------------------------------------------------------

-- msr[c.FLUSH] = forward_broadcast_filter(c.FLUSH)

-- msr[c.NOOP] = forward_broadcast_filter(c.NOOP)

------------------------------------------------------

msr[c.QUIT] =
  function(pools, skt, req, args)
    return false
  end

msr[c.QUITQ] = msr[c.QUIT]

------------------------------------------------------

msr[c.VERSION] =
  function(pools, skt, req, args)
  end

msr[c.STAT] =
  function(pools, skt, req, args)
  end

msr[c.SASL_LIST_MECHS] =
  function(pools, skt, req, args)
  end

msr[c.SASL_AUTH] =
  function(pools, skt, req, args)
  end

msr[c.SASL_STEP] =
  function(pools, skt, req, args)
  end

msr[c.BUCKET] =
  function(pools, skt, req, args)
  end

