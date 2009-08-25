local mpb  = memcached_protocol_binary
local msa  = memcached_server.ascii
local pack = mpb.pack

local SUCCESS = mpb.response_stats.SUCCESS

local function response_filter_all(head, body)
  return false
end

-- Creates a function that replicates a key-based update
-- request across all pools.  Sends the success_msg back
-- upstream if there are at least min_replicas downstream
-- successes.  If the input min_replicas is <= 0 or nil then all
-- downstreams must succeed before success_msg is sent.
--
-- Note that #pools might be > #min_replicas.
--
local function update_replicate(success_msg, min_replicas)
  min_replicas = min_replicas or 0

  return function(pools, skt, cmd, arr)
    local key = arr[1]
    if key then
      local msg = { key = key }
      local err
      local flag   = arr[2]
      local expire = arr[3]
      local size   = arr[4]
      local data   = nil

      -- Read more value data if a size was given.
      --
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

      -- Broadcast the update request to all pools.
      --
      local n = 0 -- Tracks # of requests made.

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

      -- Wait for replies, but opportunistically send an
      -- early success_msg as soon as we can.
      --
      if min_replicas <= 0 then
        min_replicas = n
      end

      local sent = nil
      local oks  = 0

      for i = 1, n do
        if apo.recv() then
          oks = oks + 1
        end

        if (not sent) and (oks >= min_replicas) then
          sent, err = sock_send(skt, success_msg)
        end
      end

      if sent then
        return sent, err
      end

      if oks >= min_replicas then
        return sock_send(skt, success_msg)
      end
    end

    return sock_send(skt, "ERROR\r\n")
  end
end

memcached_server_replication = {
  get =
    function(pools, skt, cmd, arr)
      local keys = arr -- The keys might have duplicates.
      local need = {}  -- Key'ed by string, value is integer count.
      for i = 1, #keys do
        need[keys[i]] = (need[keys[i]] or 0) + 1
      end

      -- A response filter function that tracks the number
      -- of responses needed per key, decrementing the counts
      -- the in the need table.
      --
      local function filter_need(head, body)
        local vfound, vlast, key = string.find(head, "^VALUE (%S+)")
        if vfound and key then
          local count = need[key]
          if count then
            count = count - 1
            if count <= 0 then
              count = nil
            end
            need[key] = count
            return true
          end
        end
        return false
      end

      for i = 1, #pools do
        local pool = pools[i]

        local groups = group_by(keys, pool.choose)

        -- Broadcast multi-get requests to the downstream servers
        -- in a single pool.
        --
        local n = 0
        for downstream, downstream_keys in pairs(groups) do
          if msa.proxy_a2x[downstream.kind](downstream, skt,
                                            "get", { keys = downstream_keys },
                                            filter_need) then
            n = n + 1
          end
        end

        local oks = 0
        for i = 1, n do
          if apo.recv() then
            oks = oks + 1
          end
        end

        -- Regenerate a new keys array based on keys
        -- that still need values.
        --
        keys = {}
        for key, count in pairs(need) do
          for j = 1, count do
            keys[#keys + 1] = key
          end
        end

        -- If there aren't any keys left, we can return without
        -- having to loop through any remaining, secondary pools.
        --
        if #keys <= 0 then
          return sock_send(skt, "END\r\n")
        end
      end

      return sock_send(skt, "END\r\n")
    end,

  set =
    update_replicate("STORED\r\n"),
  add =
    update_replicate("STORED\r\n"),
  replace =
    update_replicate("STORED\r\n"),
  append =
    update_replicate("STORED\r\n"),
  prepend =
    update_replicate("STORED\r\n"),
  delete =
    update_replicate("DELETED\r\n"),

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

