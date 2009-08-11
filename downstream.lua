-- Here, dconn means downstream connection,
-- and, uconn means upstream connection.
--
local function spawn_downstream(location, done_func)
  local host, port, dconn, err = connect(location)

  return apo.spawn(
    function(self_addr)
      while dconn do
        local sess_addr, uconn, cmd, keys = apo.recv()

        local ok = true

        local function value_callback(head, body)
          ok = ok and
               (head and
                asock.send(self_addr, uconn, head .. "\r\n")) and
               ((not body) or
                asock.send(self_addr, uconn, body .. "\r\n"))
        end

        local spec = spec_client[cmd]
        if spec then
          if not spec(self_addr, dconn, cmd, keys, value_callback) then
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

function create_downstream_pool(locations)
  local downstream_addrs = {}

  local function done_func(downstream_addr)
    for i, d in ipairs(downstream_addrs) do
      if downstream_addr == d then
        downstream_addrs[i] = nil
      end
    end
  end

  return {
    choose = function(key)
               local i = 1
               local x = downstream_addrs[i]
               if not x then
                 x = spawn_downstream(locations[i], done_func)
                 downstream_addrs[i] = x
               end
               return x
             end
  }
end

