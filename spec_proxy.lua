function spawn_downstream(location, done_func)
  local host, port, conn, err = connect(location)

  local loop =
    function(self_addr)
      while conn do
        local sess_addr, skt, cmd, keys = apo.recv()

        for i = 1, #keys do
          asock.send(self_addr, skt,
                     "OK " .. cmd .. " key " .. keys[i] .. "\r\n")
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

