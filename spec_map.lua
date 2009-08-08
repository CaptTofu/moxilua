spec_map = {
  get = {
    go = function(map_data, sess_addr, skt, cmdline, cmd, itr)
           for key in itr do
             data = map_data[key]
             if data then
               skt:send("VALUE " .. key .. "\r\n" .. data)
             end
           end
           skt:send("END\r\n")
           return true
         end
  },
  set = {
    go = function(map_data, sess_addr, skt, cmdline, cmd, itr)
           local key  = itr()
           local flgs = itr()
           local expt = itr()
           local size = itr()
           if key and flgs and expt and size then
             size = tonumber(size)
             if size >= 0 then
               local data = skt:receive(tonumber(size) + 2)
               if data then
                 map_data[key] = data
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
    go = function(map_data, sess_addr, skt, cmdline, cmd, itr)
           local key = itr()
           if key then
             if map_data[key] then
               map_data[key] = nil
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
    go = function(map_data, sess_addr, skt, cmdline, cmd, itr)
           return false
         end
  }
}

