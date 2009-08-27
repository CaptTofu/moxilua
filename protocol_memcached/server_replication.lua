local mpb  = memcached_protocol_binary
local msa  = memcached_server.ascii
local pack = mpb.pack

local SUCCESS = mpb.response_stats.SUCCESS

-- Creates a function that replicates a generic msg
-- request across all pools.  Sends the success_msg back
-- upstream if there are at least min_replicas number of
-- downstream successes.  If the input min_replicas is <= 0
-- or nil then all downstreams must succeed before the
-- success_msg is sent.  Otherwise an ERROR is sent.
--
-- Note that #pools might be > #min_replicas, which is
-- useful to have lots of replicas, but not have to wait
-- for acknowledgements from all of them.
--
local function create_replicator(success_msg, min_replicas)
  min_replicas = min_replicas or 0

  return function(pools, skt, cmd, msg)
    local first_response_head = nil
    local first_response_body = nil

    local function first_response_filter(head, body)
      if (not success_msg) and
         (not first_response_head) then
        first_response_head = head
        first_response_body = body
      end
      return false
    end

    local function first_response()
      local m = first_response_head .. '\r\n'
      if first_response_body then
        m = m .. first_response_body .. '\r\n'
      end
      return m
    end

    -- Broadcast the update request to all pools.
    --
    local n = 0 -- Tracks # of requests made.

    for i = 1, #pools do
      local pool = pools[i]

      if msg.key then
        local downstream = pool.choose(msg.key)
        if downstream and
           downstream.addr then
          if msa.proxy_a2x[downstream.kind](downstream, skt,
                                            cmd, msg,
                                            first_response_filter) then
            n = n + 1
          end
        end
      else
        pool.each(function(downstream)
                    if msa.proxy_a2x[downstream.kind](downstream, skt,
                                                      cmd, msg,
                                                      first_response_filter) then
                      n = n + 1
                    end
                  end)
      end
    end

    -- Wait for replies, but opportunistically send an
    -- early success_msg as soon as we can.
    --
    if min_replicas <= 0 then
      min_replicas = n
    end

    local sent = nil
    local err  = nil
    local oks  = 0

    for i = 1, n do
      if apo.recv() then
        oks = oks + 1
      end

      if (not sent) and (oks >= min_replicas) then
        sent, err = sock_send(skt, success_msg or first_response())
      end
    end

    if sent then
      return sent, err
    end

    if oks >= min_replicas then
      return sock_send(skt, success_msg or first_response())
    end

    return sock_send(skt, "ERROR\r\n")
  end
end

------------------------------------------------------

-- Creates a function that replicates a key-based update
-- request across all pools, with at least min_replicas
-- required before sending a success_msg response.
--
local function create_update_replicator(success_msg, min_replicas)
  local replicator = create_replicator(success_msg, min_replicas)

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

      return replicator(pools, skt, cmd, msg)
    end

    return sock_send(skt, "ERROR\r\n")
  end
end

------------------------------------------------------

local function create_arith_replicator(min_replicas)
  local replicator = create_replicator(nil, min_replicas)

  return function(pools, skt, cmd, arr)
    local key    = arr[1]
    local amount = arr[2]
    if key and amount then
      return replicator(pools, skt, cmd, { key = key, amount = amount })
    end

    return sock_send(skt, "ERROR\r\n")
  end
end

------------------------------------------------------

local function create_replication_spec(policy)
  return {
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
      create_update_replicator("STORED\r\n",
                               policy.min_replicas_set or 0),
    add =
      create_update_replicator("STORED\r\n",
                               policy.min_replicas_add or 0),
    replace =
      create_update_replicator("STORED\r\n",
                               policy.min_replicas_replace or 0),
    append =
      create_update_replicator("STORED\r\n",
                               policy.min_replicas_append or 0),
    prepend =
      create_update_replicator("STORED\r\n",
                               policy.min_replicas_prepend or 0),
    delete =
      create_update_replicator("DELETED\r\n",
                               policy.min_replicas_delete or 0),

    incr =
      create_arith_replicator(policy.min_replicas_incr or 0),
    decr =
      create_arith_replicator(policy.min_replicas_decr or 0),

    flush_all =
      create_replicator("OK\r\n",
                        policy.min_replicas_flush_all or 0),

    quit =
      function(pools, skt, cmd, arr)
        return false
      end
  }
end

------------------------------------------------------

-- Default policy where all replicas receive all updates,
-- and conservatively where min_replicas == #replicas.
--
memcached_server_replication =
  create_replication_spec({})

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
  msr[a[i]] = nil -- TODO
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

