-- Here, dconn means downstream connection,
-- and, uconn means upstream connection.
--
local function spawn_downstream(location, client_specs, recv_after, done_func)
  local host, port, dconn, err = connect(location)

  return apo.spawn(
    function(self_addr)
      while dconn do
        local what, uconn, cmd, args, recv_callback = apo.recv()
        if what == "close" then
          dconn:close()
          dconn = nil
        else
          local ok = true

          local function recv_after_wrapper(head, body)
            if uconn then
              ok = ok and recv_after(uconn, head, body)
            end

            if recv_callback then
              ok = ok and recv_callback(head, body)
            end
          end

          local handler = client_specs[cmd]
          if handler then
            args = args or {}

            if not handler(dconn, recv_after_wrapper, args) then
              dconn:close()
              dconn = nil
            end
          end

          local sess_addr = what

          apo.send(sess_addr, ok and dconn)
        end
      end

      done_func(self_addr)
    end
  )
end

------------------------------------------

memcached_downstream_kind = {
  ascii = {
    client_specs = memcached_client_ascii,
    recv_after = function(uconn, head, body)
      return (head and
              sock_send(uconn, head .. "\r\n")) and
             ((not body) or
              sock_send(uconn, body.data .. "\r\n"))
    end
  },

  binary = {
    client_specs = memcached_client_binary,
    recv_after = function(uconn, head, body)
      local msg = head ..
                  (body.ext or "") ..
                  (body.key or "") ..
                  (body.data or "")

      return sock_send(uconn, msg)
    end
  }
}

------------------------------------------

function memcached_pool(locations)
  local downstream_addrs = {}

  local function done_func(downstream_addr)
    for i, d in ipairs(downstream_addrs) do
      if downstream_addr == d then
        downstream_addrs[i] = nil
      end
    end
  end

  local function find_downstream(i)
    local d = downstream_addrs[i]
    if not d then
      local x = locations[i]
      if x then
        local kind = memcached_downstream_kind[x.kind]
        if kind then
          d = spawn_downstream(x.location,
                               kind.client_specs,
                               kind.recv_after,
                               done_func)
          downstream_addrs[i] = d
        end
      end
    end
    return d
  end

  return {
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
        for i = 1, #locations do
          each_func(find_downstream(i))
        end
      end
  }
end

