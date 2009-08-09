function spawn_downstream(location)
  local host, port, conn = connect(location)

print("downstream", "connected", location)

  local loop =
    function(self_addr)
      while true do
print("downstream", "recv", sess_addr)
        local sess_addr, skt, cmd, keys = apo.recv()
print("downstream", "recv'ed", sess_addr, cmd, keys)
        for i = 1, #keys do
          apo_socket.send(self_addr, skt,
                          "OK " .. cmd .. " key " .. keys[i] .. "\r\n")
print("downstream", "sent ok ", keys[i])
        end
        apo.send(sess_addr, nil)
print("downstream", "sent done")
      end
    end

  return apo.spawn(loop)
end

function create_pool(locations)
  local downstream_addrs = {}

  for i, location in ipairs(locations) do
    table.insert(downstream_addrs, spawn_downstream(location))
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
print("proxy.get", cmdline);
           local groups = group_by(itr, function(key)
                                          return pool.choose(key)
                                        end)
           local i = 0
           for downstream, keys in pairs(groups) do
print("proxy.get send downstream", downstream);
             apo.send(downstream, sess_addr, skt, "get", keys)
             i = i + 1
           end

print("proxy.get send done", downstream);

           local j = 0
           while j < i do
             apo.recv()
             j = j + 1
           end

print("proxy.get gather done", downstream);

           skt:send("END\r\n")
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

