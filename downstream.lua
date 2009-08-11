-- Here, dconn means downstream connection,
-- and, uconn means upstream connection.
--
local function spawn_downstream(location, done_func, client)
  local host, port, dconn, err = connect(location)

  return apo.spawn(
    function(self_addr)
      while dconn do
        local sess_addr, uconn, cmd, args, value = apo.recv()

        local ok = true

        local function value_callback(head, body)
          ok = ok and
               (head and
                asock.send(self_addr, uconn, head .. "\r\n")) and
               ((not body) or
                asock.send(self_addr, uconn, body .. "\r\n"))
        end

        local handler = client[cmd]
        if handler then
          if not handler(dconn, value_callback, args, value) then
            dconn:close()
            dconn = nil
          end
        end

        apo.send(sess_addr, ok and dconn)
      end

      done_func(self_addr)
    end
  )
end

------------------------------------------

function create_pool(locations)
  local downstream_addrs = {}

  local function done_func(downstream_addr)
    for i, d in ipairs(downstream_addrs) do
      if downstream_addr == d then
        downstream_addrs[i] = nil
      end
    end
  end

  local function find_downstream(i)
    local x = downstream_addrs[i]
    if not x then
      x = spawn_downstream(locations[i], done_func, client_ascii)
      downstream_addrs[i] = x
    end
    return x
  end

  return {
    choose =
      function(key)
        return find_downstream(1)
      end,

    each =
      function(each_func)
        for i = 1, #locations do
          each_func(find_downstream(i))
        end
      end
  }
end

