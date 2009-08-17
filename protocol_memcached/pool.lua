-- Here, dconn means downstream connection,
-- and, uconn means upstream connection.
--
local function spawn_downstream(location, client_specs, recv_after, done_func)
  local host, port, dconn, err = connect(location)

  return apo.spawn(
    function(self_addr)
      while dconn do
        local sess_addr, uconn, cmd, args, value, recv_callback = apo.recv()

        local ok = true

        local function recv_after_wrapper(head, body)
          if uconn then
            ok = ok and recv_after(uconn, head, body)
          end

          if recv_callback then
            recv_callback(head, body)
          end
        end

        local handler = client_specs[cmd]
        if handler then
          if not handler(dconn, recv_after_wrapper, args, value) then
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

function memcached_pool(locations, client_specs, recv_after)
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
      x = spawn_downstream(locations[i], client_specs, recv_after, done_func)
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

------------------------------------------

function memcached_pool_ascii(locations)
  local function recv_after_ascii(uconn, head, body)
    return (head and
            sock_send(uconn, head .. "\r\n")) and
           ((not body) or
            sock_send(uconn, body .. "\r\n"))
  end

  return memcached_pool(locations, memcached_client_ascii, recv_after_ascii)
end

function memcached_pool_binary(locations)
  local function recv_after_binary(uconn, head, body)
    local key  = body[1]
    local ext  = body[2]
    local data = body[3]

    local msg = head .. (ext or "") .. (key or "") .. (data or "")

    return sock_send(uconn, msg)
  end

  return memcached_pool(locations, memcached_client_binary, recv_after_binary)
end

