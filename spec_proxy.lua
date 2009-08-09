function spawn_downstream(location)
  local host, port, conn_inner, conn = connect(location)

  local loop =
    function(self_addr)
      while true do
        local sess_addr, skt, cmd, keys = apo.recv()
print("downstream", sess_addr, skt, cmd, keys)
        for i = 1, #keys do
          apo.send(sess_addr, "send", "OK " .. cmd .. " key " .. keys[i] .. "\r\n")
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
           local groups = group_by(itr, function(key)
                                          return pool.choose(key)
                                        end)
           local i = 0
           for downstream, keys in pairs(groups) do
             apo.send(downstream, sess_addr, skt, "get", keys)
             i = i + 1
           end

           local j = 0
           while j < i do
             repeat
               cmd, msg = apo.recv()
               if cmd == "send" then
                 skt:send(msg)
print("sess sending", msg)
               end
             until not cmd
print("sess received one")
             j = j + 1
           end

           skt:send("END\r\n")

print("done", i, j)
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

