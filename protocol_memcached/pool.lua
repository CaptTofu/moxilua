-- Here, dconn means downstream connection,
-- and, uconn means upstream connection.
--
local function spawn_downstream(location, done_func)
  local host, port, dconn, err = connect(location)

  return apo.spawn(
    function(self_addr)
      while dconn do
        local what, notify_addr, response, handler, args = apo.recv()
        if what == "fwd" then
          args = args or {}

          if not handler(dconn, response, args) then
            dconn:close()
            dconn = nil
          end
        elseif what == "close" then
          dconn:close()
          dconn = nil
        end

        if notify_addr then
          apo.send(notify_addr, dconn)
        end
      end

      done_func(self_addr)
    end
  )
end

------------------------------------------

function memcached_pool(locations)
  local downstreams = {}

  local function done_func(downstream_addr)
    for k, downstream in pairs(downstreams) do
      if downstream.addr == downstream_addr then
        downstreams[k] = nil
      end
    end
  end

  local function find_downstream(k)
    local downstream = downstreams[k]
    if not downstream then
      local x = locations[k]
      if x then
        local downstream_addr =
          spawn_downstream(x.location, done_func)

        downstream = {
          location = x.location,     -- eg, "localhost:11211"
          kind     = x.kind,         -- eg, binary or ascii.
          addr     = downstream_addr -- An apo address.
        }

        downstreams[k] = downstream
      end
    end
    return downstream
  end

  local pool = {
    close =
      function()
        for i = 1, #downstream_addrs do
          if downstream_addrs[i] then
            apo.send(downstream_addrs[i], "close")
          end
        end
      end,

    choose =
      function(key)
        return find_downstream(1)
      end,

    each =
      function(each_func)
        for k, location in pairs(locations) do
          each_func(find_downstream(k))
        end
      end
  }

  return pool
end

