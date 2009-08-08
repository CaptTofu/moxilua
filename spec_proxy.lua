function proxy_switch(self_addr)
  while true do
    skt, req, itr = apo.recv()
    skt:send("OK\r\n")
  end
end

spec_proxy = {
  get = {
    go = function(switch_addr, sess_addr, skt, cmdline, cmd, itr)
           apo.send(downstreams, { from = skt, cmdline, cmd, itr })
           while true do
             local msg = apo.recv()
             if msg ~= 'quit' then
               return true
             end
           end
           return true
         end
  },
  set = {
    go = function(switch_addr, sess_addr, skt, cmdline, cmd, itr)
           local key  = itr()
           local flgs = itr()
           local expt = itr()
           local size = itr()
           if key and flgs and expt and size then
             size = tonumber(size)
             if size >= 0 then
               local data = skt:receive(tonumber(size) + 2)
               if data then
                 switch_addr[key] = data
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
    go = function(switch_addr, sess_addr, skt, cmdline, cmd, itr)
           local key = itr()
           if key then
             if switch_addr[key] then
               switch_addr[key] = nil
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
    go = function(switch_addr, sess_addr, skt, cmdline, cmd, itr)
           return false
         end
  }
}

