local function spawn_downstream(location, done_func)
  -- Here, dconn means downstream connection,
  -- and, uconn means upstream connection.
  --
  local host, port, dconn, err = connect(location)

  local loop =
    function(self_addr)
      while dconn do
        local sess_addr, uconn, cmd, keys = apo.recv()

        local head
        local body
        local line = "get " .. array_join(keys) .. "\r\n"

        local ok = asock.send(self_addr, dconn, line)

        if ok then
          repeat
            head = asock.recv(self_addr, dconn)
            if head then
              if head ~= "END" then
                ok = asock.send(self_addr, uconn, head .. "\r\n")
                if ok then
                  if string.find(head, "^VALUE ") then
                    body = asock.recv(self_addr, dconn)
                    if body then
                      ok = asock.send(self_addr, uconn, body .. "\r\n")
                      if not ok then
                        dconn, uconn = close(dconn, uconn)
                      end
                    else
                      dconn = close(dconn)
                    end
                  end
                else
                  dconn, uconn = close(dconn, uconn)
                end
              end
            else
              dconn = close(dconn)
            end
          until dconn == nil or uconn == nil or head == "END"
        else
          dconn = close(dconn)
        end

        apo.send(sess_addr, nil)
      end

      done_func(self_addr)
    end

  return apo.spawn(loop)
end

function create_pool(locations)
  local downstream_addrs = {}

  local function cleanup(downstream_addr)
    for i, d in ipairs(downstream_addrs) do
      if downstream_addr == d then
        downstream_addrs[i] = nil
      end
    end
  end

  for i, location in ipairs(locations) do
    downstream_addrs[i] = spawn_downstream(location, cleanup)
  end

  return {
    choose = function(key)
               return downstream_addrs[1]
             end
  }
end

spec_proxy = {
  get = {
    go = function(pool, sess_addr, skt, cmdline, cmd, itr)
           local groups = group_by(itr, function(key)
                                          return pool.choose(key)
                                        end)
           local i = 0
           for downstream_addr, keys in pairs(groups) do
             apo.send(downstream_addr, sess_addr, skt, cmd, keys)
             i = i + 1
           end

           local j = 0
           while j < i do
             apo.recv()
             j = j + 1
           end

           asock.send(sess_addr, skt, "END\r\n")
           return true
         end
  },
  set = {
    go = function(pool, sess_addr, skt, cmdline, cmd, itr)
           local key  = itr()
           local flgs = itr()
           local expt = itr()
           local size = itr()
           if key and flgs and expt and size then
             size = tonumber(size)
             if size >= 0 then
               local data = skt:receive(tonumber(size) + 2)
               if data then
                 pool[key] = data
                 skt:send("OK\r\n")
                 return true
               end
             end
           end
           skt:send("ERROR\r\n")
           return true
         end
  },
  delete = {
    go = function(pool, sess_addr, skt, cmdline, cmd, itr)
           local key = itr()
           if key then
             if pool[key] then
               pool[key] = nil
               skt:send("DELETED\r\n")
             else
               skt:send("NOT_FOUND\r\n")
             end
           else
             skt:send("ERROR\r\n")
           end
           return true
         end
  },
  quit = {
    go = function(pool, sess_addr, skt, cmdline, cmd, itr)
           return false
         end
  }
}

